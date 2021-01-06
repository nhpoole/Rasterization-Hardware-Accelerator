#ifndef J_ZBUFF
#define J_ZBUFF

// #include <vector>
// #include <stdlib.h>
#include "rast_types.h"

int idx_f(ZBuff *zbuff, int x, int y, int sx, int sy, int c);
int idx_d(ZBuff *zbuff, int x , int y , int sx , int sy);

ZBuff* zbuff_init(Screen screen, Config config);
void eval_ss(ZBuff *zbuff, uchar *rgb, ushort *fb_pix);
uchar* eval_all_ss(ZBuff *zbuff);
void write_ppm(ZBuff *zbuff, char *file_name);
void process_fragment(ZBuff *zbuff, Sample hit_location, Sample subsample, Fragment f);
// class zbuff
// {
//  public:
//   int w ;  // width
//   int h ;  // height
//   int ss ; // super sampling
//   int ss_w ; // sqrt of super sampling
//   int ss_w_lg2 ; // log 2 of the sqrt of sampling
//   double ss_i ; // subsample interval

//  private:
  

//   uchar* eval_ss();
//   void eval_ss( uchar* rgb , ushort* fb_pix);

//  public:

//   zbuff( Screen screen, Config config );

//   void write_ppm( char* file_name );

//   void process_fragment(Sample hit_location, Sample subsample, Fragment f);
// };

#endif 
