/*
Kernel Description :

This kernel performs CNN (Convolutional Neural Network) convolution
operation of given input image and weight matrix. This implementation uses improved pipelined version
with

    Arguments :

        int *image   (input )  --> Input Image
        int *weight  (input )  --> Input Weights
        int *out     (output)  --> Output filters
        int  size    (input )  --> Output size
    Kernel Configuration :

        1. Output Channels    = 256

        -----------------------------------------------------
        | Parameter     | Value |   Description             |
        -----------------------------------------------------
        | Channels      | 64    | #Input Channels           |
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
        | OutputFilters | 32   | Output Filters/Images     |
        -----------------------------------------------------
        | OHeight       | 27    | Output Image Height       |
        -----------------------------------------------------
        | OWidth        | 27    | Output Image Width        |
        -----------------------------------------------------
    Memory Usage:

        1. Image    ~ (IHeight x IWidth x Channels):[2.84 x 96 KB]
        2. Weights  ~ (Channels x Window x Window):[96 x 0.09 KB]
        3. Output   ~ (OHeight x OWidth):[2.84 KB]

*/

#include "params.h"

void copy_weight(int *weight, int wgt_lcl[WInChan][WSize * WSize], int output)
{
#pragma HLS INLINE
    // Calculate each work_item's weight matrix location
    int stride = output * WInChan * WSize * WSize;

    // Each work_item copies weight matrix from DDR to local buffer
    readWt: for(int itr = 0, i = 0, j = 0; itr < WInChan * WSize * WSize; itr++,j++) {
    #pragma HLS PIPELINE II=1
        if(j == WSize * WSize) {j = 0; i++;}
        wgt_lcl[i][j] = weight[stride + itr];
    }
}

void copy_output(int *out, int out_lcl[OChan][OSize * OSize], int output)
{
#pragma HLS INLINE
    // Calculate each work_item's result update location
    int stride = output * OSize * OSize;

    // Work_item updates output filter/image in DDR
    writeOut: for(int itr = 0; itr < OSize * OSize; itr++) {
    #pragma HLS PIPELINE II=1
        out[stride + itr] = out_lcl[output][itr];
    }
}

void convolution_operation(int img_lcl[IChan][ISize * ISize], int wgt_lcl[WInChan][WSize * WSize], int out_lcl[OChan][OSize * OSize],int output, int y, int x, int i_chan)
{
#pragma HLS INLINE

    // Holds temporary accumulator values
    short acc[IChan][WSize][WSize];
    #pragma HLS ARRAY_PARTITION variable=acc complete dim=1

    // Holds Image Padding Boundary Check Variables
    int xVal_base = x * Stride - Padding;
    int yVal = y * Stride - Padding;

    // Runs over filter window
    convYaxis: for(int i = 0; i < WSize; i++,yVal++){
        // Runs over filter window
        convXaxis: for(int j = 0, xVal = xVal_base ; j < WSize; j++,xVal++){
        #pragma HLS PIPELINE II=1
            // Runs over each of the input channels
            convInchan: for(int input = 0; input < IChan; input++){

                // Convolution operation
                if(yVal >= 0 && yVal < ISize && xVal >= 0 && xVal < ISize) {
                    acc[input][i][j] =  (short) img_lcl[input][yVal * ISize + xVal] *
                                        (short) wgt_lcl[input][i * WSize + j];
                }
                else {
                    acc[input][i][j] = 0;
                }
            }
        }
    }

    // Summation of temporary accumulator buffer
    short sum = 0;
    accJ: for(int j = 0; j < WSize;j++) {
        accK: for(int k = 0; k < WSize; k++) {
        #pragma HLS PIPELINE II=1
            accI: for(int i = 0; i < 16; i++) {
            #pragma HLS LOOP_TRIPCOUNT min=32 max=32
              sum += acc[i][j][k];
        }
      }
    }

    // Update output pixel
    out_lcl[output][y * OSize + x] = sum;
}


void conv_pipeline_improved(
          int *image,         // Read-Only Image
          int *weights,       // Read-Only Weight Matrix
          int *out,           // Output Filters/Images
          int i_chan,         // Input Channels
          int o_chan         // Output Channels
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

      // Local Buffer to Hold Input Image
      int img_lcl[IChan][ISize * ISize];
      #pragma HLS ARRAY_PARTITION variable=img_lcl complete dim=1

      // Local Buffer to Hold Output Filters/Images
      int cu = no_cu;
      int out_lcl[OChan][OSize * OSize];
      #pragma HLS ARRAY_PARTITION variable=out_lcl block factor=cu dim=1

      // Local Buffer to Hold Weight Matrix;
      int wgt_lcl[WInChan][WSize * WSize];
      #pragma HLS ARRAY_PARTITION variable=wgt_lcl complete dim=1

      // Read Image
      readImg: for(int itr = 0, i = 0, j = 0; itr < i_chan * ISize * ISize; itr++, j++) {
      #pragma HLS LOOP_TRIPCOUNT min=c_ichan*c_isize*c_isize max=c_ichan*c_isize*c_isize
      #pragma HLS PIPELINE II=1
          if(j == ISize * ISize) {j = 0; i++;}
              img_lcl[i][j] = image[itr];
      }



      outThread: for(int output = 0; output < o_chan; output++) {
      #pragma HLS unroll factor=cu
      #pragma HLS LOOP_TRIPCOUNT min=c_ochan/cu max=c_ochan/cu

          // Burst read weight data from global to local buffer
          copy_weight(weights, wgt_lcl, output);

          outYaxis: for(int y = 0; y < OSize; y++) {
              outXaxis: for(int x = 0; x < OSize; x++) {
                 // Perform convolution for the current 'pixel'
                 convolution_operation(img_lcl, wgt_lcl, out_lcl, output, y, x, i_chan);
              }
          }

          // Burst write output
          copy_output(out, out_lcl, output);
      }

      return;
  }
