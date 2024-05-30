#!/bin/bash
#BSUB -q normal
#BSUB -n 150
#BSUB -R '(!gpu)'
#BSUB -R "rusage[mem=96]"
#BSUB -o /storage1/jonsilva/Active/m.max/Projects/fluxcurv/logs-2/bsub/output_%J.log
#BSUB -e /storage1/jonsilva/Active/m.max/Projects/fluxcurv/logs-2/bsub/error_%J.log

cd /storage1/jonsilva/Active/m.max/projects/fluxcurv

JULIA_DEPOT_PATH="/home/research/m.max/.julia" /storage1/jonsilva/Active/m.max/julia-1.10.2/bin/julia --project="/storage1/jonsilva/Active/m.max/Projects/fluxcurv" -t 150 src/mainP.jl 7 WOA