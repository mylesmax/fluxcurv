using Pkg
Pkg.activate(".")

using Graphs
using Karnak, Colors, UnPack
using Optim, Distributed, Dagger, LinearAlgebra
using YAML, DelimitedFiles, Statistics
using ExponentialUtilities
using Logging, Printf, Dates, LoggingExtras
using Flux
include("traintils/cascade.jl")
# include("traintils/pade.jl")
include("traintils/loss.jl")

modelID = Dates.format(now(), "mmddss")

p = joinpath("logs-2/", @sprintf("%s-log_%s.log", (modelID), Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")))
formatlogger = FormatLogger(p, append=true) do io, args
    println(io, args._module, " | $(Dates.format(now(), "eud @ I:M:Sp CDT")) | ", "[", args.level, "] ", args.message)
end
consolelogger = FormatLogger(stdout) do io, args
    println(io, "[", args.level, "] ", args.message)
end
logg = TeeLogger(formatlogger, consolelogger)
with_logger(logg) do 
    @info "This log can be found at $p."
    @info "nprocs = $(nprocs())"
end


THREADS = trunc(Int, nprocs()/2)
with_logger(logg) do 
    @info "Packages and prereqs loaded, running with allocated threads = $(THREADS)."
end

local pd
n = 0 #make sure to also change in loss.jl and (for later) graph.jl and protos.jl
if length(ARGS) > 0
    n = parse(Int, ARGS[1])
else
    n = 7
end

with_logger(logg) do
    @info "n set to $n"
end
n̅ = 1
global additionals = [n, n̅]
out = "models/Jun4/$(modelID)_n=$n.model"
global ct

# #GRAPH
# s=1.5
# g = complete_graph(n)
# @drawsvg begin
# background("grey10")
# sethue("pink")
# drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
# end 500*s 400*s

pd = rand(3*(n*(n-1)))
    
# (n == 7) ? (pd = vec(readdlm("models/good7State.txt")); println("pd absorbed from good7state")) : (pd = vec(readdlm("out8.txt")); println("pd absorbed from out8"))
writedlm(out, pd)
with_logger(logg) do
    @info "wrote new pd to $out"
end

global ct = 0

model = Chain(
    Dense(length(pd), 500, relu),
    Dense(500, 100, relu),
    Dense(100, 10),
    Dense(100, length(pd)),
    softmax
)
ps = Flux.params(model)

optimizer = ADAM(0.01)
epochs = 1:2

for ep ∈ epochs
    Flux.train!(x->consolidatedLoss(x,additionals), ps, [pd], optimizer)
end



# """
# PLOTTING?
# """

# include("plot/plotting.jl")

# #Graph plotting
# include("plot/graphplotting.jl")