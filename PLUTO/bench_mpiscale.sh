#!/usr/bin/env bash
#SBATCH --job-name=pluto
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=72
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
#SBATCH --exclusive
#SBATCH --nodelist=ngnode01
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

# ============================================================
#  gPLUTO MPI Strong-Scaling Benchmark  (SG2044, 64-core RISC-V)
#
#  Fixed grid: 256^3
#
#  Why 256^3:
#    - Fits comfortably on NP=1 (~16.4 GB, node has 128 GB usable)
#    - Already confirmed running at NP=64 (~0.19 GB/proc)
#    - 256 divides cleanly by 1,2,4,8,16,32,64
#    - Maximises parallel efficiency signal across the full 1->64 range
#    - Memory model: 0.000981 * local_N^3 + 12.4 MB/proc (fitted from measurements)
#
#  MPI proc counts: 1, 2, 4, 8, 16, 32, 64
#  Decompositions kept cubic as possible.
#
#   NP   DEC       Local domain      Mem/proc    Total
#    1   1x1x1     256^3             ~16.4 GB    ~16.4 GB
#    2   2x1x1     128x256x256       ~8.2  GB    ~16.4 GB
#    4   2x2x1     128x128x256       ~4.1  GB    ~16.4 GB
#    8   2x2x2     128^3             ~2.1  GB    ~16.4 GB
#   16   4x2x2     64x128x128        ~1.0  GB    ~16.4 GB
#   32   4x4x2     64x64x128         ~0.5  GB    ~16.4 GB
#   64   4x4x4     64^3              ~0.19 GB    ~12.5 GB
#
#  Output logs:  pluto_<JOBID>_grid256_np<N>.log
# ============================================================

set -euo pipefail

set +u
source /home/jlynn/newlibs-arm/setup_ompi5.0.6.sh
set -u

MPIRUN="/home/jlynn/newlibs-arm/openmpi-5.0.6/bin/mpirun"

PLUTO_INI="pluto.ini"
PLUTO_LOG="pluto.0.log"
JOB_ID=${SLURM_JOB_ID:-"local"}
GRID=256
OMP=1

# Patch pluto.ini once for the fixed grid size
cp ${PLUTO_INI} ${PLUTO_INI}.bak
sed -i \
    -e "s|^X1-grid.*|X1-grid    0.0    ${GRID}   1.0|" \
    -e "s|^X2-grid.*|X2-grid    0.0    ${GRID}   1.0|" \
    -e "s|^X3-grid.*|X3-grid    0.0    ${GRID}   1.0|" \
    ${PLUTO_INI}

echo "=============================================="
echo "  gPLUTO MPI Strong-Scaling on SG2044 RISC-V"
echo "  Fixed grid: ${GRID}^3"
echo "  Memory estimates (model: 0.000981*local_N^3 + 12.4 MB/proc):"
echo "    NP=1  -> ~16.4 GB total  (single proc, fits 128 GB node)"
echo "    NP=64 -> ~12.5 GB total  (~0.19 GB/proc, confirmed run)"
echo "  Job ID: ${JOB_ID}"
echo "  mpirun: ${MPIRUN}"
echo "=============================================="
echo ""

# -------------------------------------------------------------------
#  MPI configs: (nprocs, dec_x, dec_y, dec_z)
#  Rule: dec_x * dec_y * dec_z == nprocs
#  Local domain = GRID/dec per dimension (256 divides cleanly by all)
#
#  NP   DEC       Local domain      Mem/proc
#   1   1x1x1     256^3             ~16.4 GB
#   2   2x1x1     128x256x256       ~8.2  GB
#   4   2x2x1     128x128x256       ~4.1  GB
#   8   2x2x2     128^3             ~2.1  GB
#  16   4x2x2     64x128x128        ~1.0  GB
#  32   4x4x2     64x64x128         ~0.5  GB
#  64   4x4x4     64^3              ~0.19 GB
# -------------------------------------------------------------------
declare -a NP_LIST=(1    2    4    8    16   32   64)
declare -a DX_LIST=(1    2    2    2    4    4    4)
declare -a DY_LIST=(1    1    2    2    2    4    4)
declare -a DZ_LIST=(1    1    1    2    2    2    4)

NUM_CONFIGS=${#NP_LIST[@]}

for (( i=0; i<NUM_CONFIGS; i++ )); do
    NP=${NP_LIST[$i]}
    DX=${DX_LIST[$i]}
    DY=${DY_LIST[$i]}
    DZ=${DZ_LIST[$i]}

    LX=$(( GRID / DX ))
    LY=$(( GRID / DY ))
    LZ=$(( GRID / DZ ))

    echo "=============================================="
    echo "  NP: ${NP}  |  -dec ${DX} ${DY} ${DZ}"
    echo "  Local domain per proc: ${LX} x ${LY} x ${LZ}"
    echo "=============================================="

    START_TIME=$(date +%s)

    ${MPIRUN} -np ${NP} --map-by core --bind-to core \
        ./pluto -dec ${DX} ${DY} ${DZ} -maxsteps 10 -no-write

    END_TIME=$(date +%s)
    ELAPSED=$(( END_TIME - START_TIME ))

    OUTLOG="pluto_${JOB_ID}_grid${GRID}_np${NP}.log"
    if [ -f "${PLUTO_LOG}" ]; then
        cp "${PLUTO_LOG}" "${OUTLOG}"
        echo "  Log saved to: ${OUTLOG}"
    else
        echo "  WARNING: ${PLUTO_LOG} not found after run!"
    fi

    echo "  Wall time: ${ELAPSED} s"
    echo ""
done

# Restore original pluto.ini
mv ${PLUTO_INI}.bak ${PLUTO_INI}

echo "=============================================="
echo "  MPI scaling sweep complete.  Grid: ${GRID}^3"
echo "  Logs:  pluto_${JOB_ID}_grid${GRID}_np{1,2,4,8,16,32,64}.log"
echo "=============================================="