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
	/*
	 * Check if a pixel at (row, col) is inside the ellipse
	 * Parameters:
	 *   %rdi - pointer to Image struct
	 *   %esi - row (32-bit)
	 *   %edx - col (32-bit)
	 * Returns:
	 *   %eax - 1 if inside ellipse, 0 if outside
	 * 
	 * Register use:
	 *   %r8d - a (width/2)
	 *   %r9d - b (height/2)
	 *   %r10d - x (col - a)
	 *   %r11d - y (row - b)
	 */
	
	/* prologue save callee-saved registers */
	pushq %rbp
	movq %rsp, %rbp
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	
	/* calculate a = width / 2 */
	movl IMAGE_WIDTH_OFFSET(%rdi), %eax  /* load width into eax */
	movl $2, %ecx     /* load divisor 2 into ecx */
	cdq    /* sign extend eax into edx for division */
	idivl %ecx   /* divide width by 2, result in eax */
	movl %eax, %r8d    /* store a in r8d */
	
	/* calculate b = height / 2 */
	movl IMAGE_HEIGHT_OFFSET(%rdi), %eax /* load height into eax */
	cdq    /* sign extend eax into edx for division */
	idivl %ecx   /* divide height by 2, result in eax */
	movl %eax, %r9d   /* store b in r9d */
	
	/* calculate x = col - a */
	movl %edx, %r10d   /* copy col to r10d */
	subl %r8d, %r10d   /* x = col - a, store in r10d */
	
	/* calculate y = row - b */
	movl %esi, %r11d   /* copy row to r11d */
	subl %r9d, %r11d   /* y = row - b, store in r11d */
	
	/* calculate x*x */
	movl %r10d, %eax   /* copy x to eax */
	imull %r10d, %eax   /* x * x, result in eax */
	movl %eax, %r10d   /* store x*x back in r10d */
	
	/* calculate y*y */
	movl %r11d, %eax   /* copy y to eax */
	imull %r11d, %eax   /* y * y, result in eax */
	movl %eax, %r11d   /* store y*y back in r11d */
	
	/* calculate 10000 * x*x */
	movl $10000, %eax    /* load constant 10000 into eax */
	imull %r10d, %eax    /* multiply 10000 by x*x */
	movl %eax, %r10d     /* store 10000*x*x in r10d */
	
	/* calculate 10000 * y*y */
	movl $10000, %eax    /* load constant 10000 into eax */
	imull %r11d, %eax    /* multiply 10000 by y*y */
	movl %eax, %r11d     /* store 10000*y*y in r11d */
	
	/* calculate a*a */
	movl %r8d, %eax      /* load a into eax */
	imull %r8d, %eax     /* calculate a*a in eax */
	movl %eax, %r8d      /* store a*a back in r8d */
	
	/* calculate b*b */
	movl %r9d, %eax      /* load b into eax */
	imull %r9d, %eax     /* calculate b*b in eax */
	movl %eax, %r9d      /* store b*b back in r9d */
	
	/* calculate (10000*x*x) / (a*a) */
	movl %r10d, %eax     /* load 10000*x*x into eax */
	cdq    /* sign extend eax for division */
	idivl %r8d    /* divide by a*a, result in eax */
	movl %eax, %r10d     /* store first term in r10d */
	
	/* calculate (10000*y*y) / (b*b) */
	movl %r11d, %eax     /* load 10000*y*y into eax */
	cdq    /* sign extend eax for division */
	idivl %r9d   /* divide by b*b, result in eax */
	
	/* check if term1 + term2 <= 10000 */
	addl %r10d, %eax     /* add first term to second term */
	cmpl $10000, %eax    /* compare sum with 10000 */
	jle .Lin_ellipse     /* jump if less than or equal to 10000 */
	
	/* outside ellipse - return 0 */
	movl $0, %eax        /* load 0 into return register */
	jmp .Lis_in_ellipse_done /* jump to end */
	
.Lin_ellipse:
	/* inside ellipse - return 1 */
	movl $1, %eax     /* load 1 into return register */
	
.Lis_in_ellipse_done:
	/* epilogue - restore callee-saved registers */
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rbp
	ret                                  /* return result in eax */

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
	
	movq %rdi, %r12 /* input image pointer */
	movq %rsi, %r13 /* output image pointer */
	
	movl $0, %r14d /* initialize row counter */

	
