# using Distributed
# @everywhere begin
#     using Pkg
#     Pkg.activate(".")
#     Pkg.instantiate()
# end
using Pkg
Pkg.activate(".")
# Pkg.instantiate()

using Distributed
addprocs(50)

@everywhere using Graphs, Karnak, Colors, UnPack
@everywhere using Optim, Distributed, Dagger, LinearAlgebra
@everywhere using YAML, DelimitedFiles, Statistics
@everywhere using ExponentialUtilities
@everywhere using Logging, Printf, Dates, LoggingExtras
@everywhere using BlackBoxOptim

@everywhere include("proto/protoImport.jl")
@everywhere include("traintils/cascade.jl")
@everywhere include("traintils/pade.jl")

@everywhere THREADS = nprocs()

#-------------------------#

# n=7
# n̅ = 1
# dt = 1e-4 #dt has to be set this low to allow for convergence between machines and fitting accuracy
# dataPath = "res/INaHEK/"
# protoData = protoImport(dataPath)
@everywhere out = "out.txt"
# newest = "newest.txt"

# mutable struct Addits
#     n::Int
#     n̅::Int
#     dt::Float64
#     dataPath::String
#     protoData::NamedTuple
# end

#-------------------------#

@everywhere include("../psogpu/clgpu.jl")

