using Pkg
Pkg.activate(".")

using Graphs, Karnak, Colors, BlackBoxOptim, Distributed, Dagger
using Flux, FastExpm, YAML, DelimitedFiles
import Flux.Losses: mse

begin

    global n=8
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

            # rate = min(β, max(0, ((α * V - args₁)/args₂)))
            rate = min(abs(β), max(0, ((α * V - args₁)/args₂)))
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

    global params = vec(readdlm("out.txt"))
    @show loss(params)
    writedlm("newest.txt", loss(params))

    # writedlm("newest.txt", loss(params))
    

    global params = vec(readdlm("out.txt"))
    global count = 0;
    global finalParams = params;
    global finalLoss = vec(readdlm("newest.txt"))[1];

    global bestFitness = Inf
    global bestParams = params
    global bestWorker = -1


    while true
        thread_best_fitness = fill(Inf, (Threads.nthreads()-1))
        thread_best_params = Vector{Any}(undef, (Threads.nthreads()-1))

        lck = ReentrantLock()
        Threads.@threads for i ∈ 1:(Threads.nthreads()-1)
            global params
            res = bboptimize(
                    loss, params;
                    NumDimensions=length(params),
                    # MaxSteps=5000,
                    MaxTime = 34,
                    SearchRange = (-17, 17),
                    TraceMode = :silent,
                    PopulationSize = 17000,
                    Method = :probabilistic_descent,
                    lambda = 100,
            )
            Threads.lock(lck) do
                myfitness = loss(best_candidate(res))
                thread_best_fitness[i] = myfitness
                thread_best_params[i] = best_candidate(res)
            end
        end
        
        for i in 1:(Threads.nthreads()-1)
            if thread_best_fitness[i] < bestFitness
                bestFitness = thread_best_fitness[i]
                bestParams = thread_best_params[i]
                bestWorker = i
            end
        end

        if finalLoss > bestFitness
            finalLoss = bestFitness
            finalParams = bestParams
            setParams!(finalParams)

            println("[$count] loss updated as $finalLoss, updating out.txt and newest.txt")
            writedlm("out.txt", finalParams)
            writedlm("newest.txt", finalLoss)
        else
            println("[$count] no change. current best $bestParams")
        end
        global count += 1;
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

include("plot/plotting.jl")

# #Graph plotting
# include("plot/graphplotting.jl")