.Lcomplement_row_loop:

	// check if row < height
	movl IMAGE_HEIGHT_OFFSET(%r12), %eax /* put the height of the input into eax */
	cmpl %eax, %r14d /* check if the current row is greater than the total height */
	jge .Lcomplement_done /* if greater than or equal to, jump to end of loop */
	
	movl $0, %r15d /* initialize column counter */

.Lcomplement_col_loop:

	// check if col < width
	movl IMAGE_WIDTH_OFFSET(%r12), %eax /* move the width to eax */
	cmpl %eax, %r15d /* check if current column is greater than total width */
	jge .Lcomplement_next_row /*if greater, go to next row */
	
	// compute index = row * width + col
	movq %r12, %rdi /* move image pointer to rdi */
	movl %r14d, %esi /* move current row to esi */
	movl %r15d, %edx /* col current column to edx */
	call compute_index /* get the index of the pixel with the parameters just given */
	movl %eax, %ecx /* save index in %ecx in order to load pixel on line 153 */
	
	// load pixel from input image
	movq IMAGE_DATA_OFFSET(%r12), %rax /* put data pointer for the input image into rax */
	movl (%rax,%rcx,4), %ebx /* move the current pixel at index into ebx */
	
	// extract RGBA components
	movl %ebx, %edi /* put pixel in edi, can do this once cause pixel needed for parameter stays the same for each call*/
	call get_r
	movl %eax, %r8d /* put the red value into in %r8d */
	call get_g
	movl %eax, %r9d /* green into %r9d */
	call get_b
	movl %eax, %r10d /* blue into %r10d */
	call get_a
	movl %eax, %r11d /* alpha into %r11d */
	
	// complement RGB components
	notl %r8d /* complement red */
	andl $0xFF, %r8d /* mask to 8 bits */
	notl %r9d /* complement green */
	andl $0xFF, %r9d /* mask to 8 bits */
	notl %r10d /* complement blue */
	andl $0xFF, %r10d /* mask to 8 bits */
	
	// create new pixel
	movl %r8d, %edi /* red */
	movl %r9d, %esi /* green */
	movl %r10d, %edx /* blue */
	movl %r11d, %ecx /* alpha (unchanged) */
	call make_pixel
	
	// store pixel in output image
	movq %r12, %rdi /* image pointer for index calc */
	movl %r14d, %esi /* row */
	movl %r15d, %edx /* col */
	pushq %rax /* save pixel value */
	call compute_index
	popq %rdx /* restore pixel value to %rdx */
	movq IMAGE_DATA_OFFSET(%r13), %rcx /* get output data pointer */
	movl %edx, (%rcx,%rax,4) /* store pixel */
	
	incl %r15d /* increment column */
	jmp .Lcomplement_col_loop
	
.Lcomplement_next_row:

	incl %r14d /* increment row */
	jmp .Lcomplement_row_loop
	
.Lcomplement_done:

	/* epilogue, restore the callee saved registers */
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
	 * Register use:
	 *   %r12 - input Image pointer
	 *   %r13 - output Image pointer
	 *   %r14d - current row
	 *   %r15d - current column
	 */
	
	// prologue, save callee saved registers
	pushq %rbp
	movq %rsp, %rbp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	// save parameters
	movq %rdi, %r12 /* input Image pointer */
	movq %rsi, %r13 /* output Image pointer */
	
	// check if image is square 
	movl IMAGE_WIDTH_OFFSET(%r12), %eax /* put the width into eax */
	movl IMAGE_HEIGHT_OFFSET(%r12), %edx /* put the height into edx */
	cmpl %edx, %eax /* compare them */
	jne .Ltranspose_not_square /* if they are different, go to case where not square, return error */
	
	movl $0, %r14d /* initialize row counter */
	
.Ltranspose_row_loop:

	// check if row < height 
	movl IMAGE_HEIGHT_OFFSET(%r12), %eax /* put the height into eax */
	cmpl %eax, %r14d /* compare height and current row */
	jge .Ltranspose_success /* if current row greater than or equal to, successful, end loop */
	
	movl $0, %r15d /* initialize column counter */

