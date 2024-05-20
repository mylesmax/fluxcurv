using Pkg
Pkg.activate(".")

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
            #TODO: think about this again, since exp() kinda captures the movement of the channel in response to a good enough voltage pulse. but there's friction between ion channel subunits, so there's some sort of saturation in rate...

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

    global params = vec(readdlm("out.txt"))
    @show loss(params)
    writedlm("newest.txt", loss(params))
end


# try
    global params = vec(readdlm("out.txt"))
    count = 0;
    while true
        global params

        res = bboptimize(
                loss, params;
                # NThreads = Threads.nthreads()-1,
                NumDimensions=length(params),
                MaxTime = 75,
                SearchRange = (-17, 17),
                TraceMode = :silent,
                PopulationSize = 5000,
                # NThreads = Threads.nthreads()-1,
                Method = :probabilistic_descent,
                # NThreads = Threads.nthreads()-1,
                # NThreads = Threads.nthreads()-1,
                # NThreads = Threads.nthreads()-1,
                lambda = 100,
                # Method = :probabilistic_descent,
                
                # Workers = workers()
        )
        global params = best_candidate(res)
        setParams!(params)
        count += 1;
        println("[$count] cycle over, best fitness $(best_fitness(res))")
    end


# finally

    global params = best_candidate(res)
    setParams!(params)

    optimal_fitness = best_fitness(res)

    writedlm("out.txt", params)
    writedlm("newest.txt", optimal_fitness)
# end
# end

# for i ∈ 1:n
#     for j ∈ 1:n
#         i != j ? (@show i, j, r(i,j)) : nothing
#     end
# end


"""
PLOTTING?
"""

include("plot/plotting.jl")

#Graph plotting
include("plot/graphplotting.jl")