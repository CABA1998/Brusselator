/**
 * @file brusselator.cu
 * @brief CUDA version of the Brusselator simulation (learning-oriented).
 * @author carlosb
 *
 * This file is self-contained on purpose so you can read it top to bottom.
 * It reuses the same parameters (include/config.h) and I/O helpers
 * (src/io.cpp) as the OpenMP version.
 *
 * ---------------------------------------------------------------------------
 * HOW THE CPU VERSION MAPS TO CUDA
 * ---------------------------------------------------------------------------
 *   OpenMP                                  CUDA
 *   ------                                  ----
 *   #pragma omp parallel for collapse(2)    a "kernel": one GPU thread per
 *   over (i, j)                             grid node (i, j)
 *
 *   std::vector<std::vector<double>>        one flat array of n*m doubles in
 *                                           GPU memory, index = i*m + j
 *
 *   u.swap(aux_u)                           swap two device pointers (free)
 *
 *   16 CPU threads                          ~1 million GPU threads per step,
 *                                           grouped in blocks of 32x8
 *
 * The big rule of GPU performance: keep data ON the GPU. We copy the
 * initial conditions to the GPU once, run all 400 000 time steps there,
 * and copy the result back once at the end.
 * ---------------------------------------------------------------------------
 */

#include "config.h"
#include "io.h"

#include <cuda_runtime.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

// ---------------------------------------------------------------------------
// 1. Error checking
// ---------------------------------------------------------------------------
// Every CUDA API call returns a cudaError_t. Kernel launches do not return
// anything, so we check them with cudaGetLastError(). Always do this while
// learning: without it, errors are silent and you just get garbage results.
#define CUDA_CHECK(call)                                                      \
	do {                                                                      \
		cudaError_t err__ = (call);                                           \
		if (err__ != cudaSuccess) {                                           \
			std::fprintf(stderr, "CUDA error %s at %s:%d\n",                  \
						 cudaGetErrorString(err__), __FILE__, __LINE__);      \
			std::exit(EXIT_FAILURE);                                          \
		}                                                                     \
	} while (0)

// ---------------------------------------------------------------------------
// 2. Model parameters in constant memory
// ---------------------------------------------------------------------------
// __constant__ memory is a small, cached, read-only region. When every
// thread of a warp reads the same address (as here), it is a broadcast and
// costs about as much as a register read.
struct Params {
	double A, B, Du, Dv, dt, inv_dx2, inv_dy2;
};
__constant__ Params P;

// ---------------------------------------------------------------------------
// 3. The kernel: one Forward-Euler step for ONE grid node
// ---------------------------------------------------------------------------
// __global__  = runs on the GPU, launched from the CPU.
// __restrict__ = promise to the compiler that these pointers don't overlap,
//                which lets it use the faster read-only cache.
//
// IMPORTANT (memory coalescing): threadIdx.x varies fastest inside a warp
// (32 threads that execute together). We map it to j, the column index,
// because u[i*m + j] and u[i*m + j+1] are neighbours in memory. That way
// a warp reads 32 consecutive doubles in one memory transaction. If you
// swap i and j below, the code is still correct but several times slower.
// Try it!
__global__ void stepKernel(const double* __restrict__ u,
						   const double* __restrict__ v,
						   double* __restrict__ u_new,
						   double* __restrict__ v_new,
						   int n, int m)
{
	int j = blockIdx.x * blockDim.x + threadIdx.x; // column (fast index)
	int i = blockIdx.y * blockDim.y + threadIdx.y; // row

	// The grid of threads is rounded up to whole blocks, so some threads
	// fall outside the domain. Boundary nodes are also skipped: they keep
	// their Dirichlet value (see main()).
	if (i < 1 || i >= n - 1 || j < 1 || j >= m - 1) return;

	int idx = i * m + j;
	double uc = u[idx];
	double vc = v[idx];

	// 5-point Laplacian. Neighbours up/down are +-m away in the flat array.
	double lap_u = (u[idx + m] - 2.0 * uc + u[idx - m]) * P.inv_dx2 +
				   (u[idx + 1] - 2.0 * uc + u[idx - 1]) * P.inv_dy2;
	double lap_v = (v[idx + m] - 2.0 * vc + v[idx - m]) * P.inv_dx2 +
				   (v[idx + 1] - 2.0 * vc + v[idx - 1]) * P.inv_dy2;

	double uuv = uc * uc * vc;
	u_new[idx] = uc + P.dt * (P.Du * lap_u + P.A - (P.B + 1.0) * uc + uuv);
	v_new[idx] = vc + P.dt * (P.Dv * lap_v + P.B * uc - uuv);
}

