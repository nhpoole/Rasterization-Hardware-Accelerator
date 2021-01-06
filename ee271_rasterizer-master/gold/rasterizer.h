#ifndef RASTERIZER_H
#define RASTERIZER_H

#include <stdbool.h>
#include "rast_types.h"
#include "zbuff.h"

int min(int a, int b);
int max(int a, int b);
int floor_ss(int val, int r_shift, int ss_w_lg2);
BoundingBox get_bounding_box(Triangle triangle, Screen screen, Config config);
bool sample_test(Triangle triangle, Sample sample);
int rasterize_triangle( Triangle triangle, ZBuff *z, Screen screen, Config config);
void hash_40to8( uchar* arr40 , ushort* val , int shift );
Sample jitter_sample(const Sample sample, const int ss_w_lg2);

#endif
