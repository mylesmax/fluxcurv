using Pkg
Pkg.activate(".")

using Graphs, Karnak, Colors, BlackBoxOptim, Distributed
using Flux, FastExpm, YAML, DelimitedFiles
import Flux.Losses: mse

begin

    global n=7
    global n̅ = 1
    global rates = Dict{Edge, Tuple{Float64, Float64}}()
    global args₁ = 0.1
    global args₂ = 1
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
                rates[Edge(i, j)] = (10*rand(), 10*rand())
                rates[Edge(j, i)] = (10*rand(), 10*rand())
            end
        end
    end

    global params = getParams()

    function Q(V::T) where T <: Number
        global rates, args₁, args₂
        
        function r(x::Int64, y::Int64)
            e = Edge(x,y)
            α, β = rates[e]

            rate = min(β, max(0, ((α * V - args₁)/args₂)))
            # rate = min(max(0,β), max(0, ((α * V - args₁)/args₂)))
            
            return rate
        end
        q = zeros(n,n)

        for i ∈ 1:n
            for j ∈ 1:n
                i==j ? (q[i,j] = -sum(r(j, i) for j in 1:n if j != i)) : (q[i,j] = r(i,j))
            end
        end

        return q
    end

    # global params = vec(readdlm("out.txt"))
    # @show loss(params)
    # writedlm("newest.txt", loss(params))


try
    # global params = vec(readdlm("out.txt"))
    count = 0;
    while true
        global params
        global res = bboptimize(
                loss;
                NumDimensions=length(params),
                MaxSteps=5000,
                # MaxTime = 20,
                SearchRange = (-10, 10),
                TraceMode = :compact,
                PopulationSize = 5000,
                Method = :probabilistic_descent,
                lambda = 100,
        )
        global params = best_candidate(res)
        setParams!(params)
        count += 1;
        println("[$count] cycle over, best fitness $(best_fitness(res))")
    end


finally
    global res
    global params = best_candidate(res)
    setParams!(params)

    optimal_fitness = best_fitness(res)

    writedlm("out.txt", params)
    writedlm("newest.txt", optimal_fitness)
# end
end
end

# for i ∈ 1:n
#     for j ∈ 1:n
#         i != j ? (@show i, j, r(i,j)) : nothing
#     end
# end


# """
# PLOTTING?
# """

# include("plot/plotting.jl")

# #Graph plotting
# include("plot/graphplotting.jl")