// ---------------------------------------------------------------------------
// 4. Plain CPU reference (same math, flat arrays) used by --verify
// ---------------------------------------------------------------------------
static void stepCPU(const std::vector<double>& u, const std::vector<double>& v,
					std::vector<double>& un, std::vector<double>& vn,
					int n, int m)
{
	const double inv_dx2 = 1.0 / (dx * dx), inv_dy2 = 1.0 / (dy * dy);
	for (int i = 1; i < n - 1; ++i) {
		for (int j = 1; j < m - 1; ++j) {
			int idx = i * m + j;
			double uc = u[idx], vc = v[idx];
			double lap_u = (u[idx + m] - 2 * uc + u[idx - m]) * inv_dx2 +
						   (u[idx + 1] - 2 * uc + u[idx - 1]) * inv_dy2;
			double lap_v = (v[idx + m] - 2 * vc + v[idx - m]) * inv_dx2 +
						   (v[idx + 1] - 2 * vc + v[idx - 1]) * inv_dy2;
			double uuv = uc * uc * vc;
			un[idx] = uc + dt * (Du * lap_u + A - (B + 1.0) * uc + uuv);
			vn[idx] = vc + dt * (Dv * lap_v + B * uc - uuv);
		}
	}
}

// Helpers to convert between the 2D vectors used by io.cpp and flat arrays.
static std::vector<double> flatten(const std::vector<std::vector<double>>& a) {
	std::vector<double> f;
	f.reserve(a.size() * a[0].size());
	for (const auto& row : a) f.insert(f.end(), row.begin(), row.end());
	return f;
}
static void unflatten(const std::vector<double>& f, std::vector<std::vector<double>>& a) {
	int m = (int)a[0].size();
	for (size_t i = 0; i < a.size(); ++i)
		std::memcpy(a[i].data(), f.data() + i * m, m * sizeof(double));
}

