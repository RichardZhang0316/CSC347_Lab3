all: PiMC.cu
	nvcc -o PiMC PiMC.cu
clean:
	rm -f PiMC