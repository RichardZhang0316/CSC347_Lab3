/**
 * This program implements a parallel code via a kernel function call that calculates Pi with the Monte Carlo Algorithm
 * and the hierarchical atomics strategy.
 *
 * Users are expected to enter two arguments: the executable file and the argument that corresponds to the number 
 * of “iterations” used to compute pi with the Monte Carlo algorithm
 *
 * @author Richard Zhang {zhank20@wfu.edu}
 * @date Mar.14, 2023
 * @assignment Lab 2
 * @course CSC 347
 **/
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <curand_kernel.h>
#include <math.h>

#define BLOCK_SIZE 1024

// kernel to initialize the random states
__global__ void setup_kernel(curandState *state)
{
	int index = threadIdx.x + blockDim.x*blockIdx.x;
    curand_init(123456789, index, 0, &state[index]);
}

// This function calculates the percentage of the points that falled inside the unit circle which is inscribed within the square
__global__ void computePi_MC_HAS(int n, curandState *state, int *count)
{
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    __shared__ int cache[BLOCK_SIZE];
    cache[threadIdx.x] = 0;
    __syncthreads();

    for (int i = 0; i < n; i++) {
        // Generate random points 
        double xCoordinate = curand_uniform(&state[index]);
        double yCoordinate = curand_uniform(&state[index]);
        if (xCoordinate*xCoordinate + yCoordinate*yCoordinate <= 1.0) {
            cache[threadIdx.x]++;
        }
    }

    // reduction
	int i = blockDim.x/2;
	while(i != 0){
		if(threadIdx.x < i){
			cache[threadIdx.x] += cache[threadIdx.x + i];
		}
		i /= 2;
		__syncthreads();
	}
	// update to our global variable count
	if(threadIdx.x == 0){
		atomicAdd(count, cache[0]);
	}
}

int main(int argc, char *argv[]) {
    int iterations;

    // Determine if there are two arguments on the command line
    if (argc != 2) {
        printf("Command line arguments are not enough: %s \n", argv[0]);
        return 1;
    }

    // Convert the second argument to integer
    iterations = atoll(argv[1]);

    // Determine if the number of iteration entered by users is legitamate
    if (iterations <= 0) {
        printf("Number of iterations should not less than 1\n");
        return 2;
    }

    // Determine the size of grid and block
    int gridSize = (iterations + BLOCK_SIZE - 1) / BLOCK_SIZE;
    int blockSize = BLOCK_SIZE;

    // To generate random numbers on the device
    curandState *devStates;
    cudaMalloc((void**)&devStates, gridSize * blockSize * sizeof(curandState));

    int *count;
    int *devCount;
    count = (int*)malloc(gridSize * blockSize * sizeof(int));
    cudaMalloc((void**)&devCount, gridSize * blockSize * sizeof(int));
    cudaMemset(devCount, 0, sizeof(int));

    // initialize all of the random states on the GPU.
    // This kernel call can also warm up the GPU, so we don't need to call computePi_MC_HAS twice
    setup_kernel<<<gridSize, blockSize>>>(devStates);
    
    cudaEvent_t start, stop; /* Measure the starting time and the ending time to calculate the time spent */
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start); /* Start the timer */
    computePi_MC_HAS<<<gridSize, blockSize>>>(iterations, devStates, devCount);
    cudaEventRecord(stop); /* End the timer */

    cudaDeviceSynchronize();
    cudaMemcpy(count, devCount, sizeof(int), cudaMemcpyDeviceToHost);

    /* Output the π result and the execution time of the kernel function to the terminal */
    float total_time = 0.0;
    cudaEventElapsedTime(&total_time, start, stop);

    double pi = 4.0 * (*count) / (iterations * gridSize * blockSize);
    printf("Pi: %f\n", pi);
    printf("Time costed: %f seconds\n", total_time);

    cudaFree(devStates);
    cudaFree(devCount);
    return 0;
}
