using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Graphs, Karnak, Colors, BlackBoxOptim, Distributed
using Flux, FastExpm, YAML, DelimitedFiles
import Flux.Losses: mse

begin

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

global params = getParams()

function Q(V::T) where T <: Number
    global rates, args₁, args₂
    
    function r(x::Int64, y::Int64)
        e = Edge(x,y)
        α, β = rates[e]

        rate = exp(α + (β * tanh((V + args₁)/args₂)))

        rate > 0.2 ? (return rate) : (return 0)
        #added pruning?
        # return 
        # #TODO: add pruning if this is below a threshold?
    end
    q = zeros(n,n)

    for i ∈ 1:n
        for j ∈ 1:n
            i==j ? (q[i,j] = -sum(r(j, i) for j in 1:n if j != i)) : (q[i,j] = r(i,j))
        end
    end

    return q
end


end

try
    res = bboptimize(
                loss;
                NumDimensions=length(params),
                MaxSteps = 50000,
                SearchRange = (-17, 17),
                TraceMode = :compact,
                PopulationSize = 5000,
                NThreads = Threads.nthreads()-1,
                Method = :xnes,
                # Method = :probabilistic_descent,
                
                # Workers = workers(),
                lambda = 100
    )
catch
    res = bboptimize(
            loss;
            NumDimensions=length(params),
            MaxSteps = 50000,
            SearchRange = (-17, 17),
            TraceMode = :compact,
            PopulationSize = 5000,
            NThreads = Threads.nthreads()-5,
            Method = :xnes,
            # Method = :probabilistic_descent,
            
            # Workers = workers(),
            lambda = 100
    )
end



global params = best_candidate(res)
setParams!(params)

optimal_fitness = best_fitness(res)

writedlm("out.txt", params)