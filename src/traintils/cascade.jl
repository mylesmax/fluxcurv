function optimizationCascade(consolidatedLoss::Function, paramz::Vector{Float64}, additionals::Vector{Int64})
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
    # optf = OptimizationFunction(consolidatedLossTest, Optimization.AutoReverseDiff())
    # prob = OptimizationProblem(optf, pd, additionals, lb = 0*ones(length(paramz)), ub = 1e9*ones(length(paramz)))
    # sol = solve(prob, ParticleSwarm())
    # sol.objective



    # nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 100000,lower = 0*ones(length(paramz)), upper =[]), Optim.Options(iterations=34))
    
    nres = optimize(x -> consolidatedLoss(x, additionals), paramz, ParticleSwarm(n_particles = 1111,lower = 0*ones(length(paramz)), upper =1*ones(length(paramz))), Optim.Options(iterations=10))
    # paramz = Optim.minimizer(nres)

    # #train m
    # nres2 = optimize(x -> consolidatedLoss(paramz, additionals, [x, args[2], args[3]]), [args[1]], ParticleSwarm(n_particles = 11, lower = [1], upper = [3]), Optim.Options(iterations=20))
    # args[1] = Optim.minimizer(nres2)[1]

    # #train n
    # nres2 = optimize(x -> consolidatedLoss(paramz, additionals, [args[1], x, args[3]]), [args[2]], ParticleSwarm(n_particles = 11, lower = [100], upper = [130]), Optim.Options(iterations=20))
    # args[2] = Optim.minimizer(nres2)[1]

    # #train h
    # nres2 = optimize(x -> consolidatedLoss(paramz, additionals, [args[1], args[2], x]), [args[3]], ParticleSwarm(n_particles = 11, lower = [0], upper = [50]), Optim.Options(iterations=20))
    # args[3] = Optim.minimizer(nres2)[1]
    
    
    
    # nres = fetch(nres)

    # paramz = Optim.minimizer(nres)
    # nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 11,lower = 0*ones(length(paramz)), upper =[]), Optim.Options(time_limit=7))
    # paramz = Optim.minimizer(nres)
    # nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 11,lower = 0*ones(length(paramz)), upper =[]), Optim.Options(time_limit=7))
    # paramz = Optim.minimizer(nres)
    # nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 11,lower = 0*ones(length(paramz)), upper =[]), Optim.Options(time_limit=7))
    # paramz = Optim.minimizer(nres)
    # nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 11,lower = 0*ones(length(paramz)), upper =[]), Optim.Options(time_limit=7))
    # nres = optimize(consolidatedLoss, paramz, ParticleSwarm(n_particles = 1000,lower = 0*ones(length(paramz)), upper =1000*ones(length(paramz))), Optim.Options(iterations=1))
    return nres
end