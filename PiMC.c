/**
 * This program implements a serial code via a function call that calculates Pi with the Monte Carlo Algorithm
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

double toComputePiUsingMonteCarlo(long long int iterations) {
    // We need to make i be able to hold super large number, so we set it to long long int
    long long int i, qualifiedPoint = 0;
    double xCoordinate, yCoordinate;

    // Seed the random number generator
    srand(time(NULL));
    for (i = 0; i < iterations; i++) {
        // Suppose we have a square whoes length is 2 and a circle inscribed with it whose radius is 1
        // generates two random double values between 0 and 1, which represent the coordiantes of a randomly generated point
        xCoordinate = (double)rand() / RAND_MAX;
        yCoordinate = (double)rand() / RAND_MAX;

        // Calculates the distance between the point and the origin using the Pythagorean theorem, which is that for any point (x,y) the distance from the origin is sqrt(x^2 + y^2).
        if ((xCoordinate * xCoordinate + yCoordinate * yCoordinate) <= 1) {
            qualifiedPoint++;
        }
    }

    return 4.0 * qualifiedPoint / iterations;
}

int main(int argc, char *argv[]) {
    long long int iterations;

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

    // Compute π and print result
    double pi;
    clock_t start = clock();
    pi = toComputePiUsingMonteCarlo(iterations);
    clock_t end = clock();
    printf("Serial code implementation:\n");
    printf("Pi: %f\n", pi);
    printf("Time costed: %f seconds\n", (double)(end - start) / CLOCKS_PER_SEC);

    return 0;
}
