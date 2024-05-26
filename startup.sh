#!/bin/bash
#BSUB -q cpu-compute
#BSUB -n 128
#BSUB -R '(!gpu)'
#BSUB -R "rusage[mem=96]"
#BSUB -o /storage1/jonsilva/Active/m.max/Projects/fluxcurv/logs/bsub/output_%J.log
#BSUB -e /storage1/jonsilva/Active/m.max/Projects/fluxcurv/logs/bsub/error_%J.log

cd /storage1/jonsilva/Active/m.max/projects/fluxcurv

/storage1/jonsilva/Active/m.max/julia-1.10.2/bin/julia --project="." -p 1 src/main.jl