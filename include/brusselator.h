
/**
 * @file brusselator.h
 * @brief Declaration of the Brusselator class for simulating the Brusselator model.
 * @author carlosb
 */

#ifndef BRUSSELATOR_H
#define BRUSSELATOR_H

#include <vector>

class Brusselator {
public:
	Brusselator(int n, int m);
	void timeStepForwardEuler(double dt);

	std::vector<std::vector<double>>& getU();
	std::vector<std::vector<double>>& getV();

private:
	int n, m;
	double dx, dy;
	std::vector<std::vector<double>> u, v, aux_u, aux_v;
	void computeLaplacians(int i, int j, double& lap_u, double& lap_v);
};

#endif
