@everywhere using Pkg
@everywhere Pkg.activate(".")

@everywhere using Graphs, Karnak, Colors, BlackBoxOptim, Distributed
@everywhere using Flux, FastExpm, YAML, DelimitedFiles
@everywhere import Flux.Losses: mse

@everywhere begin

global n=7
global n̅ = 1
global rates = Dict{Edge, Tuple{Float64, Float64}}()
global args₁ = 2
global args₂ = -4
global dt = 0.0001
global dataPath = "res/INaHEK/"

include("traintils/param.jl")
include("proto/protoImport.jl")
include("proto/protocols.jl")
include("proto/protocolBlocks.jl")
include("traintils/objective.jl")

s=1.5
g = complete_graph(n)
@drawsvg begin
   background("grey10")
   
   sethue("pink")
   
   drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
end 500*s 400*s

#randomly initialize edge weights
for i in 1:n
    for j in 1:n
        if i != j
            global rates
            rates[Edge(i, j)] = (100*rand(), 100*rand())
            rates[Edge(j, i)] = (100*rand(), 100*rand())
        end
    end
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
    @info "m,n,h activated. n set to $n"
end
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
writedlm(out, pd)
with_logger(logg) do
    @info "wrote new pd to $out"
end

global ct = 0
while true
    local pd = vec(readdlm(out))
    local curloss = consolidatedLoss(pd, additionals)

    # with_logger(logg) do
    #     global ct
    #     @info "[$ct] instantiated with $(curloss)"
    # end

    t1 = time()

try
    global params = vec(readdlm("out.txt"))
    global curbestFitness = vec(readdlm("newest.txt"))[1]
    count = 0;
    while true
        global params = vec(readdlm("out.txt"))
        global curbestFitness = vec(readdlm("newest.txt"))[1]

        res = bboptimize(
                loss, params;
                # NThreads = Threads.nthreads()-1,
                NumDimensions=length(params),
                MaxTime = 70,
                SearchRange = (-17, 17),
                TraceMode = :silent,
                PopulationSize = 5000,
                NThreads = Threads.nthreads()-1,
                Method = :probabilistic_descent,
                # NThreads = Threads.nthreads()-1,
                # NThreads = Threads.nthreads()-1,
                # NThreads = Threads.nthreads()-1,
                lambda = 100,
                # Method = :probabilistic_descent,
                
                Workers = workers()
        )
        @sync begin end
        @sync if best_fitness(res) < curbestFitness
            global params = best_candidate(res)
            global curbestFitness = best_fitness(res)
            setParams!(params)
            println("new best fitness ($(best_fitness(res)))")
            writedlm("out.txt", params)
            writedlm("newest.txt", curbestFitness)
        end
        count += 1;
        @sync println("[$count] cycle over, best fitness $(best_fitness(res))")
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