/*
 * x86-64 assembly language implementations of functions
 */

	.text

/* Offsets of struct Image fields */
#define IMAGE_WIDTH_OFFSET   0
#define IMAGE_HEIGHT_OFFSET  4
#define IMAGE_DATA_OFFSET    8

/*
 * TODO: define your helper functions here.
 * Don't forget to use the .globl directive to make
 * them visible to the test code.
 */

	.globl get_r
get_r:
	movl %edi, %eax /* argument is the pixel, so its in %edi as a 32 bit unit, move it to eax to be returned */
	shrl $24, %eax /* shift the bits right 24 to get the first 8 bits */
	andl $0xFF, %eax /* filter out the first 24 bits of the new uint post shift for the red value */
	ret

	.globl get_g
get_g:
	movl %edi, %eax /* argument is the pixel, so its in %edi as a 32 bit unit, move it to eax to be returned */
	shrl $16, %eax /* shift the bits right 16 to get the second 8 bits */
	andl $0xFF, %eax /* filter out the first 24 bits of the new uint post shift for the green value */
	ret

	.globl get_b
get_b:
	movl %edi, %eax /* argument is the pixel, so its in %edi as a 32 bit unit, move it to eax to be returned */
	shrl $8, %eax /* shift the bits right 8 to get the third 8 bits */
	andl $0xFF, %eax /* filter out the first 24 bits of the new uint post shift for the blue value */
	ret

	.globl get_a
get_a:
	movl %edi, %eax /* argument is the pixel, so its in %edi as a 32 bit unit, move it to eax to be returned */
	andl $0xFF, %eax /* filter out the first 24 bits of uint for the alpha value */
	ret

	.globl make_pixel
make_pixel: 

	movl %edi, %eax /* put red value into eax */
	shll $24, %eax /* put red value into first 8 bits */
	andl $0xFF000000, %eax /* filter out the rest of the bits so they are 0 */

	shll $16, %esi /* put the green value at the second 8 bits of esi */
	andl $0xFF0000, %esi /* filter out the rest of the bits so they are 0 */
	orl %esi, %eax /* put the green value in the second 8 bits of eax */

	shll $8, %edx /* put the blue value in the third 8 bits of edx */
	andl $0xFF00, %edx /* filter out the rest of the bits so they are 0 */
	orl %edx, %eax /* put the blue value in the third 8 bits of eax */

	andl $0xFF, %ecx /* filter out the first 24 bits of the alpha value */
	orl %ecx, %eax /* put the alpha value in the last 8 bits of eax */

	ret

	.globl compute_index
compute_index:
	/*
	 * Compute array index from row and column
	 * Parameters:
	 *   %rdi - pointer to image struct
	 *   %esi - row (32-bit)
	 *   %edx - col (32-bit)
	 * Returns:
	 *   %eax - index (row * width + col)
	 */
	movl IMAGE_WIDTH_OFFSET(%rdi), %eax  /* load width into %eax */
	imull %esi, %eax                     /* multiply width by row */
	addl %edx, %eax                      /* add column */
	ret

	.globl is_in_ellipse
is_in_ellipse:
	ret

/*
 * Definitions of image transformation functions
 */

/*
 *  Transform the color component values in each input pixel
 *  by applying the bitwise complement operation. I.e., each bit
 *  in the color component information should be inverted
 *  (1 becomes 0, 0 becomes 1.) The alpha value of each pixel should
 *  be left unchanged.
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *         transformed pixels should be stored)
 */
	.globl imgproc_complement
imgproc_complement:
	/*
	 * Transform color components using bitwise complement
	 * Parameters:
	 *   %rdi - pointer to input image
	 *   %rsi - pointer to output image
	 * 
	 * Register use:
	 *   %r12 - input Image pointer
	 *   %r13 - output Image pointer
	 *   %r14d - current row
	 *   %r15d - current column
	 *   %ebx - current pixel value
	 */
	
	/* save callee-saved registers */
	pushq %rbp
	movq %rsp, %rbp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	
	/* save parameters */
	movq %rdi, %r12          /* input image pointer */
	movq %rsi, %r13          /* output image pointer */
	
	/* initialize row counter */
	movl $0, %r14d
	
