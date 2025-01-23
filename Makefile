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
	rm -f $(OUT)