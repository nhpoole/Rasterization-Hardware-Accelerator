

#include "zbuff.h" 
#include "float.h"
#include "limits.h"
#include "assert.h"
#include "rast_types.h"
#include <stdio.h>
#include <stdlib.h>


int idx_f(ZBuff *zbuff, int x, int y, int sx, int sy, int c){
  int ss_w = zbuff->config.ss_w;
  int w = zbuff->w;
  int h = zbuff->h;
  return ((((( y*w ) + x)*ss_w+sy)*ss_w+sx)*4+c);
}

int idx_d(ZBuff *zbuff, int x , int y , int sx , int sy){
  int ss_w = zbuff->config.ss_w;
  int w = zbuff->w;
  int h = zbuff->h;
  return (((( y*w ) + x)*ss_w+sy)*ss_w+sx);
}

// Build a black zbuffer
ZBuff* zbuff_init(Screen screen, Config config){
  ZBuff *zbuff = (ZBuff*) malloc(sizeof(ZBuff));
  zbuff->w = screen.width / 1024;
  zbuff->h = screen.height / 1024;
  zbuff->config = config;
  
  zbuff->frame_buffer = (ushort*) calloc(zbuff->w*zbuff->h*config.ss*4, sizeof(ushort));
  zbuff->depth_buffer = (uint*) malloc(zbuff->w*zbuff->h*config.ss*sizeof(uint));
  for(int i = 0; i < zbuff->w*zbuff->h*config.ss; i++){
    zbuff->depth_buffer[i] = UINT_MAX;
  }

  return zbuff;
}

// Evaluate the Subsamples at the given pixel
//  return the colors for that fragment
void eval_ss(ZBuff *zbuff, uchar *rgb, ushort *fb_pix){
  uint rgb_l[4];
  rgb_l[0] = 0 ;
  rgb_l[1] = 0 ;
  rgb_l[2] = 0 ;

  for(int i = 0 ; i < zbuff->config.ss_w ; i++){
    for(int j = 0 ; j < zbuff->config.ss_w ; j++){
      for(int k = 0 ; k < 4 ; k++){
        rgb_l[k] += fb_pix[ (i*zbuff->config.ss_w+j)*4 + k ];
      }
    }
  }

  for(int k = 0 ; k < 3 ; k++ ){
    rgb[k] = (uchar) (( rgb_l[k] / zbuff->config.ss ) >> ( 8 )) ;
  }
}

uchar *blank( int w , int h )
{
    int x ;
    int y ;

    uchar* img ;
    uchar* rgba ;

    img = (uchar*) malloc( sizeof(uchar) * w * h * 3 );

    for( y=0 ;  y<h ; y++ ) {
        for( x=0 ; x<w ; x++ ) {
            rgba = &(img[(y*w+x)*3]);
            rgba[0] =  255 ; // Set R
            rgba[1] =  255 ; // Set G
            rgba[2] =  255 ; // Set B
        }
    }

    return img;
}

// Evaluate All Subsamples
uchar* eval_all_ss(ZBuff *zbuff){
  int w = zbuff->w;
  int h = zbuff->h;
  
  int x ;
  int y ;

  uchar* rgb ;
  ushort* fb_pix ;

  uchar* img = blank(w,h);
  
  for(int y=0 ;  y<h ; y++ ) {
    for(int x=0 ; x<w ; x++ ) {
      rgb = &(img[ (y*w + x)*3]);
      fb_pix = &( zbuff->frame_buffer[ idx_f(zbuff, x , y , 0 , 0 , 0 ) ] ) ;
      eval_ss(zbuff, rgb , fb_pix ) ;
    }
  }

  return img ;
}

void write_ppm(ZBuff *zbuff, char *file_name){
  int w = zbuff->w;
  int h = zbuff->h;

  uchar* imgBuffer = eval_all_ss(zbuff);
  

  /*Taken From: http://www.cse.ohio-state.edu/~shareef/cse681/labs/writePPM.html */

  FILE *stream;

  stream = fopen(file_name, "wb" );            // Open the file for write
  fprintf( stream, "P6\n%d %d\n255\n", w, h ); // Write the file header information

  for( int iy = 0; iy < h; iy++){             // Write the contents of the buffer to file
    for( int ix = 0; ix < w; ix++ ){

      // Access pixel (ix, iy) by indexing the appropriate row and then column in the
      // image buffer and taking into account that each pixel has
      // three unsigned char values. This command will write a single pixel value (rgb)
      // to the file in binary format.
      fwrite( imgBuffer + (iy * w + ix) * 3, 1, 3, stream );
    }
  }

  fclose( stream );
}

void process_fragment(ZBuff *zbuff, Sample hit_location, Sample subsample, Fragment f){
  if( f.z <= zbuff->depth_buffer[ idx_d(zbuff, hit_location.x, hit_location.y, subsample.x, subsample.y ) ] ){
    zbuff->depth_buffer[ idx_d(zbuff, hit_location.x, hit_location.y, subsample.x, subsample.y ) ] = f.z ;
    uint id = idx_f(zbuff, hit_location.x, hit_location.y, subsample.x, subsample.y, 0 ) ;
    
    zbuff->frame_buffer[ id ] = f.R ;
    zbuff->frame_buffer[ id + 1 ] = f.G ;
    zbuff->frame_buffer[ id + 2 ] = f.B ;
    zbuff->frame_buffer[ id + 3 ] = 1 ; // alpha is always 1
  }
}
