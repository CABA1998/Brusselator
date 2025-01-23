
/**
 * @file main.cpp
 * @brief Main program to simulate the Brusselator model and handle input/output operations.
 * @author carlosb
 */

#include "brusselator.h"
#include "io.h"
#include "config.h"
#include <chrono>
#include <iostream>

int main() {
	Brusselator brusselator(N, M); // Create Brusselator object

	// Load initial conditions
	readMatrix("data/u0.dat", brusselator.getU());
	readMatrix("data/v0.dat", brusselator.getV());

	auto start = std::chrono::steady_clock::now();

	double t = 0.0;
	while (t < Tmax) {
		brusselator.timeStepForwardEuler(dt);
		t += dt;
	}

	auto end = std::chrono::steady_clock::now();
	std::cout << "Execution time: " 
			<< std::chrono::duration<double>(end - start).count() 
			<< " seconds" << std::endl;

	// Save final results
	writeMatrix("output/uf.dat", brusselator.getU());
	writeMatrix("output/vf.dat", brusselator.getV());

	return 0;
}
