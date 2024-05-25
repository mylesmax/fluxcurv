function optimizationCascade(consolidatedLoss::Function, paramz::Vector{Float64})
    # res = bboptimize(
    #             consolidatedLoss;
    #             NumDimensions=86,
    #             # MaxSteps=5000,
    #             MaxTime = 100,
    #             SearchRange = (-10, 10),
    #             TraceMode = :compact,
    #             PopulationSize = 17000,
    #             Method = :generating_set_search,
    #             lambda = 100,
    #     )
    # best_fitness(res)
    # paramz = best_candidate(res)

    nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 11,lower = 0*ones(length(paramz)), upper =40*ones(length(paramz))), Optim.Options(iterations=17))
    
    # params = Optim.minimizer(nres)
    # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -20*ones(length(params)), upper =20*ones(length(params))), Optim.Options(time_limit=7))
    
    # params = Optim.minimizer(nres)
    # nres = optimize(consolidatedLoss, params, ParticleSwarm(n_particles = 11,lower = -20*ones(length(params)), upper =20*ones(length(params))), Optim.Options(time_limit=3))
    
    
    # with_logger(logg) do 
    #     @info "[Thread $(myid())] step 3 done, waiting, $(Optim.minimum(nres))"
    # end
    return nres
end