# Building and Running the PLUTO Benchmark

## 1. Install PLUTO

Follow the official gPLUTO installation instructions:

https://gitlab.com/PLUTO-code/gPLUTO

Set the `PLUTO_DIR` environment variable to point to your PLUTO installation:

```bash
export PLUTO_DIR=/path/to/gPLUTO
```

---

## 2. Configure the Orszag–Tang Test Case

Navigate to the Orszag–Tang test problem:

```bash
cd /home/jlynn/gPLUTO-x86/Test_Problems/MHD/Orszag_Tang
```

Use the provided benchmark configuration:

```bash
cp definitions_01.hpp definitions.hpp
cp pluto_01.ini pluto.ini
```

---

## 3. Update the Makefile

Modify the `CFLAGS` in the `makefile` to include the following optimization flags:

```make
# Optimized for Arm Neoverse V2

CFLAGS += -c -O3 -std=c++17                    \
          -march=armv9-a                        \
          -mtune=neoverse-v2                    \
          -msve-vector-bits=128                 \
          -moutline-atomics                     \
          -ftree-vectorize                      \
          -fopt-info-vec-optimized              \
          -funroll-loops                        \
          -ffast-math                           \
          -Wall
```

---

## 4. Build

Compile the code using:

```bash
make -j
```

---

## 5. Run the Benchmark

Submit the benchmark job to Slurm:

```bash
sbatch bench_mpiscale.sh
```

This sample script launches the MPI scaling experiment using the configured Orszag–Tang test case.