.Ltranspose_col_loop:

	// check if col < width
	movl IMAGE_WIDTH_OFFSET(%r12), %eax /* put width into eax */
	cmpl %eax, %r15d /* compare current col and width */
	jge .Ltranspose_next_row /* if current col is greater or equal to, go to next row */
	
	// compute source index = row * width + col
	movq %r12, %rdi /* Image pointer */
	movl %r14d, %esi /* row */
	movl %r15d, %edx /* col */
	call compute_index
	movl %eax, %ecx /* source index in %ecx */
	
	// load pixel from input image
	movq IMAGE_DATA_OFFSET(%r12), %rax /* get input data pointer */
	movl (%rax,%rcx,4), %ebx /* load source pixel */
	
	// compute destination index = col * width + row (swapped)
	movq %r13, %rdi /* output Image pointer */
	movl %r15d, %esi /* col (becomes row) */
	movl %r14d, %edx /* row (becomes col) */
	call compute_index
	movl %eax, %ecx /* destination index in %ecx */
	
	// store pixel in output image 
	movq IMAGE_DATA_OFFSET(%r13), %rax /* get output data pointer */
	movl %ebx, (%rax,%rcx,4) /* store pixel at destination */
	
	incl %r15d /* increment col, restart col loop */
	jmp .Ltranspose_col_loop
	
.Ltranspose_next_row:

	incl %r14d /* increment row, restart row loop */
	jmp .Ltranspose_row_loop
	
.Ltranspose_success:

	movl $1, %eax /* return 1 for success */
	jmp .Ltranspose_done
	
.Ltranspose_not_square:

	movl $0, %eax /* return 0 for failure */
	
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
	/* Register use: %r12=input, %r13=output, %r14d=row, %r15d=col, %ebx=pixel */
	
	/* prologue: save callee-saved registers */
	pushq %rbp
	movq %rsp, %rbp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	pushq %rbx
	
	/* save parameters */
	movq %rdi, %r12          /* input Image pointer */
	movq %rsi, %r13          /* output Image pointer */
	
	/* a = width/2 and b = height/2 */
	movl IMAGE_WIDTH_OFFSET(%r12), %eax
	shrl $1, %eax           /* a = width/2 */
	movl %eax, %r8d          /* store a in %r8d */
	
	movl IMAGE_HEIGHT_OFFSET(%r12), %eax
	shrl $1, %eax           /* b = height/2 */
	movl %eax, %r9d          /* store b in %r9d */
	
	/* initialize row counter */
	movl $0, %r14d
	
.Lellipse_row_loop:
	/* check if row < height */
	movl IMAGE_HEIGHT_OFFSET(%r12), %eax
	cmpl %eax, %r14d
	jge .Limgproc_ellipse_done
	
	/* initialize column counter */
	movl $0, %r15d
	
.Lellipse_col_loop:
	/* check if col < width */
	movl IMAGE_WIDTH_OFFSET(%r12), %eax
	cmpl %eax, %r15d
	jge .Lellipse_next_row
	
	/* compute index = row * width + col */
	movl IMAGE_WIDTH_OFFSET(%r12), %eax
	movl %r14d, %ebx
	imull %eax, %ebx         /* row * width */
	addl %r15d, %ebx         /* + col, result in %ebx */
	
	/* calculate x = col - a */
	movl %r15d, %ecx
	subl %r8d, %ecx          /* x = col - a */
	
	/* calculate y = row - b */
	movl %r14d, %edx
	subl %r9d, %edx          /* y = row - b */
	
	/* calculate x*x */
	movl %ecx, %eax
	imull %eax, %eax         /* x*x */
	
	/* calculate (10000 * x*x) / (a*a) */
	movl $10000, %edi
	imull %edi, %eax         /* 10000 * x*x */
	movl %r8d, %edi
	imull %edi, %edi         /* a*a */
	testl %edi, %edi
	jz .Lellipse_outside     /* avoid division by zero */
	xorl %edx, %edx
	divl %edi                /* (10000 * x*x) / (a*a) */
	movl %eax, %esi          /* store term1 in %esi */
	
	/* calculate y*y */
	movl %r14d, %eax         /* reload row */
	subl %r9d, %eax          /* y = row - b */
	imull %eax, %eax         /* y*y */
	
	/* calculate (10000 * y*y) / (b*b) */
	movl $10000, %edi
	imull %edi, %eax         /* 10000 * y*y */
	movl %r9d, %edi
	imull %edi, %edi         /* b*b */
	testl %edi, %edi
	jz .Lellipse_outside     /* avoid division by zero */
	xorl %edx, %edx
	divl %edi                /* (10000 * y*y) / (b*b) */
	
	/* check if term1 + term2 <= 10000 */
	addl %esi, %eax          /* term1 + term2 */
	cmpl $10000, %eax
	jg .Lellipse_outside     /* outside ellipse */
	
	/* inside ellipse copy original pixel */
	movq IMAGE_DATA_OFFSET(%r12), %rax  /* get input data pointer */
	movl (%rax,%rbx,4), %eax            /* load original pixel */
	jmp .Lellipse_store_pixel
	
