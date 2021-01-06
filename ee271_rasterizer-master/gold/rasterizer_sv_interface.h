#ifndef RASTERIZER_SV_INTERFACE_H
#define RASTERIZER_SV_INTERFACE_H

#include "acc_user.h"
#include "vcs_acc_user.h"
#include "svdpi.h"
#include "stdlib.h"

int check_bounding_box(
    int   v0_x,     //triangle
    int   v0_y,     //triangle
    int   v1_x,     //triangle
    int   v1_y,     //triangle
    int   v2_x,     //triangle
    int   v2_y,     //triangle
    int  valid_triangle, // valid
    int   ll_x,     //BBOX
    int   ll_y,     //BBOX
    int   ur_x,     //BBOX
    int   ur_y,     //BBOX
    int   ss_w_lg2, //Subsample
    int   screen_w, //Screen
    int   screen_h, //Screen
    int  valid_bbox,   //BBOX
    int   r_shift,  //Config
    int   r_val     //Congig 
);

int check_sample_test(
    int   v0_x,      //triangle
    int   v0_y,      //triangle
    int   v1_x,      //triangle
    int   v1_y,      //triangle
    int   v2_x,      //triangle
    int   v2_y,      //triangle
    int   s_x,       //SAMPLE 
    int   s_y,       //SAMPLE
    int   hit        //HIT
);

int check_hit_count(
    int   v0_x,      //triangle
    int   v0_y,      //triangle
    int   v1_x,      //triangle
    int   v1_y,      //triangle
    int   v2_x,      //triangle
    int   v2_y,      //triangle
    int   hits,      //Number of Samples in triangle
    int   ss_w_lg2,  //Subsample
    int   screen_w,  //Screen
    int   screen_h,  //Screen
    int   r_shift,   //Config
    int   r_val      //Config
);

ZBuff *zbuff;
int check_zbuff_init(
    int w,    //Screen Width
    int h,    //Screen Width
    int ss_w  //Subsample Width
);

int check_zbuff_process_fragment(
    int x ,   //Hit Loc. X
    int y ,   //Hit Loc. Y
    int ss_x ,  //`$ss` Hit loc X
    int ss_y ,  //`$ss` Hit Loc Y
    int d , //actually a uint
    int R , //actually a ushort
    int G , //actually a ushort
    int B   //actually a ushort
);

int check_zbuff_write_ppm();

#endif
