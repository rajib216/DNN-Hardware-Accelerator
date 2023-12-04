/*
Kernel Description (Baseline Example) :

    This kernel performs CNN (Convolutional Neural Network) convolution
    operation of given input image and weight matrix. This implementation uses large local buffers (load all variables)
    and pipelined computation at the innermost loop.

    Arguments :

        int *image    (input ) --> Input Image
        int *weight   (input ) --> Input Weights
        int *out      (output) --> Output Filters/Images
        int  size     (input ) --> Output Size

    Kernel Configuration :

        1. Output Filters  = 256 (Size = 27 x 27)

        -----------------------------------------------------
        | Parameter     | Value |   Description             |
        -----------------------------------------------------
        | Channels      | 96    | #Input Channels           |
        -----------------------------------------------------
        | IHeight       | 27    | Input Image Height        |
        -----------------------------------------------------
        | IWidth        | 27    | Input Image Width         |
        -----------------------------------------------------
        | Window        | 5     | Convolution Window Size   |
        -----------------------------------------------------
        | Stride        | 1     | Convolution Stride        |
        -----------------------------------------------------
        | Padding       | 2     | Convolution Image Padding |
        -----------------------------------------------------
        | OutputFilters | 256   | Output Filters/Images     |
        -----------------------------------------------------
        | OHeight       | 27    | Output Image Height       |
        -----------------------------------------------------
        | OWidth        | 27    | Output Image Width        |
        -----------------------------------------------------

    Memory Usage :

        1. Image    ~ (IHeight x IWidth x Channels):[274 KB]
        2. Weights  ~ (OutputFilters x Channels x Window x Window):[2400 KB]
        3. Output   ~ (OutputFilters x OHeight x OWidth):[729 KB]

*/
#include "params.h"


  void conv_pipeline_large_local_buffer(
          int *image,     // Read-Only Image
          int *weights,   // Read-Only Weight Matrix
          int *out,       // Output Filters/Images
          int i_chan,     // Input Channels
          int o_chan      // Output Channels
          )
  {
  #pragma HLS INTERFACE m_axi port=image offset=slave bundle=gmem
  #pragma HLS INTERFACE m_axi port=weights offset=slave bundle=gmem
  #pragma HLS INTERFACE m_axi port=out offset=slave bundle=gmem

  #pragma HLS INTERFACE s_axilite port=image bundle=control
  #pragma HLS INTERFACE s_axilite port=weights bundle=control
  #pragma HLS INTERFACE s_axilite port=out bundle=control
  #pragma HLS INTERFACE s_axilite port=i_chan bundle=control
  #pragma HLS INTERFACE s_axilite port=o_chan bundle=control
  #pragma HLS INTERFACE s_axilite port=return bundle=control

      // Local buffer to hold image, weight & output
      int img_lcl[IChan * ISize * ISize];
      int out_lcl[OChan * OSize * OSize];
      int wgt_lcl[WOutChan * WInChan * WSize * WSize];

      // Burst Read Image
      readImg: for(int i = 0; i < i_chan * ISize * ISize; i++){
    #pragma HLS PIPELINE II=1
	  #pragma HLS LOOP_TRIPCOUNT min=c_ichan*c_isize*c_isize max=c_ichan*c_isize*c_isize
          img_lcl[i] = image[i];
      }

      // Burst Read Weights
      readWt: for(int i = 0; i < o_chan * WInChan * WSize * WSize; i++) {
    #pragma HLS PIPELINE II=1
	  #pragma HLS LOOP_TRIPCOUNT min=c_ochan*c_ichan*c_wsize*c_wsize max=c_ochan*c_ichan*c_wsize*c_wsize
          wgt_lcl[i] = weights[i];
      }

      // Runs over output filters
      outputLoop: for(int output = 0, count = 0; output < o_chan; output++) {
      #pragma HLS LOOP_TRIPCOUNT min=c_ochan max=c_ochan
          // Runs over Y-Axis of output filter
          outYAxis: for(int y = 0; y < OSize; y++) {
              // Runs over X-Axis of output filter
              outXAxis: for(int x = 0; x < OSize; x++) {
                  short acc = 0;
                  // Runs over input channel
                  convInchan: for(int input = 0; input < i_chan; input++) {
                  #pragma HLS LOOP_TRIPCOUNT min=c_ichan max=c_ichan
                      // Runs over filter window in Y-direction
                      convILoop: for(int i = 0; i < WSize; i++) {
                          // Runs over filter windows in X-direction
                          convJLoop: for(int j = 0; j < WSize; j++) {
                            #pragma HLS PIPELINE II=1
                              // Calculates padding boundaries in X & Y direction
                              int xVal = x*Stride + j-Padding, yVal = y*Stride + i-Padding;

                              if(yVal >= 0 && yVal < ISize && xVal >= 0 && xVal < ISize) {
                                  acc +=    (short) img_lcl[(input*ISize + yVal)*ISize + xVal] *
                                          (short) wgt_lcl[((output*i_chan + input)*WSize + i)*WSize + j];
                              }
                          }
                      }
                  }

                  // Updates local output buffer
                  out_lcl[count++] = acc;
              }
          }
      }

      // Burst write output
      writeOut: for(int i = 0; i < o_chan * OSize * OSize; i++) {
    #pragma HLS PIPELINE II=1
	  #pragma HLS LOOP_TRIPCOUNT min=c_ichan*c_osize*c_osize max=c_ochan*c_osize*c_osize
          out[i] = out_lcl[i];
      }

      return;
}
