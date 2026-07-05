#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/home/jlynn/iPIC3D-KTH"
EXEC="${BASE_DIR}/build_x86_gcc/iPIC3D"

OUTPUT_ROOT="$(pwd)"
DEFAULT_INP="${OUTPUT_ROOT}/benchmark_ss.inp"

N_RUNS=10
GRID_SIZES=(256)
PPC=40

MPI_TASKS="${SLURM_NTASKS:?SLURM_NTASKS not set}"
OMP_THREADS="${OMP_NUM_THREADS:?OMP_NUM_THREADS not set}"

compute_topology() {
  local total=$1
  local xlen=1
  for ((f=1; f*f<=total; f++)); do
    if (( total % f == 0 )); then
      xlen=$f
    fi
  done
  echo "$xlen $((total / xlen))"
}

read XLEN YLEN <<< "$(compute_topology "${MPI_TASKS}")"
ZLEN=1

echo "======================================"
echo "Running iPIC3D grid sweep"
echo "OUTPUT_ROOT  = ${OUTPUT_ROOT}"
echo "MPI ranks    = ${MPI_TASKS}  (XLEN=${XLEN} YLEN=${YLEN} ZLEN=${ZLEN})"
echo "OMP threads  = ${OMP_THREADS}"
echo "Total cores  = $((MPI_TASKS * OMP_THREADS))"
echo "PPC          = ${PPC}"
echo "======================================"

for GRID in "${GRID_SIZES[@]}"; do
  if (( GRID % XLEN != 0 )) || (( GRID % YLEN != 0 )); then
    echo "ERROR: grid ${GRID} is not divisible by XLEN=${XLEN} or YLEN=${YLEN}" >&2
    exit 1
  fi
done
echo

declare -a CONFIG_LABELS=(
  "unsorted_AoS"
  "unsorted_SoA"
  "sorted_AoS"
  "sorted_SoA"
)
declare -a CONFIG_VECTORIZE=( "0"   "0"   "1"   "1"  )
declare -a CONFIG_MOMENTS=(   "AoS" "SoA" "AoS" "SoA" )
declare -a CONFIG_MOVER=(     "AoS" "SoA" "AoS" "SoA" )

N_CONFIGS=${#CONFIG_LABELS[@]}

for GRID in "${GRID_SIZES[@]}"; do
  for ((c=0; c<N_CONFIGS; c++)); do
    mkdir -p "${OUTPUT_ROOT}/grid_${GRID}/${CONFIG_LABELS[$c]}"
  done
done

for ((i=0; i<N_RUNS; i++)); do
  for GRID in "${GRID_SIZES[@]}"; do
    for ((c=0; c<N_CONFIGS; c++)); do

      LABEL="${CONFIG_LABELS[$c]}"
      [[ "${LABEL}" == "sorted_SoA" ]] && continue   # <-- skip sorted_SoA

      VM="${CONFIG_VECTORIZE[$c]}"
      MT="${CONFIG_MOMENTS[$c]}"
      MOV="${CONFIG_MOVER[$c]}"

      RUN_SUBDIR="${OUTPUT_ROOT}/grid_${GRID}/${LABEL}/run_${i}"
      INP_FILE="benchmark_grid_${GRID}.inp"
      OUT_FILE="output-${i}.txt"

      mkdir -p "${RUN_SUBDIR}"
      cp "${DEFAULT_INP}" "${RUN_SUBDIR}/${INP_FILE}"

      sed -i \
      -e "s/^nxc *=.*/nxc = ${GRID}/" \
      -e "s/^nyc *=.*/nyc = ${GRID}/" \
      -e "s/^XLEN *=.*/XLEN = ${XLEN}/" \
      -e "s/^YLEN *=.*/YLEN = ${YLEN}/" \
      -e "s/^ZLEN *=.*/ZLEN = ${ZLEN}/" \
      -e "s/^npcelx *=.*/npcelx = ${PPC} ${PPC} ${PPC} ${PPC}/" \
      -e "s/^npcely *=.*/npcely = ${PPC} ${PPC} ${PPC} ${PPC}/" \
      -e "s/^WriteMethod *=.*/WriteMethod = pvtk/" \
      -e "s/^FieldOutputCycle *=.*/FieldOutputCycle = 999999/" \
      -e "s/^ParticlesOutputCycle *=.*/ParticlesOutputCycle = 999999/" \
      -e "s/^DiagnosticsOutputCycle *=.*/DiagnosticsOutputCycle = 999999/" \
      -e "s/^RestartOutputCycle *=.*/RestartOutputCycle = 999999/" \
      -e "s/^FieldOutputCycle *=.*/FieldOutputCycle = 100/" \
      -e "s/^ParticlesOutputCycle *=.*/ParticlesOutputCycle = 100/" \
      -e "s/^DiagnosticsOutputCycle *=.*/DiagnosticsOutputCycle = 100/" \
      -e "s/^RestartOutputCycle *=.*/RestartOutputCycle = 100/" \
      "${RUN_SUBDIR}/${INP_FILE}"

      echo "--- grid=${GRID} config=${LABEL} run=${i} ---"
      echo "    XLEN=${XLEN} YLEN=${YLEN} ZLEN=${ZLEN}"
      echo "    IPIC_VECTORIZE_MOMENTS=${VM}  IPIC_MOMENTS_TYPE=${MT}  IPIC_MOVER_TYPE=${MOV}"

      (
        cd "${RUN_SUBDIR}"
        IPIC_VECTORIZE_MOMENTS="${VM}" \
        IPIC_MOMENTS_TYPE="${MT}" \
        IPIC_MOVER_TYPE="${MOV}" \
        mpirun -np "${MPI_TASKS}" "${EXEC}" "${INP_FILE}" > "${OUT_FILE}" 2>&1
      )

    done
  done
done

echo
echo "======================================"
echo "All grid sweeps completed successfully."
echo "Results layout:"
echo "  grid_<N>/<config>/run_<i>/output-<i>.txt"
echo
echo "Configs run:"
for ((c=0; c<N_CONFIGS; c++)); do
  [[ "${CONFIG_LABELS[$c]}" == "sorted_SoA" ]] && continue
  printf "  %-15s  VECTORIZE=%s  MOMENTS_TYPE=%s  MOVER_TYPE=%s\n" \
    "${CONFIG_LABELS[$c]}" \
    "${CONFIG_VECTORIZE[$c]}" \
    "${CONFIG_MOMENTS[$c]}" \
    "${CONFIG_MOVER[$c]}"
done
echo "======================================"