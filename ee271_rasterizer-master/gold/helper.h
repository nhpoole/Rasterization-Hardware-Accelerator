
/*
 *   Modified from http://www.zarb.org/~gc/html/libpng.html
 *
 *   A test of a simple function that can take an array and 
 *   write a png from it.
 *
 *
 *
 *
 */

/*
 * Copyright 2002-2008 Guillaume Cottenceau.
 *
 * This software may be freely redistributed under the terms
 * of the X11 license.
 *
 */

#if !defined( J_HELPER )
#define J_HELPER

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <iostream>
#include <fstream>
#include <string>

#include <vector>

#include "rast_types.h"

using namespace std;


void abort_(const char * s, ...);

void load_file(char* file_name, vector<Triangle>& triangles, Screen& screen, Config &config);

void write_ppm_file( 
		    char* file_name , 
		    uchar* img , 
		    int w , 
		    int h 
		     );

#endif
