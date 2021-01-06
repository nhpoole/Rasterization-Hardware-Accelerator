#include "helper.h"
#include "zbuff.h"
#include "rast_types.h"

using namespace std;

void abort_(const char * s, ...)
{
    va_list args;
    va_start(args, s);
    vfprintf(stderr, s, args);
    fprintf(stderr, "\n");
    va_end(args);
    abort();
}

/* File Format:
   /
   /   First Line: JB20
   /   Second Line: w,h,ss
   /
   /   One triangle or quad per line
   /   Each Line:
   /    Number of Vertices
   /    For Each Vertex:
   /       x,y,z   floats in screen space
   /       r,g,b,a floats [0,1]
*/

void load_file(char* file_name, vector<Triangle>& triangles, Screen& screen, Config &config)
{
    char buf[256];
    
    int valid, integer;

    ifstream myfile (file_name);  /* Open File for Read */

    if( ! myfile.is_open() )
        abort_("Failed to Open Vector File for Read");

    /* Check First Line */
    myfile.getline( buf, 256 , '\n'); // First Line
    if( !strcmp( buf , "JB21" ) ){

        printf( "File type JB21 found, begin parsing\n");

        /* Grab Config From Second Line */
        myfile>>hex>>screen.width;
        // screen.width = integer / 1024;

        myfile>>hex>>screen.height;
        // screen.height = integer / 1024;

        myfile>>dec>>config.ss;
        switch( config.ss )
        {
        case 1:  config.ss_w = 1 ;  config.ss_w_lg2 = 0 ; break ;
        case 4:  config.ss_w = 2 ;  config.ss_w_lg2 = 1 ; break ;
        case 16: config.ss_w = 4 ;  config.ss_w_lg2 = 2 ; break ;
        case 64: config.ss_w = 8 ;  config.ss_w_lg2 = 3 ; break ;
        }
        config.ss_i = 1024 / config.ss_w;

        // cout<<"Debug: \tw="<<*w<<" \th="<<*h<<" \tss="<<*ss<<endl;

        while( ! myfile.eof() ){
            myfile>>dec>>valid;

            //Get the Vertice Count
            int vertices;
            myfile>>dec>>vertices;

            if(vertices <3 || vertices > 4){
                //not safe, must guarentee input
                printf("End of File, %i\n" , vertices );
                return;
            }

            Triangle triangle;
            for( int vertex = 0 ; vertex < 3 ; vertex++ ){
                //Vertice Screen Space Positions
                myfile >> hex >> triangle.v[vertex].x;
                myfile >> hex >> triangle.v[vertex].y;
                myfile >> hex >> triangle.v[vertex].z;
                // for(int axis = 0; axis < 3; axis++){
                //     myfile >> hex >> triangle.v[vertex].axis[axis];
                // }
                
            }
            
            // test vectors have a 4th vertex, so ignore
            for(int vertex = 3; vertex < 4; vertex++){
                int dummy;
                for(int axis = 0; axis < 3; axis++){
                    myfile >> hex >> dummy;
                }
            }

            // Colors for vertice
            myfile >> hex >> triangle.v[0].R;
            myfile >> hex >> triangle.v[0].G;
            myfile >> hex >> triangle.v[0].B;

            // copy the color of the first vertex to the others
            // FIXME: this should be 3!!
            for( int vertex = 1; vertex < 3 ; vertex++ ){
                triangle.v[vertex].R = triangle.v[0].R;
                triangle.v[vertex].G = triangle.v[0].G;
                triangle.v[vertex].B = triangle.v[0].B;
                // for( int color = 0 ; color < 4 ; color++ ){
                //     triangle.v[vertex].c[color] = triangle.v[0].c[color];
                // }
            }

            if(valid){
                triangles.push_back(triangle);
            }
        }
    } else {
        printf( "%s\n" ,buf );
        abort_("File is Incorrect Format");
    }
    
    myfile.close();

}


void write_ppm_file(
            char* file_name ,
            uchar* imgBuffer ,
            int w ,
            int h
             )
{
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

  return ;
}

