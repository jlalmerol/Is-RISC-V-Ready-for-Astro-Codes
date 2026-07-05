#!/bin/bash

#SBATCH --job-name=ipic3d
#SBATCH --nodes=1
#SBATCH --ntasks=__MPI__
#SBATCH --cpus-per-task=__OMP__
#SBATCH --gres=gpu:1
#SBATCH --exclusive
#SBATCH --time=12:00:00
#SBATCH --partition=a-gpu-h100
#SBATCH --error=err_%j.txt
#SBATCH --output=out_%j.txt

set -euo pipefail

set +u
source /home/jlynn/newlibs/setup_newlibs.sh
set -u

export OMP_NUM_THREADS=__OMP__
export NRUNS=__NRUNS__

echo "======================================"
echo "SLURM_NTASKS      = ${SLURM_NTASKS}"
echo "SLURM_CPUS_PER_TASK = ${SLURM_CPUS_PER_TASK}"
echo "======================================"

./run_ipic3d_grid_sweep_ss.sh