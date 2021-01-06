

#include "helper.h"
// #include "rasterizer_wrapper.h"
// #include "rasterizer_core.h"
extern "C"{
#include "rasterizer.h"
#include "rast_types.h"
#include "zbuff.h"
}

#include <stdlib.h>
#include <stdio.h>


/*

   Test Rast
     This is a test function with a 
     few cases with known results.

     These tests should act as a rough
     test of whether the bounding box
     and sample test operation have 
     been configured correctly.

     This function also demonstrates
     how some of the primitives are defined.
*/
bool testRast()
{
  Config config;
  config.r_shift = 10 ;   //This is the number of fractional bits
  config.ss_w_lg2 = 2 ; // This is the log_2 ( sqrt( MSAA ) )  

  /* Lets Describe the Screen Space */
  Screen screen;
  screen.width =  1024 << config.r_shift ; // 1024 pixels wide (on x axis)
  screen.height = 1024 << config.r_shift ; // 1024 pixels tall (on y axit)

  Triangle triangle; // This is a triangle
  triangle.v[0].x = 556 << ( config.r_shift - 2 ); //v0.x
  triangle.v[0].y = 679 << ( config.r_shift - 2 ); //v0.y

  triangle.v[1].x = 562 << ( config.r_shift - 2 ); //v1.x
  triangle.v[1].y = 660 << ( config.r_shift - 2 ); //v1.y

  triangle.v[2].x = 557 << ( config.r_shift - 2 ); //v2.x
  triangle.v[2].y = 661 << ( config.r_shift - 2 ); //v2.y

  // Note that there are other parameters in
  // a triangle, but they are more or less
  // irrelevant for this portion of the algorithm


  printf( "Test 1: Bounding Box Test\n" );

  BoundingBox bbox = get_bounding_box(triangle, screen, config);
  if( ! bbox.valid ){
    abort_("Fail Test 1"); 
  }
  if( bbox.lower_left.x != (556 << ( config.r_shift - 2 )) ){
    abort_("Fail Test 1"); 
  }
  if( bbox.lower_left.y != (660 << ( config.r_shift - 2 )) ){
    abort_("Fail Test 1"); 
  }
  if( bbox.upper_right.x != (562 << ( config.r_shift - 2 )) ){
    abort_("Fail Test 1"); 
  }
  if( bbox.upper_right.y != (679 << ( config.r_shift - 2 )) ){
    abort_("Fail Test 1"); 
  }

  printf( "\t\tPass Test 1\n");


  /* 
     If you are having trouble determining if your bounding
     box function is correct, you can add more test cases
     here.
  */

  printf( "Test 2: SampleTest Test\n" );
  Sample sample;
  sample.x = 559 << ( config.r_shift - 2 );
  sample.y = 662 << ( config.r_shift - 2 );
  bool hit = sample_test( triangle, sample);

  if(!hit) { //If a miss
    abort_("Failed Test 2");
  }

  printf( "\t\tPass Test 2\n");


  printf( "Test 3: SampleTest Test\n" );

  sample.x = 560 << ( config.r_shift - 2 );
  sample.y = 678 << ( config.r_shift - 2 );
  hit = sample_test( triangle, sample);

  if(hit) { //If a hit
    abort_("Failed Test 3");
  }

  printf( "\t\tPass Test 3\n");

  /* 
     If you are having trouble determining if your sample test
     function is correct, you can add more test cases
     here.
  */

  return true ;
}




int main(int argc, char **argv)
{

  if( ! testRast() )
  {
    abort_("Test Failed");
  }

  if (argc != 3)
  {
    abort_("Usage: program_name <file_out> <vector>");
  }
  
  //Set Screen and Subsample
  vector<Triangle> triangles;
  Screen screen;
  Config config;

  config.r_shift = 10;

  //Read in triangles from file
  load_file(argv[2], triangles, screen, config);

  //Report Number of triangles
  printf( "Triangles to rasterize: %zu\n" , triangles.size() );
  
  //Initialize a Depth Buffer
  ZBuff *zbuff = zbuff_init(screen, config);

  //Rasterize the Scene   
  for(size_t i = 0; i < triangles.size(); i++) {
    rasterize_triangle(triangles[i], zbuff, screen, config);
  }

  //Write the Zbuffer to a file
  write_ppm(zbuff, argv[1] );
}
