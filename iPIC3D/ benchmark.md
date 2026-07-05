# Building and Running the iPIC3D Benchmark

## 1. Clone the Repository

Clone the modified iPIC3D repository:

```bash
git clone https://github.com/jlalmerol/iPIC3D.git
cd iPIC3D
```

This fork adds support for multiple particle data layouts, including:

* **Structure of Arrays (SoA)**
* **Array of Structures (AoS)**

allowing performance comparisons between the two memory layouts.

---

## 2. Build

Example compilation scripts are provided for different architectures:

* `compile-arm.sh` – builds the benchmark for Arm systems.
* `compile-x86.sh` – builds the benchmark for x86 systems.

Run the appropriate script for your target platform:

```bash
./compile-arm.sh
```

or

```bash
./compile-x86.sh
```

---

## 3. Run the Benchmark

Launcher scripts are located in the `scripts` directory.

To submit the strong-scaling benchmark, run:

```bash
cd scripts
./launcher_ipic3d_ss.sh
```

Modify the launcher script as needed to match your system configuration (e.g., scheduler, MPI launcher, node count, and executable path).
