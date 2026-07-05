#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(pwd)"

OMP_VALUES=(1)
MPI_VALUES=(64 16 4 1)
MAX_CORES=64
NRUNS=10
NCYCLES=5

for OMP in "${OMP_VALUES[@]}"; do
    for MPI in "${MPI_VALUES[@]}"; do

        TOTAL_CORES=$((OMP * MPI))
        if (( TOTAL_CORES > MAX_CORES )); then
            echo "Skipping MPI=${MPI}, OMP=${OMP} (total cores = ${TOTAL_CORES} > ${MAX_CORES})"
            continue
        fi

        # --- MPI → domain decomposition ---
        case "${MPI}" in
            1)  XLEN=1; YLEN=1 ;;
            4)  XLEN=2; YLEN=2 ;;
            16) XLEN=4; YLEN=4 ;;
            64) XLEN=8; YLEN=8 ;;
            *)
                echo "Unsupported MPI value: ${MPI}"
                exit 1
                ;;
        esac

        echo "======================================"
        echo "Launching MPI=${MPI}, OMP=${OMP}"
        echo "Domain decomposition: ${XLEN} x ${YLEN}"
        echo "======================================"

        RUN_DIR="${BASE_DIR}/omp_${OMP}/mpi_${MPI}"
        mkdir -p "${RUN_DIR}"

        # Copy inputs and sweep script
        cp "${BASE_DIR}/benchmark_ss.inp" "${RUN_DIR}/"
        # cp "${BASE_DIR}/run_ipic3d_grid_sweep_ss.sh" "${RUN_DIR}/"
        cp "${BASE_DIR}/./run_ipic3d_grid_sweep_ss.sh" "${RUN_DIR}/"

        # Patch benchmark_ss.inp
        sed -i \
            -e "s/^XLEN *= *.*/XLEN = ${XLEN}/" \
            -e "s/^YLEN *= *.*/YLEN = ${YLEN}/" \
            -e "s/^ncycles *= *.*/ncycles = ${NCYCLES}/" \
            "${RUN_DIR}/benchmark_ss.inp"

        # Generate SLURM job script
        sed \
            -e "s/__OMP__/${OMP}/g" \
            -e "s/__MPI__/${MPI}/g" \
            -e "s/__NRUNS__/${NRUNS}/g" \
            "${BASE_DIR}/job_template.slurm" \
            > "${RUN_DIR}/job_mpi${MPI}_omp${OMP}.slurm"

        chmod +x "${RUN_DIR}/job_mpi${MPI}_omp${OMP}.slurm"

        JOB_ID=$(sbatch --parsable --chdir="${RUN_DIR}" "${RUN_DIR}/job_mpi${MPI}_omp${OMP}.slurm")
        echo "Submitted job ${JOB_ID}"

        while squeue -j "${JOB_ID}" &>/dev/null; do
            sleep 10
        done
        echo "Job ${JOB_ID} completed"
        echo
    done
done