// ---------------------------------------------------------------------------
// 5. Host program
// ---------------------------------------------------------------------------
int main(int argc, char** argv)
{
	// --verify [steps] : run a few steps on CPU and GPU and compare.
	bool verify = (argc > 1 && std::strcmp(argv[1], "--verify") == 0);
	long long num_steps = verify ? (argc > 2 ? std::atoll(argv[2]) : 100)
								 : (long long)std::llround(Tmax / dt);
	// Note: we count integer steps instead of "while (t < Tmax) t += dt;",
	// because adding 0.0025 400 000 times accumulates rounding error and can
	// give one step more or less than intended.

	const int n = N, m = M;
	const size_t bytes = (size_t)n * m * sizeof(double);

	// --- Print which GPU we're using --------------------------------------
	cudaDeviceProp prop;
	CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
	std::printf("GPU: %s (compute capability %d.%d, %d SMs)\n",
				prop.name, prop.major, prop.minor, prop.multiProcessorCount);

	// --- Load initial conditions on the CPU ("host") ----------------------
	std::vector<std::vector<double>> U(n, std::vector<double>(m)), V = U;
	readMatrix("data/u0.dat", U);
	readMatrix("data/v0.dat", V);
	std::vector<double> h_u = flatten(U), h_v = flatten(V);

	// --- Allocate memory on the GPU ("device") ----------------------------
	double *d_u, *d_v, *d_u_new, *d_v_new;
	CUDA_CHECK(cudaMalloc(&d_u, bytes));
	CUDA_CHECK(cudaMalloc(&d_v, bytes));
	CUDA_CHECK(cudaMalloc(&d_u_new, bytes));
	CUDA_CHECK(cudaMalloc(&d_v_new, bytes));

	// Copy the initial state into BOTH buffers. The kernel never writes the
	// boundary nodes, so this keeps U = U0 on the boundary in both buffers
	// no matter how many times we swap them (Dirichlet condition).
	CUDA_CHECK(cudaMemcpy(d_u,     h_u.data(), bytes, cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_v,     h_v.data(), bytes, cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_u_new, h_u.data(), bytes, cudaMemcpyHostToDevice));
	CUDA_CHECK(cudaMemcpy(d_v_new, h_v.data(), bytes, cudaMemcpyHostToDevice));

	Params p{A, B, Du, Dv, dt, 1.0 / (dx * dx), 1.0 / (dy * dy)};
	CUDA_CHECK(cudaMemcpyToSymbol(P, &p, sizeof(Params)));

	// --- Launch configuration ---------------------------------------------
	// A block of 32x8 = 256 threads: 32 in x so each row of the block is a
	// full warp reading contiguous memory. The grid has enough blocks to
	// cover the whole n x m domain (rounded up).
	dim3 block(32, 8);
	dim3 grid((m + block.x - 1) / block.x, (n + block.y - 1) / block.y);
	std::printf("Grid %d x %d blocks of %d x %d threads, %lld steps\n",
				grid.x, grid.y, block.x, block.y, num_steps);

	// --- Time the simulation with CUDA events -----------------------------
	// Kernel launches are asynchronous: the CPU queues them and moves on.
	// CUDA events measure time on the GPU itself.
	cudaEvent_t start, stop;
	CUDA_CHECK(cudaEventCreate(&start));
	CUDA_CHECK(cudaEventCreate(&stop));
	CUDA_CHECK(cudaEventRecord(start));

	for (long long s = 0; s < num_steps; ++s) {
		stepKernel<<<grid, block>>>(d_u, d_v, d_u_new, d_v_new, n, m);
		// Swap pointers: the new state becomes the current one. Launches on
		// the same stream run in order, so step s+1 waits for step s.
		std::swap(d_u, d_u_new);
		std::swap(d_v, d_v_new);
	}
	CUDA_CHECK(cudaGetLastError());     // catches bad launch configurations
	CUDA_CHECK(cudaEventRecord(stop));
	CUDA_CHECK(cudaEventSynchronize(stop)); // wait for the GPU to finish

	float ms = 0.0f;
	CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));
	std::printf("Execution time: %.3f seconds (%.2f us/step)\n",
				ms / 1000.0, 1000.0 * ms / num_steps);

	// --- Copy the result back to the CPU ----------------------------------
	std::vector<double> r_u(n * (size_t)m), r_v(n * (size_t)m);
	CUDA_CHECK(cudaMemcpy(r_u.data(), d_u, bytes, cudaMemcpyDeviceToHost));
	CUDA_CHECK(cudaMemcpy(r_v.data(), d_v, bytes, cudaMemcpyDeviceToHost));

	if (verify) {
		// Run the same number of steps on the CPU and compare.
		std::vector<double> cu = h_u, cv = h_v, cu2 = h_u, cv2 = h_v;
		for (long long s = 0; s < num_steps; ++s) {
			stepCPU(cu, cv, cu2, cv2, n, m);
			cu.swap(cu2);
			cv.swap(cv2);
		}
		double max_err = 0.0;
		for (size_t k = 0; k < cu.size(); ++k) {
			max_err = std::fmax(max_err, std::fabs(cu[k] - r_u[k]));
			max_err = std::fmax(max_err, std::fabs(cv[k] - r_v[k]));
		}
		// Small differences (~1e-12) are normal: the GPU may fuse a*b+c into
		// one FMA instruction, which rounds differently from the CPU.
		std::printf("Max |CPU - GPU| after %lld steps: %.3e\n", num_steps, max_err);
	} else {
		unflatten(r_u, U);
		unflatten(r_v, V);
		writeMatrix("output/uf_cuda.dat", U);
		writeMatrix("output/vf_cuda.dat", V);
	}

	// --- Clean up ---------------------------------------------------------
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	cudaFree(d_u);
	cudaFree(d_v);
	cudaFree(d_u_new);
	cudaFree(d_v_new);
	return 0;
}
