#!/bin/bash
#BSUB -q cpu-compute-long
#BSUB -n 140
#BSUB -R '(!gpu)'
#BSUB -R "rusage[mem=64]"
#BSUB -o /storage1/jonsilva/Active/m.max/Projects/fluxcurv/logs-3/bsub/output_%J.log
#BSUB -e /storage1/jonsilva/Active/m.max/Projects/fluxcurv/logs-3/bsub/error_%J.log

cd /storage1/jonsilva/Active/m.max/projects/fluxcurv

JULIA_DEPOT_PATH="/home/research/m.max/.julia" JULIA_WORKER_TIMEOUT='1700' /storage1/jonsilva/Active/m.max/julia-1.10.2/bin/julia --project="/storage1/jonsilva/Active/m.max/Projects/fluxcurv" --procs 140 src/main.jl 7