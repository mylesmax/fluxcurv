using Pkg
Pkg.activate(".")

@everywhere using Graphs
@everywhere using Karnak, Colors, UnPack
@everywhere using Optimisers, Distributed, Dagger, LinearAlgebra
@everywhere using YAML, DelimitedFiles, Statistics
@everywhere using ExponentialUtilities
@everywhere using Logging, Printf, Dates, LoggingExtras, StochasticAD
@everywhere include("src/traintils/cascade.jl")
@everywhere include("src/traintils/loss.jl")


idd = Dates.format(now(), "mmddss")
@everywhere modelID = $idd
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

with_logger(logg) do
    @info "n set to $n"
end
@everywhere n̅ = 1
@everywhere global additionals = [n, n̅]
@everywhere out = "models/Jun4/$(modelID)_n=$n.model"
global ct

# #GRAPH
# s=1.5
# g = complete_graph(n)
# @drawsvg begin
# background("grey10")
# sethue("pink")
# drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
# end 500*s 400*s

@everywhere pd = rand(3*(n*(n-1)))
    
# @everywhere (n == 7) ? (pd = vec(readdlm("models/good7State.txt")); println("pd absorbed from good7state")) : (pd = vec(readdlm("out8.txt")); println("pd absorbed from out8"))
writedlm(out, pd)
with_logger(logg) do
    @info "wrote new pd to $out"
end

global ct = 0

# csl(p) = consolidatedLoss(p, additionals)
include("src/traintils/loss.jl")
m = StochasticModel(x -> consolidatedLoss(StochasticAD.value.(x), additionals), pd)
iterations = 5
trace = []

s = Optimisers.setup(Optimisers.Adam(eta=0.1), m)
for i in 1:iterations
    j = Optim.optimize(x -> consolidatedLoss(x, additionals), m.p, ParticleSwarm(n_particles=11), Optim.Options(iterations=10))
    m = StochasticModel(x -> consolidatedLoss(x, additionals), j.minimizer)
    Optimisers.update!(s, m, stochastic_gradient(m))
    println("[$i] $(consolidatedLoss(m.p, additionals))")
end
p_opt = m.p # Our optimized value of p


while true
    local pd = vec(readdlm(out))
    local curloss = consolidatedLoss(pd, additionals)

    # with_logger(logg) do
    #     global ct
    #     @info "[$ct] instantiated with $(curloss)"
    # end

    t1 = time()

    tasks = [Distributed.@spawn optimizationCascade(consolidatedLoss, pd, additionals) for _ in 1:THREADS]
    results = map(Distributed.fetch, tasks)
    indecks = argmin([Optim.minimum(results[i]) for i in 1:length(results)])
    
    local pd = Optim.minimizer(results[indecks])
    best = Optim.minimum(results[indecks])

    with_logger(logg) do 
        global ct
        @info "[$ct] loss = $best. took $(time()-t1) sec. $(THREADS) threads."
    end

    writedlm(out, pd)

    global ct += 1
end

# """
# PLOTTING?
# """

# include("plot/plotting.jl")

# #Graph plotting
# include("plot/graphplotting.jl")