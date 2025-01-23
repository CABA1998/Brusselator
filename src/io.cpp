
/**
 * @file io.cpp
 * @brief Implementation of input/output helper functions for reading and writing matrices.
 * @author carlosb
 */

#include "io.h"
#include <fstream>
#include <iostream>

void readMatrix(const std::string& filename, std::vector<std::vector<double>>& data) {
	std::ifstream file(filename);
	if (!file.is_open()) {
		std::cerr << "Error opening file: " << filename << std::endl;
		return;
	}
	int rows = data.size();
	int cols = data[0].size();
	for (int i = 0; i < rows; ++i) {
		for (int j = 0; j < cols; ++j) {
			if (!(file >> data[i][j])) {
				std::cerr << "Error reading data from file: " << filename << std::endl;
				return;
			}
		}
	}
	file.close();
}

void writeMatrix(const std::string& filename, const std::vector<std::vector<double>>& data) {
	std::ofstream file(filename);
	if (!file.is_open()) {
		std::cerr << "Error opening file for writing: " << filename << std::endl;
		return;
	}
	for (const auto& row : data) {
		for (size_t j = 0; j < row.size(); ++j) {
			file << row[j];
			if (j < row.size() - 1) {
				file << " ";
			}
		}
		file << "\n";
	}
	file.close();
}
