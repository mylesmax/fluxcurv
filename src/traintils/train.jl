# using Optim, LinearAlgebra, DelimitedFiles, YAML, ExponentialUtilities,Dates
# include("objective.jl")
# include("../proto/protocolBlocks.jl")
# # include("../src/plotting.jl")
# include("markov.jl")
# include("../proto/protocols.jl")


# openStateIndex = 1;
# dt = 1;
# pathicles = "trainedSaves/7stateflex/psoApril7/"

# if length(ARGS) > 0
#     particles = parse(Int, ARGS[1])
# else
#     particles = 550
# end

# #PSO!!!
# println("particles chosen as $particles, will save to "*pathicles*"pso$particles.yml")
# filename = "pso$particles.yml";

# #TODO: get instantiated manifest from washu servers

# out = Dict(
#     "starttime" => Dates.format(Dates.now(), "e, u d, Y at HH:MM:SS p"),
#     "endtime" => nothing,
#     "curParams" => nothing,
#     "particles" => particles,
#     "iterations" => []
# )

# # global params = vec(readdlm("trainedSaves/Previous/newmodel.txt"))
# # global params = vec(readdlm("trainedSaves/7stateflex/init.txt"))
# # updateRates!(params)

# eek = YAML.load_file("/storage1/jonsilva/Active/m.max/Projects/Markov Model (Simple Na)/markovSimpleNa/trainedSaves/7stateflex/psoApril7/pso10000.yml")["curParams"]
# curRates = Dict{Int64, Tuple{Float64, Float64}}()
# for (key, value) in eek
#     value_parts = split(replace(value, r"[()]" => ""), ",")
#     tuple_value = (parse(Float64, strip(value_parts[1])), parse(Float64, strip(value_parts[2])))
    
#     curRates[key] = tuple_value
# end

# global params = rates2Params(curRates)

# #f=GLMakie.Figure(size=(800,450),fontsize=18)

# function addIteration(data, iteration, loss=nothing, validation=nothing)
#     new_iteration = Dict(
#         "iteration" => iteration,
#         "loss" => loss,
#         "validation" => validation,
#         "endtime" => Dates.format(Dates.now(), "e, u d, Y at HH:MM:SS p")
#     )
#     push!(out["iterations"], new_iteration)
# end


# for i ∈ 1:100000
#     @show i
#     res = optimize(cost, params, ParticleSwarm(n_particles=particles), Optim.Options(iterations=10))
#     paramsParticleSwarm = Optim.minimizer(res)

#     nelderMead = optimize(cost, paramsParticleSwarm, Optim.Options(iterations=10))
#     global params = Optim.minimizer(nelderMead)

#     addIteration(out, i, minimum(nelderMead), validate())
#     out["curParams"] = rates
#     out["endtime"] = Dates.format(Dates.now(), "e, u d, Y at HH:MM:SS p")
#     YAML.write_file(pathicles*filename, out)
#     @show minimum(nelderMead)
# end