.Lcomplement_row_loop:
	/* check if row < height */
	movl IMAGE_HEIGHT_OFFSET(%r12), %eax
	cmpl %eax, %r14d
	jge .Lcomplement_done
	
	/* initialize column counter */
	movl $0, %r15d
	
.Lcomplement_col_loop:
	/* check if col < width */
	movl IMAGE_WIDTH_OFFSET(%r12), %eax
	cmpl %eax, %r15d
	jge .Lcomplement_next_row
	
	/* compute index = row * width + col */
	movq %r12, %rdi          /* Image pointer */
	movl %r14d, %esi         /* row */
	movl %r15d, %edx         /* col */
	call compute_index
	movl %eax, %ecx          /* save index in %ecx */
	
	/* load pixel from input image */
	movq IMAGE_DATA_OFFSET(%r12), %rax  /* get data pointer */
	movl (%rax,%rcx,4), %ebx            /* load pixel at index */
	
	/* extract RGBA components */
	movl %ebx, %edi
	call get_r
	movl %eax, %r8d          /* red in %r8d */
	
	movl %ebx, %edi
	call get_g
	movl %eax, %r9d          /* green in %r9d */
	
	movl %ebx, %edi
	call get_b
	movl %eax, %r10d         /* blue in %r10d */
	
	movl %ebx, %edi
	call get_a
	movl %eax, %r11d         /* alpha in %r11d */
	
	/* complement RGB components */
	notl %r8d                /* complement red */
	andl $0xFF, %r8d         /* mask to 8 bits */
	
	notl %r9d                /* complement green */
	andl $0xFF, %r9d         /* mask to 8 bits */
	
	notl %r10d               /* complement blue */
	andl $0xFF, %r10d        /* mask to 8 bits */
	
	/* create new pixel */
	movl %r8d, %edi          /* red */
	movl %r9d, %esi          /* green */
	movl %r10d, %edx         /* blue */
	movl %r11d, %ecx         /* alpha (unchanged) */
	call make_pixel
	
	/* store pixel in output image */
	movq %r12, %rdi          /* Image pointer for index calc */
	movl %r14d, %esi         /* row */
	movl %r15d, %edx         /* col */
	pushq %rax               /* save pixel value */
	call compute_index
	popq %rdx                /* restore pixel value to %rdx */
	movq IMAGE_DATA_OFFSET(%r13), %rcx  /* get output data pointer */
	movl %edx, (%rcx,%rax,4)            /* store pixel */
	
	/* increment column */
	incl %r15d
	jmp .Lcomplement_col_loop
	
.Lcomplement_next_row:
	/* increment row */
	incl %r14d
	jmp .Lcomplement_row_loop
	
.Lcomplement_done:
	/* epilogue - restore callee-saved registers */
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
	ret

/*
 *  Transform the input image by swapping the row and column
 *  of each source pixel when copying it to the output image.
 *  E.g., a pixel at row i and column j of the input image
 *  should be copied to row j and column i of the output image.
 *  Note that this transformation can only be applied to square
 *  images (where the width and height are identical.)
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 * 
 *  @return 1 if the transformation succeeded, or 0 if the
 *          transformation can't be applied because the image
 *          width and height are not the same
 */
	.globl imgproc_transpose
imgproc_transpose:
	/*
	 * Transform image by swapping rows and columns
	 * Parameters:
	 *   %rdi - pointer to input Image
	 *   %rsi - pointer to output Image
	 * Returns:
	 *   %eax - 1 if successful, 0 if image not square
	 * 
	 * Register use:
	 *   %r12 - input Image pointer
	 *   %r13 - output Image pointer
	 *   %r14d - current row
	 *   %r15d - current column
	 */
	
	/* prologue - save callee-saved registers */
	pushq %rbp
	movq %rsp, %rbp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	/* save parameters */
	movq %rdi, %r12          /* input Image pointer */
	movq %rsi, %r13          /* output Image pointer */
	
	/* check if image is square */
	movl IMAGE_WIDTH_OFFSET(%r12), %eax
	movl IMAGE_HEIGHT_OFFSET(%r12), %edx
	cmpl %edx, %eax
	jne .Ltranspose_not_square
	
	/* initialize row counter */
	movl $0, %r14d
	
