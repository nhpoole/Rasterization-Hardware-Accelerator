#include "rasterizer.h"
#include "rasterizer_sv_interface.h"
#include <stddef.h>
#include <stdio.h>

#define PRINT_ERROR(signal, rtl, gold) \
    printf("\n[ERROR] Signal %s mismatch!\n", signal); \
    printf("\tRTL: %d\n", rtl); \
    printf("\tGold: %d\n", gold);

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
){
    Triangle triangle;
    triangle.v[0].x = v0_x;
    triangle.v[0].y = v0_y;
    triangle.v[1].x = v1_x;
    triangle.v[1].y = v1_y;
    triangle.v[2].x = v2_x;
    triangle.v[2].y = v2_y;

    Screen screen;
    screen.width = screen_w;
    screen.height = screen_h;

    Config config;
    config.r_shift = r_shift;
    config.ss_w_lg2 = ss_w_lg2;

    BoundingBox bbox = get_bounding_box(triangle, screen, config);

    int isCorrect = true;
    if(valid_triangle){
        if(valid_bbox != bbox.valid){
            //PRINT_ERROR("bbox_valid", valid_bbox, bbox.valid);
            isCorrect = false;
        }
        else if(valid_bbox == true){
            if(ll_x != bbox.lower_left.x){
                PRINT_ERROR("ll_x", ll_x, bbox.lower_left.x);
                isCorrect = false;
            }
            if(ll_y != bbox.lower_left.y){
                PRINT_ERROR("ll_y", ll_y, bbox.lower_left.y);
                isCorrect = false;
            }
            if(ur_x != bbox.upper_right.x){
                PRINT_ERROR("ur_x", ur_x, bbox.upper_right.x);
                isCorrect = false;
            }
            if(ur_y != bbox.upper_right.y){
                PRINT_ERROR("ur_y", ur_y, bbox.upper_right.y);
                isCorrect = false;
            }
            
        }
    }

    // printf("done\n");
    // return isCorrect;
    // return true;
    return 1;
}

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
){
    Triangle triangle;
    triangle.v[0].x = v0_x;
    triangle.v[0].y = v0_y;
    triangle.v[1].x = v1_x;
    triangle.v[1].y = v1_y;
    triangle.v[2].x = v2_x;
    triangle.v[2].y = v2_y;

    Sample sample;
    sample.x = s_x;
    sample.y = s_y;
    
    int gold_hit = sample_test(triangle, sample);
    
    if(hit != gold_hit){
        PRINT_ERROR("sample_hit", hit, gold_hit);
        return false;
    }
    
    return true;
}

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
){
    Triangle triangle;
    triangle.v[0].x = v0_x;
    triangle.v[0].y = v0_y;
    triangle.v[1].x = v1_x;
    triangle.v[1].y = v1_y;
    triangle.v[2].x = v2_x;
    triangle.v[2].y = v2_y;

    Screen screen;
    screen.width = screen_w;
    screen.height = screen_h;

    Config config;
    config.r_shift = r_shift;
    config.ss_w_lg2 = ss_w_lg2;

    int gold_hits = rasterize_triangle(triangle, NULL, screen, config);

    if(hits != gold_hits){
        PRINT_ERROR("hits", hits, gold_hits);
        return false;
    }
    
    return true;
}

int check_hash(
    int s_x,
    int s_y,
    int ss_w_lg2,
    int jitter_x,
    int jitter_y,
    int s_j_x,
    int s_j_y
)
{
    Sample sample;
    sample.x = s_x;
    sample.y = s_y;
    
    int isCorrect = true;

    Sample jitter = jitter_sample(sample, ss_w_lg2);
    if(jitter_x != jitter.x){
        PRINT_ERROR("jitter_x", jitter_x, jitter.x);
        isCorrect = false;
    }
    if(jitter_y != jitter.y){
        PRINT_ERROR("jitter_y", jitter_y, jitter.y);
        isCorrect = false;
    }

    if(isCorrect){
        Sample jittered_sample;
        jittered_sample.x = sample.x + (jitter.x << 2);
        jittered_sample.y = sample.y + (jitter.y << 2);
        if(s_j_x != jittered_sample.x){
            PRINT_ERROR("s_j_x", s_j_x, jittered_sample.x);
            isCorrect = false;
        }

        if(s_j_y != jittered_sample.y){
            PRINT_ERROR("s_j_y", s_j_y, jittered_sample.y);
            isCorrect = false;
        }
    }

    return isCorrect;
}

int check_zbuff_init(
    int w,    //Screen Width
    int h,    //Screen Width
    int ss_w  //Subsample Width
){
    Screen screen;
    screen.width = w*1024;
    screen.height = h*1024;
    
    Config config;
    config.ss_w = ss_w;
    config.ss = ss_w*ss_w;

    zbuff = zbuff_init(screen, config);

    return 1;
}

int check_zbuff_process_fragment(
    int x ,   //Hit Loc. X
    int y ,   //Hit Loc. Y
    int ss_x ,  //`$ss` Hit loc X
    int ss_y ,  //`$ss` Hit Loc Y
    int d , //actually a uint
    int R , //actually a ushort
    int G , //actually a ushort
    int B   //actually a ushort
){
    Sample sample;
    sample.x = x;
    sample.y = y;

    Sample subsample;
    subsample.x = ss_x;
    subsample.y = ss_y;

    Fragment f;
    f.z = d;
    f.R = R;
    f.G = G;
    f.B = B;

    process_fragment(zbuff, sample, subsample, f);
    return 1;
}

int check_zbuff_write_ppm(){
    write_ppm(zbuff, "verif_out.ppm" );
    return 1;
}
