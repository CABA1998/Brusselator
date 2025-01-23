
/**
 * @file io.h
 * @brief Declaration of input/output helper functions for matrices.
 * @author carlosb
 */

#ifndef IO_H
#define IO_H

#include <vector>
#include <string>

void readMatrix(const std::string& filename, std::vector<std::vector<double>>& data);
void writeMatrix(const std::string& filename, const std::vector<std::vector<double>>& data);

#endif
