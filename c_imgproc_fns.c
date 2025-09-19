// C implementations of image processing functions

#include <stdlib.h>
#include <assert.h>
#include "imgproc.h"

// Helper functions for pixel manipulation

// Extract red component from pixel (bits 24-31)
uint32_t get_r( uint32_t pixel ) {
  return (pixel >> 24) & 0xFF;
}

// Extract green component from pixel (bits 16-23)
uint32_t get_g( uint32_t pixel ) {
  return (pixel >> 16) & 0xFF;
}

// Extract blue component from pixel (bits 8-15)
uint32_t get_b( uint32_t pixel ) {
  return (pixel >> 8) & 0xFF;
}

// Extract alpha component from pixel (bits 0-7)
uint32_t get_a( uint32_t pixel ) {
  return pixel & 0xFF;
}

// Create a pixel
uint32_t make_pixel( uint32_t r, uint32_t g, uint32_t b, uint32_t a ) {
  return (r << 24) | (g << 16) | (b << 8) | a;
}

// Compute array index from row and column
int32_t compute_index( struct Image *img, int32_t row, int32_t col ) {
  return row * img->width + col;
}

// Check if a pixel at (row, col) is inside the ellipse
int is_in_ellipse( struct Image *img, int32_t row, int32_t col ) {
  int32_t w = img->width;
  int32_t h = img->height;
  int32_t a = w / 2;  // floor(w/2)
  int32_t b = h / 2;  // floor(h/2)
  
  // Distance from center pixel
  int32_t x = col - a;
  int32_t y = row - b;
  
  // Check ellipse inequality
  int32_t term1 = (10000 * x * x) / (a * a);
  int32_t term2 = (10000 * y * y) / (b * b);
  
  return (term1 + term2) <= 10000;
}

//! Transform the color component values in each input pixel
//! by applying the bitwise complement operation. I.e., each bit
//! in the color component information should be inverted
//! (1 becomes 0, 0 becomes 1.) The alpha value of each pixel should
//! be left unchanged.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_complement( struct Image *input_img, struct Image *output_img ) {
  for ( int32_t row = 0; row < input_img->height; row++ ) {
    for ( int32_t col = 0; col < input_img->width; col++ ) {
      int32_t index = compute_index( input_img, row, col );
      uint32_t pixel = input_img->data[index];
      
      // Extract color components
      uint32_t r = get_r( pixel );
      uint32_t g = get_g( pixel );
      uint32_t b = get_b( pixel );
      uint32_t a = get_a( pixel );  // alpha stays unchanged
      
      // invert bits to get complement
      r = (~r) & 0xFF;
      g = (~g) & 0xFF;
      b = (~b) & 0xFF;
      
      // Create new pixel and store in output
      output_img->data[index] = make_pixel( r, g, b, a );
    }
  }
}

//! Transform the input image by swapping the row and column
//! of each source pixel when copying it to the output image.
//! E.g., a pixel at row i and column j of the input image
//! should be copied to row j and column i of the output image.
//! Note that this transformation can only be applied to square
//! images (where the width and height are identical.)
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
//!
//! @return 1 if the transformation succeeded, or 0 if the
//!         transformation can't be applied because the image
//!         width and height are not the same
int imgproc_transpose( struct Image *input_img, struct Image *output_img ) {
  // Check if image is square
  if ( input_img->width != input_img->height ) {
    return 0;  // Can't transpose non-square image
  }
  
  // pixel at (i,j) goes to (j,i)
  for ( int32_t row = 0; row < input_img->height; row++ ) {
    for ( int32_t col = 0; col < input_img->width; col++ ) {
      int32_t src_index = compute_index( input_img, row, col );
      int32_t dst_index = compute_index( output_img, col, row );  // swapped row and col
      
      output_img->data[dst_index] = input_img->data[src_index];
    }
  }
  
  return 1;  // Success
}

//! Transform the input image by copying only those pixels that are
//! within an ellipse centered within the bounds of the image.
//! Pixels not in the ellipse should be left unmodified, which will
//! make them opaque black.
//!
//! Let w represent the width of the image and h represent the
//! height of the image. Let a=floor(w/2) and b=floor(h/2).
//! Consider the pixel at row b and column a is being at the
//! center of the image. When considering whether a specific pixel
//! is in the ellipse, x is the horizontal distance to the center
//! of the image and y is the vertical distance to the center of
//! the image. The pixel at the coordinates described by x and y
//! is in the ellipse if the following inequality is true:
//!
//!   floor( (10000*x*x) / (a*a) ) + floor( (10000*y*y) / (b*b) ) <= 10000
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_ellipse( struct Image *input_img, struct Image *output_img ) {
  //TODO
}

//! Transform the input image using an "emboss" effect. The pixels
//! of the source image are transformed as follows.
//!
//! The top row and left column of pixels are transformed so that their
//! red, green, and blue color component values are all set to 128,
//! and their alpha values are not modified.
//!
//! For all other pixels, we consider the pixel's color component
//! values r, g, and b, and also the pixel's upper-left neighbor's
//! color component values nr, ng, and nb. In comparing the color
//! component values of the pixel and its upper-left neighbor,
//! we consider the differences (nr-r), (ng-g), and (nb-b).
//! Whichever of these differences has the largest absolute value
//! we refer to as diff. (Note that in the case that more than one
//! difference has the same absolute value, the red difference has
//! priority over green and blue, and the green difference has priority
//! over blue.)
//!
//! From the value diff, compute the value gray as 128 + diff.
//! However, gray should be clamped so that it is in the range
//! 0..255. I.e., if it's negative, it should become 0, and if
//! it is greater than 255, it should become 255.
//!
//! For all pixels not in the top or left row, the pixel's red, green,
//! and blue color component values should be set to gray, and the
//! alpha value should be left unmodified.
//!
//! @param input_img pointer to the input Image
//! @param output_img pointer to the output Image (in which the
//!                   transformed pixels should be stored)
void imgproc_emboss( struct Image *input_img, struct Image *output_img ) {
      //TODO
    }
