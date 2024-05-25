using Pkg
Pkg.activate(".")

using Graphs, Karnak, Colors, Optim, Distributed, Dagger
using YAML, DelimitedFiles,Statistics
using ExponentialUtilities, UnPack
using Logging, Printf, Dates, LoggingExtras
using PSOGPU, CUDA, StaticArrays, Cthulhu
include("../src/proto/protoImport.jl")

#-------------------------#

n::Int = 7
n̅::Int = 1
dataPath = "res/INaHEK/"
protoData = protoImport(dataPath)
out = "out.txt"
newest = "newest.txt"

# mutable struct Addits
#     n::Int
#     n̅::Int
#     dt::Float64
#     dataPath::String
#     protoData::NamedTuple
# end

#-------------------------#

include("clgpu.jl")

#LOGGING
p = joinpath("logs/", @sprintf("log_%s.log", Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")))

formatlogger = FormatLogger(p, append=true) do io, args
    println(io, args._module, " | $(Dates.format(now(), "eud @ I:M:Sp CDT")) | ", "[", args.level, "] ", args.message)
end
consolelogger = FormatLogger(stdout) do io, args
    println(io, "[", args.level, "] ", args.message)
end
logg = TeeLogger(formatlogger, consolelogger)

with_logger(logg) do 
    @info "This log can be found at $p."
    @info "Threads allocated = $(Threads.nthreads())."
end

# additionals = Addits(n, n̅, dt, dataPath, protoData)

# #GRAPH
# s=1.5
# g = complete_graph(n)
# @drawsvg begin
# background("grey10")
# sethue("pink")
# drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
# end 500*s 400*s

params = rand(2*(n*(n-1))+2)
try
    params = vec(readdlm(out))
catch
    writedlm(out, params)

    with_logger(logg) do
        @info "wrote new params to $out"
    end
end

params = vec(readdlm(out))
pd = @SArray Float64[p for p in params]
additionals = @SArray Int[n, n̅]

with_logger(logg) do
    @info "instantiated with $(consolidatedLoss(pd, additionals))"
end

lb = @SArray Float64[p for p in -100*ones(length(params))]
ub = @SArray Float64[p for p in 100*ones(length(params))]

prob = OptimizationProblem(consolidatedLoss, pd, additionals; lb = lb, ub = ub)

sol = solve(prob, ParallelSyncPSOKernel(1000, backend = CUDA.CUDABackend()), maxiters = 1)




try
    sol = solve(prob, ParallelSyncPSOKernel(1000, backend = CUDA.CUDABackend()), maxiters = 1)
catch err
    Cthulhu.code_typed(err; interactive = false)
end

# """
# PLOTTING?
# """

# include("plot/plotting.jl")

# #Graph plotting
# include("plot/graphplotting.jl")




using PSOGPU, StaticArrays, CUDA

lb = @SArray [-1.0f0, -1.0f0, -1.0f0]
ub = @SArray [10.0f0, 10.0f0, 10.0f0]

function rosenbrock(x, p,g)
    g[1]*sum( (x[i + 1].^2 - x[i]^2)^2 + (1 - x[i])^2 for i in 1:(length(x) - 1))^g[2]
end

x0 = @SArray zeros(Float32, 3)
p = @SArray Float32[1.0, 100.0]

prob = OptimizationProblem((x) -> rosenbrock(x,x0,[30 30]), x0, p; lb = lb, ub = ub)

sol = solve(prob,
    ParallelSyncPSOKernel(1000, backend = CUDA.CUDABackend()),
    maxiters = 5000)