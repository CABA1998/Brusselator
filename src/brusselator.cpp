
/**
 * @file brusselator.cpp
 * @brief Implementation of the Brusselator class for simulating the Brusselator model.
 * @author carlosb
 */

#include "brusselator.h"
#include "config.h"
#include <omp.h>

/**
 * @brief Constructor for the Brusselator class.
 * @param n Number of grid points in the x-direction.
 * @param m Number of grid points in the y-direction.
 */
Brusselator::Brusselator(int n, int m) : n(n), m(m), dx(1.0 / n), dy(1.0 / m) {
	u = std::vector<std::vector<double>>(n, std::vector<double>(m, 0.0));
	v = std::vector<std::vector<double>>(n, std::vector<double>(m, 0.0));
	aux_u = u;
	aux_v = v;
}

void Brusselator::computeLaplacians(int i, int j, double& lap_u, double& lap_v) {
	lap_u = (u[i+1][j] - 2*u[i][j] + u[i-1][j]) / (dx*dx) +
			(u[i][j+1] - 2*u[i][j] + u[i][j-1]) / (dy*dy);
	lap_v = (v[i+1][j] - 2*v[i][j] + v[i-1][j]) / (dx*dx) +
			(v[i][j+1] - 2*v[i][j] + v[i][j-1]) / (dy*dy);
}


/**
 * @brief Perform a time step using Forward Euler method.
 * @param dt Time step size.
 */
void Brusselator::timeStepForwardEuler(double dt) {
	#pragma omp parallel for collapse(2) num_threads(num_threads)
	for (int i = 1; i < n - 1; ++i) {
		for (int j = 1; j < m - 1; ++j) {
			double lap_u, lap_v;
			computeLaplacians(i, j, lap_u, lap_v);
			aux_u[i][j] = u[i][j] + Du * lap_u * dt + dt * (A - (B + 1) * u[i][j] + u[i][j] * u[i][j] * v[i][j]);
			aux_v[i][j] = v[i][j] + Dv * lap_v * dt + dt * (B * u[i][j] - u[i][j] * u[i][j] * v[i][j]);
		}
	}
	u.swap(aux_u);
	v.swap(aux_v);
}


std::vector<std::vector<double>>& Brusselator::getU() {
	return u;
}

std::vector<std::vector<double>>& Brusselator::getV() {
	return v;
}
