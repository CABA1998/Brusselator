CXX = g++-14
CXXFLAGS = -O3 -fopenmp -std=c++17
SRC = src/main.cpp src/io.cpp src/brusselator.cpp
INCLUDE = -Iinclude
OUT = program

compile:
	$(CXX) $(CXXFLAGS) $(SRC) $(INCLUDE) -o $(OUT)

run: compile
	./$(OUT)

clean:
	rm -f $(OUT) $(CUDA_OUT)

# --- CUDA version (see cuda/brusselator.cu) ---
NVCC = nvcc
NVCCFLAGS = -O3 -std=c++17
CUDA_OUT = program_cuda

cuda-compile:
	$(NVCC) $(NVCCFLAGS) cuda/brusselator.cu src/io.cpp $(INCLUDE) -o $(CUDA_OUT)

cuda-run: cuda-compile
	./$(CUDA_OUT)

cuda-verify: cuda-compile
	./$(CUDA_OUT) --verify 100