.Ltranspose_row_loop:
	/* check if row < height */
	movl IMAGE_HEIGHT_OFFSET(%r12), %eax
	cmpl %eax, %r14d
	jge .Ltranspose_success
	
	/* initialize column counter */
	movl $0, %r15d
	
.Ltranspose_col_loop:
	/* check if col < width */
	movl IMAGE_WIDTH_OFFSET(%r12), %eax
	cmpl %eax, %r15d
	jge .Ltranspose_next_row
	
	/* compute source index = row * width + col */
	movq %r12, %rdi          /* Image pointer */
	movl %r14d, %esi         /* row */
	movl %r15d, %edx         /* col */
	call compute_index
	movl %eax, %ecx          /* source index in %ecx */
	
	/* load pixel from input image */
	movq IMAGE_DATA_OFFSET(%r12), %rax  /* get input data pointer */
	movl (%rax,%rcx,4), %ebx            /* load source pixel */
	
	/* compute destination index = col * width + row (swapped) */
	movq %r13, %rdi          /* output Image pointer */
	movl %r15d, %esi         /* col (becomes row) */
	movl %r14d, %edx         /* row (becomes col) */
	call compute_index
	movl %eax, %ecx          /* destination index in %ecx */
	
	/* store pixel in output image */
	movq IMAGE_DATA_OFFSET(%r13), %rax  /* get output data pointer */
	movl %ebx, (%rax,%rcx,4)            /* store pixel at destination */
	
	/* increment column */
	incl %r15d
	jmp .Ltranspose_col_loop
	
.Ltranspose_next_row:
	/* increment row */
	incl %r14d
	jmp .Ltranspose_row_loop
	
.Ltranspose_success:
	/* return 1 for success */
	movl $1, %eax
	jmp .Ltranspose_done
	
.Ltranspose_not_square:
	/* return 0 for failure */
	movl $0, %eax
	
.Ltranspose_done:
	/* epilogue - restore callee-saved registers */
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
	ret

/*
 *  Transform the input image by copying only those pixels that are
 *  within an ellipse centered within the bounds of the image.
 *  Pixels not in the ellipse should be left unmodified, which will
 *  make them opaque black.
 * 
 *  Let w represent the width of the image and h represent the
 *  height of the image. Let a=floor(w/2) and b=floor(h/2).
 *  Consider the pixel at row b and column a is being at the
 *  center of the image. When considering whether a specific pixel
 *  is in the ellipse, x is the horizontal distance to the center
 *  of the image and y is the vertical distance to the center of
 *  the image. The pixel at the coordinates described by x and y
 *  is in the ellipse if the following inequality is true:
 * 
 *    floor( (10000*x*x) / (a*a) ) + floor( (10000*y*y) / (b*b) ) <= 10000
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_ellipse
imgproc_ellipse:
	/* TODO: implement */
	ret

/*
 *  Transform the input image using an "emboss" effect. The pixels
 *  of the source image are transformed as follows.
 * 
 *  The top row and left column of pixels are transformed so that their
 *  red, green, and blue color component values are all set to 128,
 *  and their alpha values are not modified.
 * 
 *  For all other pixels, we consider the pixel's color component
 *  values r, g, and b, and also the pixel's upper-left neighbor's
 *  color component values nr, ng, and nb. In comparing the color
 *  component values of the pixel and its upper-left neighbor,
 *  we consider the differences (nr-r), (ng-g), and (nb-b).
 *  Whichever of these differences has the largest absolute value
 *  we refer to as diff. (Note that in the case that more than one
 *  difference has the same absolute value, the red difference has
 *  priority over green and blue, and the green difference has priority
 *  over blue.)
 * 
 *  From the value diff, compute the value gray as 128 + diff.
 *  However, gray should be clamped so that it is in the range
 *  0..255. I.e., if it's negative, it should become 0, and if
 *  it is greater than 255, it should become 255.
 * 
 *  For all pixels not in the top or left row, the pixel's red, green,
 *  and blue color component values should be set to gray, and the
 *  alpha value should be left unmodified.
 * 
 *  Parameters:
 *  %rdi - pointer to the input Image
 *  %rsi - pointer to the output Image (in which the
 *                    transformed pixels should be stored)
 */
	.globl imgproc_emboss
imgproc_emboss:
	/* TODO: implement */
	ret

/*
vim:ft=gas:
*/
