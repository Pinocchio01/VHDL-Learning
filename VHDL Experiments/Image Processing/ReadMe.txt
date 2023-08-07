1. The image_processor_top.vhd source file uses Xilinx FIFO Generator IP core.
    Before run the testbench for it, add it to your project.
2. Simply modify the kernel constant in conv.vhd to perform different image processing operations.
3. The script is for grayscale images, for color images the code should be adjusted.
4. Check the bmp file header width before running the code and modify TYPE header_type range in tb_image_processor_top.vhd.
5. Use "sent_size < C_image_height * (C_image_width - 1) " instead of C*C when set the termination condition. 
    Or there will be "File lena_gray.bmp is at end of file. Cannot read from it" error in tcl.
6. Put the image in xsim folder, or use the full path of the image for Vivado to read it.