#!/bin/bash
export JULIA_NUM_THREADS=$(nproc)
/storage1/jonsilva/Active/m.max/julia-1.10.2/bin/julia src/main.jl
