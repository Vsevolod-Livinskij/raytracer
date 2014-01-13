int G [] = {247570, 280596, 280600, 249748, 18578, 18577, 231184, 16, 16};

RNGState rngstate;

struct vec {
    float x,y,z; 
};

static inline vec vadd (vec a, vec b) {
    vec ret;
    ret.x = a.x + b.x;
    ret.y = a.y + b.y;
    ret.z = a.z + b.z;
    return ret;
}

static inline vec vproduct (float n, vec a) {
    vec ret;
    ret.x = n * a.x;
    ret.y = n * a.y;
    ret.z = n * a.z;
    return ret;
}

static inline float vdot (vec a, vec b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

static inline vec vcross (vec v0, vec v1) {
    vec ret;
    ret.x = v0.y * v1.z - v0.z * v1.y;
    ret.y = v0.z * v1.x - v0.x * v1.z;
    ret.z = v0.x * v1.y - v0.y * v1.x;
    return ret;
}

static inline vec vinit (float a, float b, float c) {
    vec ret;
    ret.x = a;
    ret.y = b;
    ret.z = c;
    return ret;
}

static inline vec vnormalize (vec v) {
    float len2 = vdot (v, v);
    float invlen = sqrt (len2);
    return vproduct (1 / invlen, v);
}

static int T (vec o, vec d, float &t, vec &n){
    t = 1e9;
    int m = 0;
    float p = - o.z / d.z;
    if (.01 < p)
        t = p, n = vinit (0, 0, 1), m = 1;
    
     //The world is encoded in G, with 9 lines and 19 columns
    for (uniform int k = 19; k--;)  //For each columns of objects
    for (uniform int j = 9; j--;)   //For each line on that columns
    
    if (G [j] & 1 << k) { //For this line j, is there a sphere at column i ?
    
        // There is a sphere but does the ray hits it ?
            
        vec box = vinit (-k, 0, -j - 4);
        vec pr = vadd (o, box);
        float b = vdot (pr, d);
        float c = vdot (pr, pr) - 1;
        float q = b * b - c;
        
        //Does the ray hit the sphere ?
        if (q > 0) {
            //It does, compute the distance camera-sphere
            float s = -b - sqrt (q);
    
            if (s < t && s > .01) {
                 // So far this is the minimum distance, save it. And also
                 // compute the bouncing ray vector into 'n'
                 t = s;
                 n = vnormalize (vadd (pr, vproduct(t, d)));
                 m = 2;
            }
        }
     }
    return m;
}

// (S)ample the world and return the pixel color for
// a ray passing by point o (Origin) and d (Direction)
static vec S (vec o, vec d) {
    float t;
    vec n;

    //Search for an intersection ray Vs World.
    int m = T (o,d,t,n);


    if (!m) { // m==0
        //No sphere found and the ray goes upward: Generate a sky color
        vec box = vinit (.7, .6, 1);
        return vproduct (pow (1 - d.z, 4), box);
    }

    //A sphere was maybe hit.

    vec h   = vadd (o, vproduct (t, d));                    // h = intersection coordinate
    vec box = vinit (9 + frandom (&rngstate), 9 + frandom (&rngstate), 16);
    vec l   = vnormalize ((vadd(box, vproduct (-1, h))));  // 'l' = direction to light (with random delta for soft-shadows).
    vec r   = vadd (d, vproduct ((vdot (n, d) * -2), n));               // r = The half-vector

    //Calculated the lambertian factor
    float b = vdot (l, n);

    //Calculate illumination factor (lambertian coefficient > 0 or in shadow)?
    if (b < 0 || T (h, l, t, n))
       b = 0;

    // Calculate the color 'p' with diffuse and specular component
    float p = 0;
    if (b > 0) p = pow (vdot (l, r), 99);

    if (m & 1){   //m == 1
       h = vproduct (.2, h); //No sphere was hit and the ray was going downward: Generate a floor color
       return vproduct ((b*.2+.1), ((int)(ceil(h.x)+ceil(h.y))&1?vinit(3,1,1):
                                                               vinit(3,3,3)));
    }

    //m == 2 A sphere was hit. Cast an ray bouncing from the sphere surface.
    box = vinit (p, p, p);
    return vadd(box, vproduct (.5, S (h, r))); //Attenuate color by 50% since it is bouncing (* .5)
}

export void picture_creator (uniform int width, uniform int height,
                             uniform int depth, uniform int out []) {
       
    vec g = vnormalize( vinit (-6, -16, 0));       // Camera direction
    vec box = vinit (0,0,1);
    vec a = vproduct (.002, vnormalize (vcross (box, g))); // Camera up vector...Seem Z is pointing up :/ WTF !
    vec b = vproduct (0.002, vnormalize ((vcross (g, a))));        // The right vector, obtained via traditional cross-product
    vec c = vadd (vproduct(-256, (vadd (a,b))), g);       // WTF ? See https://news.ycombinator.com/item?id=6425965 for more.
    vec box1 = vinit (17, 16, 8);
    seed_rng(&rngstate, programIndex + (clock () % 4294967296 << (programIndex & 15)));
    int size = width * height;

    for(uniform int y = 0; y < height ; y++){    //For each column
        foreach (x = 0 ... width) { //For each pixel in a line
            //Reuse the vector class to store not XYZ but a RGB pixel color
            vec p = vinit (13, 13, 13);     // Default pixel color is almost pitch black
        
            //Cast 64 rays per pixel (For blur (stochastic sampling) and soft-shadows.
            for (uniform int r = 0; r < 64; r++) {
                
                // The delta to apply to the origin of the view (For Depth of View blur).
                vec t = vadd (vproduct (99, vproduct ((frandom (&rngstate)-.5), a)),
                              vproduct (99, vproduct ((frandom (&rngstate)-.5), b))); // A little bit of delta up/down and left/right
        
                // Set the camera focal point v(17,16,8) and Cast the ray
                // Accumulate the color returned in the p variable
                p = vadd (vproduct (3.5, S (vadd (box1, t), //Ray Origin
                    vnormalize(vadd(vproduct (-1, t), vproduct (16,
                            (vadd (vadd (vproduct ((frandom (&rngstate)+x-0.1), a),
                            vproduct ((frandom (&rngstate)+y-0.05), b)), c))))))) // Ray Direction with random deltas for stochastic sampling
                    , p); // +p for color accumulation
            }
            
            int index = x + y * width;
            out [index] = p.z;
            out [index + size] = p.y;
            out [index + 2 * size] = p.x;
        }
    }
}
