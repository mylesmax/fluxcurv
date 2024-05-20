# using BayesNets

# bn = BayesNet()

# push!(bn, StaticCPD(:Vm, Normal(0, 1)))
# push!(bn, LinearGaussianCPD(:DI, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DII, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DIV, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DIII_Inac, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:Po, [:DI, :DII, :DIV, :DIII_Inac, :Vm], [1.0, 1.0, 1.0, 1.0, 1.0], 0.0, 1.0))

# plot = BayesNets.plot(bn)
# samples = rand(bn, 100)
# println(samples)

# using BayesNets
# using Distributions
# using DataFrames
# using Turing
# using StatsPlots
# using ExponentialUtilities

# bn = BayesNet()

# push!(bn, StaticCPD(:Vm, Normal(0, 1)))
# push!(bn, LinearGaussianCPD(:DI, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DII, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DIII, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DIV, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:Po, [:DI, :DII, :DIII, :DIV, :Vm], [1.0, 1.0, 1.0, 1.0, 1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:I, [:DIII, :DIV], [1.0, 1.0], 0.0, 1.0))

# theme(:vibrant)
# BayesNets.plot(bn)








"""
an absolutely magnificent 7 state model graph
"""
# n=7
# n̅ = 3
# g = complete_digraph(n)
# s = 1 #s is scale
# @drawsvg begin
#     sethue("thistle2")
#     drawgraph(g,
#     vertexlabels=vertices(g),
#     edgecurvature=3,
#     vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen",
#     vertexshapesizes = (v) -> v ∈ (n̅) ? 20 : 10,
#     edgegaps= 15)
# end 500*s 400*s

using Graphs,Karnak,Colors,BlackBoxOptim, Distributed
using Flux, FastExpm, YAML, DelimitedFiles
import Flux.Losses: mse



begin

global n=5
global n̅ = 3
global rates = Dict{Edge, Tuple{Float64, Float64}}()
global args₁ = 2
global args₂ = 4
global dt = 1
global dataPath = "res/INaHEK/"

include("traintils/param.jl")
include("proto/protoImport.jl")
include("proto/protocols.jl")
include("proto/protocolBlocks.jl")

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


include("traintils/objective.jl")

# using NOMAD

# function eval_fct(p)
#     bb_outputs = [loss(p)]
#     success = false
#     count_eval = true
#     return (success, count_eval)
# end
# pb = NomadProblem(42, 1,["OBJ"],eval_fct)
# result = solve(pb, params)


res = bboptimize(
    loss, params;
    NumDimensions=length(params),
    MaxSteps = 50000,
    SearchRange = (-17, 17),
    TraceMode = :compact,
    PopulationSize = 5000,
    Method = :xnes,
    # Method = :probabilistic_descent,
    NThreads = Threads.nthreads()-1,
    Workers = workers(),
    lambda = 100
)


global params = best_candidate(res)
setParams!(params)

optimal_fitness = best_fitness(res)

writedlm("out.txt", params)


# @drawsvg begin
#     background("grey10")
    
#     sethue("pink")
    
#     drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
#  end 500*s 400*s






# # @benchmark fastExpm(Q(10)*dt)

# pso_settings = Optim.Options(iterations=1, 
#                              store_trace=true, 
#                              show_trace=true)

                             
# # Run the optimization
# result = optimize(loss, params, DifferentialEvolution())

# # Extract optimized parameters
# optimized_params = Optim.minimizer(result)


# for i ∈ 1:10
    
#     paramsParticleSwarm = Optim.minimizer(res)

#     nelderMead = optimize(cost, paramsParticleSwarm, Optim.Options(iterations=10))
#     global params = Optim.minimizer(nelderMead)

#     addIteration(out, i, minimum(nelderMead), validate())
#     out["curParams"] = rates
#     out["endtime"] = Dates.format(Dates.now(), "e, u d, Y at HH:MM:SS p")
#     YAML.write_file(pathicles*filename, out)
#     @show minimum(nelderMead)
# end