#LOGGING
p = joinpath("logs/", @sprintf("log_%s.log", Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")))

formatlogger = FormatLogger(p, append=true) do io, args
    println(io, args._module, " | $(Dates.format(now(), "eud @ I:M:Sp CDT")) | ", "[", args.level, "] ", args.message)
end
consolelogger = FormatLogger(stdout) do io, args
    println(io, "[", args.level, "] ", args.message)
end
logg = TeeLogger(formatlogger, consolelogger)

with_logger(logg) do 
    @info "This log can be found at $p."
    @info "Threads allocated = $(THREADS)."
end

@everywhere local pd
    # local finalLoss
    # local finalParams
global ct

# additionals = Addits(n, n̅, dt, dataPath, protoData)

# #GRAPH
# s=1.5
# g = complete_graph(n)
# @drawsvg begin
# background("grey10")
# sethue("pink")
# drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
# end 500*s 400*s
@everywhere n=7
@everywhere n̅ = 1

@everywhere begin
    local pd = rand(2*(n*(n-1))+2)
    try
        local pd = vec(readdlm(out))
    catch
        writedlm(out, pd)

        with_logger(logg) do
            @info "wrote new pd to $out"
        end
    end
end

# additionals = Int[n, n̅]
# finalParams = params
# # finalLoss = consolidatedLoss(params, additionals)
# finalLoss = consolidatedLoss(params)
# ThreadOutput = NamedTuple{(:fitness, :params), Tuple{Float64, Any}}


global ct = 0
while true
    @everywhere THREADS = nprocs()

    local pd = vec(readdlm(out))
    local curloss = consolidatedLoss(pd)

    with_logger(logg) do
        # @info "[$ct] instantiated with $(consolidatedLoss(params, additionals))"
        global ct
        @info "[$ct] instantiated with $(curloss)"
    end

    t1 = time()

    tasks = [Distributed.@spawn optimizationCascade(consolidatedLoss, pd) for _ in 1:THREADS/2]
    results = map(Distributed.fetch, tasks)
    indecks = argmin([Optim.minimum(results[i]) for i in 1:length(results)])
    
    local pd = Optim.minimizer(results[indecks])
    best = Optim.minimum(results[indecks])
    # best == consolidatedLoss(params) ? (@show best) : nothing
    

    with_logger(logg) do 
        global ct
        @info "[$ct] loss = $best. took $(time()-t1) sec. $(THREADS) threads/2."
    end

    curloss > best ? writedlm("out.txt", pd) : nothing

    global ct += 1

    # bestFitness = Inf
    # bestParams = params
    # bestWorker = -1
    
    # threadOut = Vector{Union{Nothing, ThreadOutput}}(undef, Threads.nthreads())
    # fill!(threadOut, nothing)
    
    # with_logger(logg) do
    #     @info "[$ct] training"
    # end
    
    # lck = ReentrantLock()
    # @sync for i ∈ 1:1
    #     # res = bboptimize(
    #     #         consolidatedLoss, params;
    #     #         NumDimensions=length(params),
    #     #         # MaxSteps=5000,
    #     #         MaxTime = 34,
    #     #         SearchRange = (-100, 100),
    #     #         TraceMode = :silent,
    #     #         PopulationSize = 17000,
    #     #         Method = :xnes,
    #     #         lambda = 100,
    #     # )

    #     # Threads.lock(lck) do
    #     #     threadOut[Threads.threadid()] = (fitness = best_fitness(res), params = best_candidate(res))
    #     #     # threadOut[Threads.threadid()] = (fitness = Optim.minimum(res), params = Optim.minimizer(res))
    #     #     # with_logger(logg) do
    #     #     #     # @info "[Thread $(Threads.threadid())] Locked in fitness $(best_fitness(res))."
    #     #     #     # @info "[Thread $(Threads.threadid())] Locked in fitness $(Optim.minimum(res))."
    #     #     # end
    #     # end


    #     # params = Optim.minimizer(nres)
    #     nres = Dagger.@par consolidatedLoss(params)
    
    #     Dagger.collect.(nres)
    #     nres = Dagger.@shard optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -20*ones(length(params)), upper =20*ones(length(params))), Optim.Options(time_limit=7))
    #     j = Dagger.@spawn Dagger.fetch(nres)

        
        

        

        

    #     Dagger.fetch(j)

    #     optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 11,lower = -20*ones(length(paramz)), upper =20*ones(length(paramz))), Optim.Options(time_limit=7))
    #     with_logger(logg) do 
    #         @info "[Thread $(myid())] step 1 done, $(Optim.minimum(nres))"
    #     end

    #     # @show Optim.minimum(nres)
    #     params = Optim.minimizer(nres)
    #     nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -20*ones(length(params)), upper =20*ones(length(params))), Optim.Options(time_limit=7))
    #     with_logger(logg) do 
    #         @info "[Thread $(myid())] step 2 done, $(Optim.minimum(nres))"
    #     end
    #     # @show Optim.minimum(nres)
    #     params = Optim.minimizer(nres)
    #     nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -20*ones(length(params)), upper =20*ones(length(params))), Optim.Options(time_limit=3))
    #     with_logger(logg) do 
    #         @info "[Thread $(myid())] step 3 done, waiting, $(Optim.minimum(nres))"
    #     end
    #     threadOut[myid()] = (fitness = Optim.minimum(nres), params = Optim.minimizer(nres))
        
    #     # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=2))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=2))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=7))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=2))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=2))
    #     # # # @show Optim.minimum(nres)
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # # params = Optim.minimizer(nres)
    #     # # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -17*ones(length(params)), upper =17*ones(length(params))), Optim.Options(time_limit=3))
    #     # Optim.minimum(nres)
    #     # # with_logger(logg) do
    #     # #     @info "[Thread $(Threads.threadid())] I just completed PSO with loss $(Optim.minimum(res))."
    #     # # end

    #     # # nres = optimize(x -> consolidatedLoss(x, additionals), Optim.minimizer(res), NelderMead(), Optim.Options(time_limit=35))
    #     # # with_logger(logg) do
    #     # #     @info "[Thread $(Threads.threadid())] I just completed NM with loss $(Optim.minimum(nres))."
    #     # # end

    #     # Threads.lock(lck) do
    #     #     threadOut[Threads.threadid()] = (fitness = Optim.minimum(nres), params = Optim.minimizer(nres))
    #     #     # threadOut[Threads.threadid()] = (fitness = Optim.minimum(res), params = Optim.minimizer(res))
    #     #     # with_logger(logg) do
    #     #     #     @info "[Thread $(Threads.threadid())] Locked in fitness $(Optim.minimum(nres))."
    #     #     #     # @info "[Thread $(Threads.threadid())] Locked in fitness $(Optim.minimum(res))."
    #     #     # end
    #     # end
    # end
    
    # @info "[$ct] training round concluded on $(Threads.nthreads()) threads, determining best"

    # # consolidate = Vector{Union{Nothing, ThreadOutput}}(undef, Threads.nthreads())
    # # fill!(consolidate, nothing)
    # # for (i, output) in enumerate(threadOut)
    # #     if output !== nothing
    # #         consolidate[i] = (fitness = loss(output.params), params = output.params)
    # #     end
    # # end

    

    # for (i, output) in enumerate(threadOut)
    #     # with_logger(logg) do 
    #     #     @info output.fitness
    #     # end
    #     # with_logger(logg) do
    #     #     # @info "[$i] computed loss $(consolidatedLoss(output.params, additionals)), fitness $(output.fitness)"
    #     #     @info "[Thread $i] computed loss $(consolidatedLoss(output.params)), fitness $(output.fitness)"
    #     # end

    #     if output !== nothing && output.fitness < bestFitness
    #         bestFitness = output.fitness
    #         bestParams = output.params
    #     end
    # end

    # if finalLoss > bestFitness
    #     finalLoss = bestFitness
    #     finalParams = bestParams
    #     params = finalParams

    #     with_logger(logg) do
    #         @info "[$ct] loss updated as $finalLoss, updating $out and $newest"
    #     end

    #     writedlm(out, finalParams)
    #     writedlm(newest, finalLoss)
    # else
    #     with_logger(logg) do
    #         @info "[$ct] no change. current best $finalLoss < $bestFitness"
    #     end
    # end
    # with_logger(logg) do
    #     @info "[$ct] ---------------------------- END ----------------------------"
    # end
    # ct += 1;
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