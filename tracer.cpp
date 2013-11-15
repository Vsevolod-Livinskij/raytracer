/*
 * tracer.cpp
 *
 *  Created on: Nov 8, 2013
 *      Author: vsevolod
 */
#include <stdlib.h>   // card > aek.ppm
#include <stdio.h>
#include <math.h>
#include <algorithm>
//#include "tracer_ispc.h"

extern "C"
void picture_creator (int width, int height, int depth, int out []);
extern "C"
int programNum;

int main () {
	printf("P6 512 512 255 "); // The PPM Header is issued
	int width = 512, height = 512, depth = 3;
	int *out = new int [width * height * depth];
	picture_creator (width, height, depth, out);
	for (int i = width * height * depth - 1; i >= 0 ; i--) {
		printf ("%c", out [i]);
	}
}
