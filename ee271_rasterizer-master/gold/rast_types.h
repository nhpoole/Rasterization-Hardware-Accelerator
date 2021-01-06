#ifndef RAST_TYPES_H
#define RAST_TYPES_H

#include <stdbool.h>

typedef unsigned char uchar ;
typedef unsigned short ushort ;
typedef unsigned int  uint; 

typedef struct {
    // x,y,z coordinates
    int x;
    int y;
    int z;
    
    // rgb color
    ushort R;
    ushort G;
    ushort B;
} ColorVertex3D;

typedef struct { // triangle 
  ColorVertex3D v[3] ;
} Triangle;

typedef struct {
    int x;
    int y;
} Vertex2D;

typedef struct { // bounding box
	Vertex2D lower_left;
	Vertex2D upper_right;
	bool valid;
} BoundingBox;

typedef struct { // screen
	int width; // width of screen (on x axis)
	int height; // height of screen (on y axis)
} Screen;

typedef struct { // config
	int r_shift; // number of fractional bits in fixed point representation
	int ss;      // super sampling (1, 4, 16, 4)
    double ss_i;   // sampling interval (1024/ss_w)
    int ss_w;    // subsample_width
    int ss_w_lg2; // log2(subsample_width)
    /*
     *  ss_w_lg2 is a log2 value related to supersampling:
     *      1xMSAA  : ss_w_lg2 = 0
     *      4xMSAA  : ss_w_lg2 = 1
     *      16xMSAA : ss_w_lg2 = 2
     *      64xMSAA : ss_w_lg2 = 3
     */
} Config;

typedef Vertex2D Sample;

typedef struct {
    uint z;

    // rgb color
    ushort R;
    ushort G;
    ushort B;
} Fragment;

typedef struct {
    int w;
    int h;
    Config config;
    ushort* frame_buffer ;
    uint*   depth_buffer ;
} ZBuff;


#endif