.Lellipse_outside:
	/* outside ellipse to black */
	movl $0x000000ff, %eax   /* black pixel */
	
.Lellipse_store_pixel:
	/* store pixel in output image */
	movq IMAGE_DATA_OFFSET(%r13), %rcx  /* get output data pointer */
	movl %eax, (%rcx,%rbx,4)            /* store pixel */
	
	/* increment column */
	incl %r15d
	jmp .Lellipse_col_loop
	
.Lellipse_next_row:
	/* increment row */
	incl %r14d
	jmp .Lellipse_row_loop
	
.Limgproc_ellipse_done:
	/* epilogue: restore callee-saved registers */
	popq %rbx
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
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

	/*
	 * Register use:
	 *   %r12 - input Image pointer
	 *   %r13 - output Image pointer
	 *   %r14d - current row
	 *   %r15d - current column
	 * Stack locals:
	 *   -4(%rbp) - current pixel value
	 *	 -8(%rbp) - top left pixel value
	 *	 -12(%rbp) - red diff
	 *	 -16(%rbp) - green diff
	 *	 -20(%rbp) - blue diff
	 *	 -24(%rbp) - highest diff
	 *	 -28(%rbp) - current pixel index
	 */

	//prologue, save callee safe registers
	pushq %rbp
	movq %rsp, %rbp
	subq $32, %rsp
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15

	//put input into r12, output into r13
	movq %rdi, %r12
	movq %rsi, %r13
	
	//initialize current row to 0
	movl $0, %r14d

	//row loop to get all pixels
	.Lemboss_row_loop:

		//compare current row to total rows, if greater end loop go to end
		cmpl %r14d, IMAGE_HEIGHT_OFFSET(%r12)
		jle .Lemboss_done

		//initialize current col to 0
		movl $0, %r15d

		//col loop to get all pixels
		.Lemboss_col_loop:

			//see if current col greater than width, if so, next row
			cmpl %r15d, IMAGE_WIDTH_OFFSET(%r12)
			jle .Lemboss_next_row

			//put parameters and call compute index to find current pixel
			movq %r12, %rdi
			movl %r14d, %esi
			movl %r15d, %edx
			call compute_index

			//put the found pixel into -4(%rbp), and index into -28(%rbp)
			movl %eax, -28(%rbp) /* save index in -24(%rbp) */
			movl %eax, %ecx /* put index in %ecx in order to load pixel */
			// load pixel from input image
			movq IMAGE_DATA_OFFSET(%r12), %rax /* put data pointer for the input image into rax */
			movl (%rax,%rcx,4), %eax /* load pixel into %eax */
			movl %eax, -4(%rbp) /* store into local variable */


			//see if the row is 0, if so, go to set pixel 128, else continue with diff
			cmpl $0, %r14d 
			jz .Lemboss_set_pixel_128

			//see if the col is 0, if so go to set pixel 128, else continue with diff
			cmpl $0, %r15d
			jz .Lemboss_set_pixel_128

			//continue with regular find difference of top left and set to max diff:


			//find index of the upper left pixel, subtract 1 from row and col and call again
			subl $1, %esi
			subl $1, %edx
			call compute_index
	

			//put the found pixel into -8(%rbp)
			movl %eax, %ecx /* save index in %ecx in order to load pixel*/
			// load pixel from input image
			movq IMAGE_DATA_OFFSET(%r12), %rax /* put data pointer for the input image into rax */
			movl (%rax,%rcx,4), %edx /* load pixel into %edx */
			movl %edx, -8(%rbp) /* store into -8(%rbp) */

			//get red value of top left and put in -12(%rbp)
			movl -8(%rbp), %edi
			call get_r
			movl %eax, -12(%rbp)

			//get green value of top left and put in -16(%rbp)
			call get_g
			movl %eax, -16(%rbp)

			//get blue value of top left and put in -20(%rbp)
			call get_b
			movl %eax, -20(%rbp)

			//get red value of current and subtract it from top left red value to store in -12(%rbp)
			movl -4(%rbp), %edi
			call get_r
			subl %eax, -12(%rbp) /* now current red diff, nr - r, in -12(%rbp) */

			//get green value of current and subtract it from top left red value to store in -16(%rbp)
			call get_g
			subl %eax, -16(%rbp) /* now current red diff, nb - b, in -16(%rbp) */

			//get red value of current and subtract it from top left red value to store in -12(%rbp)
			call get_b
			subl %eax, -20(%rbp) /* now current red diff, ng - g, in -20(%rbp) */

			//begin by moving red diff in highest diff, and putting it into %eax
			movl -12(%rbp), %eax
			movl %eax, -24(%rbp)

			//absolute value of highest diff (red right now)
			cmpl $0, %eax
			jge .Lskip_negate_for_abs1
			negl %eax /* negate if %eax is negative to become positive */
			.Lskip_negate_for_abs1:

			//put green diff into %ecx
			movl -16(%rbp), %ecx

			//absolute value of green diff
			cmpl $0, %ecx
			jge .Lskip_negate_for_abs2
			negl %ecx /* negate if %ecx is negative to become positive */
			.Lskip_negate_for_abs2:

			//compare abs green diff to current abs highest diff (red right now)
			cmpl %ecx, %eax
			jge .Lcurrent_highest_still_higher1
			movl %ecx, %eax /* put current highest absolute value (green) into %eax */
			movl -16(%rbp), %edx /* put current highest regular value (green) into %edx */
			movl %edx, -24(%rbp) /* then into -24(%rbp) */
			.Lcurrent_highest_still_higher1:

			//put blue diff into %ecx
			movl -20(%rbp), %ecx

			//absolute value of blue diff
			cmpl $0, %ecx
			jge .Lskip_negate_for_abs3
			negl %ecx /* negate if %ecx is negative to become positive */
			.Lskip_negate_for_abs3:

			//compare abs blue diff to currrent abs highest diff (red or green right now)
			cmpl %ecx, %eax
			jge .Lcurrent_highest_still_higher2
			movl %ecx, %eax /* put current highest absolute value (blue) into %eax */
			movl -20(%rbp), %edx /* put current highest regular value (blue) into %edx */
			movl %edx, -24(%rbp) /* then into -24(%rbp) */
			.Lcurrent_highest_still_higher2:

			//current highest value is in -24(%rbp), calc gray with that
			addl $128, -24(%rbp)

			//if gray is > 255, set to 255, else, go to val over is okay
			cmpl $255, -24(%rbp)
			jle .Lgray_val_over_is_okay

			movl $255, -24(%rbp) /* if greater than 255, will set to 255 because it didnt jump to over is okay */
			jmp .Lgray_val_is_good /* gray is good if was set to 255, so skip checking if less than 0 */

			//if gray is < 0, set to 0, else val is okay
			.Lgray_val_over_is_okay:
			cmpl $0, -24(%rbp)
		
			jg .Lgray_val_is_good /* if -24(%rbp) is positive or 0, skip ahead to is good */
			movl $0, -24(%rbp) /* else set to 0 and val is good now */

			//gray value is correct 
			.Lgray_val_is_good:

			//put gray values into parameters to make pixel
			movl -24(%rbp), %edi
			movl -24(%rbp), %esi
			movl -24(%rbp), %edx
			jmp .Lcontinue_emboss /* skip setting values to 128 */

			//if top row or left col, set to 128
			.Lemboss_set_pixel_128:
			//if pixel is in top row or left column set r g b to 128
			movl $128, %edi
			movl $128, %esi
			movl $128, %edx

			.Lcontinue_emboss:
			andl $0xFF, -4(%rbp) /* get original alpha value and put into %ecx*/
			movl -4(%rbp), %ecx
			call make_pixel

			//put pixel into output image

			movq IMAGE_DATA_OFFSET(%r13), %rdi /* put data pointer for the output image into %rdi, pixel in %eax */
			movl -28(%rbp), %ecx /* put index into %ecx */
			movl %eax, (%rdi, %rcx, 4) /* move the current pixel into output image at index */

			incl %r15d /* increment col, restart col loop */
			jmp .Lemboss_col_loop
			
		.Lemboss_next_row:
		//increment row, restart row loop
		incl %r14d
		jmp .Lemboss_row_loop

	.Lemboss_done:
		popq %r15
		popq %r14
		popq %r13
		popq %r12
		addq $32, %rsp
		popq %rbp 
		ret



/*
vim:ft=gas:
*/
