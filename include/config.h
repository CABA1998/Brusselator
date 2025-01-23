
/**
 * @file config.h
 * @brief Declaration of the system and model variables.
 * @author carlosb
 */

#ifndef CONFIG_H
#define CONFIG_H

// Brusselator model parameters
const double A = 1.0;
const double B = 3.0;
const double Du = 5e-5;
const double Dv = 5e-6;

// System parameters
const int N = 1024;
const int M = 1024;
const double dt = 0.0025;
const double dx = 1.0 / N;
const double dy = 1.0 / M;
const double Tmax = 1000.0;

// Number of threads for parallel execution
const int num_threads = 16;

#endif
