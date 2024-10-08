using Pkg
Pkg.activate(".")
using Distributed

@everywhere using Graphs
@everywhere using Karnak, Colors, UnPack
@everywhere using Optim, Distributed, Dagger, LinearAlgebra
@everywhere using YAML, DelimitedFiles, Statistics
@everywhere using ExponentialUtilities
@everywhere using Logging, Printf, Dates, LoggingExtras
@everywhere include("traintils/cascade.jl")
@everywhere include("traintils/loss.jl")

idd = Dates.format(now(), "mmddss")
@everywhere modelID = $idd
p = joinpath("logs-6/", @sprintf("%s-log_%s.log", (modelID), Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")))
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


@everywhere THREADS = trunc(Int, nprocs()/2)
with_logger(logg) do 
    @info "Packages and prereqs loaded, running with allocated threads = $(THREADS)."
end

@everywhere local pd
n = 0 #make sure to also change in loss.jl and (for later) graph.jl and protos.jl
if length(ARGS) > 0
    n = parse(Int, ARGS[1])
else
    n = 7
end

@everywhere n= $n


@everywhere n̅ = 1
@everywhere global additionals = [n, n̅]
@everywhere out = "models/Jul28/$(modelID)_n=$n.model"
global ct

# #GRAPH
# s=1.5
# g = complete_graph(n)
# @drawsvg begin
# background("grey10")
# sethue("pink")
# drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
# end 500*s 400*s

@everywhere pd = rand(3*(n*(n-1)) + 3) #add the m,n,h
    
# @everywhere (n == 7) ? (pd = vec(readdlm("models/good7State.txt")); println("pd absorbed from good7state")) : (pd = vec(readdlm("out8.txt")); println("pd absorbed from out8"))


global ct = 0
@everywhere include("plot/protos.jl")