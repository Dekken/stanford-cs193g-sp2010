// This is machine problem 1, part 1, shift cypher
//
// The problem is to take in a string of unsigned chars and an int,
// the shift amount, and add the number to each element of
// the string, effectively "shifting" each element in the 
// string.

#include <stdlib.h>
#include <stdio.h>


// Repeating from the tutorial, just in case you haven't looked at it.

// "kernels" or __global__ functions are the entry points to code that executes on the GPU
// The keyword __global__ indicates to the compiler that this function is a GPU entry point.
// __global__ functions must return void, and may only be called or "launched" from code that
// executes on the CPU.

#define uchar unsigned char

void host_shift_cypher(uchar *input_array, uchar *output_array, int shift_amount, int alphabet_max, int array_length)
{
	int i;
	for(i=0;i<array_length;i++)
	{
		int element = input_array[i];
		int shifted = element + shift_amount;
		if(shifted > alphabet_max || shifted < 0)
		{
			shifted = shifted % (alphabet_max + 1);
		}
		output_array[i] = (uchar)shifted;
	}
}


// This kernel implements a per element shift
__global__ void shift_cypher(uchar *input_array, uchar *output_array, int shift_amount, int alphabet_max, int array_length)
{
	// your code here
}


int main(void)
{
  // create arrays of 256 elements
  int num_elements = 256;

  
  int alphabet_max = 255;
  
  // compute the size of the arrays in bytes
  int num_bytes = num_elements * sizeof(unsigned char);

  // pointers to host & device arrays
  uchar *host_input_array = 0;
  uchar *host_output_array = 0;
  uchar *host_output_checker_array = 0;
  uchar *device_input_array = 0;
  uchar *device_output_array = 0;
  

  // malloc a host array
  host_input_array = (uchar*)malloc(num_bytes);
  host_output_array = (uchar*)malloc(num_bytes);
  host_output_checker_array = (uchar*)malloc(num_bytes);

  // cudaMalloc two device arrays
  cudaMalloc((void**)&device_input_array, num_bytes);
  cudaMalloc((void**)&device_output_array, num_bytes);
  
  // if either memory allocation failed, report an error message
  if(host_input_array == 0 || host_output_array == 0 || host_output_checker_array == 0 || 
	device_input_array == 0 || device_output_array == 0)
  {
    printf("couldn't allocate memory\n");
    return 1;
  }

  // generate random input string
  // initialize
  srand(1);
  
  int shift_amount = rand();
  
  for(int i=0;i< num_elements;i++)
  {
	host_input_array[i] = (uchar)rand(); 
  }
  
  // copy input to GPU
  cudaMemcpy(device_input_array, host_input_array, num_bytes, cudaMemcpyHostToDevice);

  // choose a number of threads per block
  // 128 threads (4 warps) tends to be a good number
  int block_size = 128;

  int grid_size = num_elements / block_size;

  // launch kernel
  shift_cypher<<<grid_size,block_size>>>(device_input_array, device_output_array, shift_amount, alphabet_max, num_elements);

  // download and inspect the result on the host:
  cudaMemcpy(host_output_array, device_output_array, num_bytes, cudaMemcpyDeviceToHost);

  // generate reference output
  host_shift_cypher(host_input_array, host_output_checker_array, shift_amount, alphabet_max, num_elements);
  
  // check CUDA output versus reference output
  int error = 0;
  for(int i=0;i<num_elements;i++)
  {
	if(host_output_array[i] != host_output_checker_array[i]) 
	{ 
		error = 1;
	}
	
  }
  
  if(error)
  {
	printf("Output of CUDA version and normal version didn't match! \n");
  }
  else {
	printf("Worked! CUDA and reference output match. \n");
  }
 
  // deallocate memory
  free(host_input_array);
  free(host_output_array);
  free(host_output_checker_array);
  cudaFree(device_input_array);
  cudaFree(device_output_array);
}

