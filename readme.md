
# Brusselator System Simulation

This project simulates a Brusselator system. 
The system consists of two coupled partial differential equations 
that describe the evolution of two chemical species, $U$ and $V$, 
over time and space.

## Mathematical Model

The Brusselator system is governed by the following equations:

$$
\frac{\partial U}{\partial t} = D_U \nabla^2 U + A + U^2 V - (B + 1) U
$$

$$
\frac{\partial V}{\partial t} = D_V \nabla^2 V + B U - U^2 V
$$

Where:

- $U(t, \bold x)$ and $V(t, \bold x)$ represent the concentrations of the two 
chemical species at time $t$ and position $\bold x$,
- $D_U$ and $D_V$ are the diffusion coefficients of $U$ and $V$, respectively,
- $A$ and $B$ are constants that define the system's behavior.

The system is solved over the domain $\Omega = [0, 1]^2$, where 
$\bold x \in \Omega$ and $t \in [0, T_{\text{max}}]$, with the 
following initial conditions:

$$
U(\bold x, 0) = U_0(\bold x), \quad V(\bold x, 0) = V_0(\bold x)
$$

The system is subject to Dirichlet boundary conditions:

$$
U(\bold x, t) \Big|_{\partial \Omega} = U_0(\bold x) \Big|_{\partial \Omega}, 
    \quad V(\bold x, t) \Big|_{\partial \Omega} = V_0(\bold x) \Big|_{\partial \Omega}
$$

Where $\partial \Omega$ denotes the boundary of the domain $\Omega$.

## Numerical Methods

The system is discretized in space using the finite difference method and 
in time using the Forward Euler method.

## Input Files & Configuration

### Model Parameters

The simulation uses the Brusselator model with the following default parameters:

- $A = 1.0$
- $B = 3.0$
- $D_U = 5 \times 10^{-5}$
- $D_V = 5 \times 10^{-6}$

These parameters govern the reaction-diffusion dynamics and 
can be modified in the **`include/config.h`** file.

### System Parameters

The computational domain and system behavior are defined as follows:

- Grid size: $N = 1024$, $M = 1024$ (number of nodes along the x and y directions)
- Spatial step size: $dx = \frac{1.0}{N}$, $dy = \frac{1.0}{M}$
- Time step: $dt = 0.0025$
- Maximum simulation time: $T_{max} = 1000.0$

These values are also specified in **`include/config.h`**, allowing for customization.

### Input Files

Input files should be in `.dat` format, containing matrix-like data 
that represent the initial conditions for each node in the spatial discretization. 
Ensure the input data corresponds to the defined grid size ($N \times M$).

### Parallelization

The simulation leverages OpenMP for parallelized computations. 
The number of threads for parallel execution is set to:

- **`num_threads = 16`**

This value can be adjusted in **`include/config.h`** to match the desired 
level of parallelism based on your hardware capabilities.


## Plot results

To visualize the simulation results, a Python script is provided.
**`plot_results.py`**

## Installation

### Requirements

- g++-14 or later
- OpenMP (for parallelization)

#### Building the project

To build the project, navigate to the project directory and 
run the following command:

```bash
make compile
```

#### Running the simulation

To run the simulation, use the following command:

```bash
make run
```

#### Cleaning the build

To clean the compiled files, run:

```bash
make clean
```
