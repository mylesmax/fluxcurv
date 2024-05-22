using Pkg
Pkg.activate(".")

using Graphs, Karnak, Colors, Optim, Distributed, Dagger
using Flux, YAML, DelimitedFiles,Statistics
using ExponentialUtilities
using Logging, Printf, Dates, LoggingExtras
import Flux.Losses: mse

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
    @info "Threads allocated = $(Threads.nthreads())."
end

begin

    global n=7
    global n̅ = 1
    global rates = Dict{Edge, Tuple{Float64, Float64}}()
    global args₁ = 2
    global args₂ = -4
    global dt = 0.1
    global dataPath = "res/INaHEK/"
    global out = "out.txt"
    global newest = "newest.txt"

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

    global paramz = getParams()

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

    global paramz = vec(readdlm(out))
    # @show loss(paramz)
    # writedlm(newest, loss(paramz))

    # writedlm(newest, loss(paramz))
    

    global paramz
    global countz = 0;
    global finalParams = paramz;
    global finalLoss = loss(paramz);
    ThreadOutput = NamedTuple{(:fitness, :params), Tuple{Float64, Any}}
    



    while true
        global paramz = vec(readdlm(out))
        setParams!(paramz)
        with_logger(logg) do 
            @info "[$countz] instantiated with $(loss(paramz))"
        end
        #TODO: NEED TO REWRITE AND GET RID OF ALL GLOBAL PARAMETERS BECAUSE I THINK THAT'S WHAT'S MESSING IT UP
        #TODO: consolidate into one large loss function that takes in params and outputs the cost
        #Will need to pass in all the notable parameters such as n, nbar, dt, etc.

        bestFitness = Inf
        bestParams = paramz
        bestWorker = -1
        
        threadOut = Vector{Union{Nothing, ThreadOutput}}(undef, Threads.nthreads())
        fill!(threadOut, nothing)
        
        with_logger(logg) do 
            @info "[$countz] training"
        end
        
        lck = ReentrantLock()
        Threads.@threads for i ∈ 1:(Threads.nthreads())
            res = 
            optimize(loss, paramz, ParticleSwarm(
                # lower = -30*ones(length(paramz)),
                # upper = 30*ones(length(paramz)),
                n_particles = 11), Optim.Options(time_limit=170))
            # with_logger(logg) do 
            #     @info "[Thread $(Threads.threadid())] I am thread $(Threads.threadid())! I just completed PSO with loss $(Optim.minimum(res))."
            # end

            nres = 
            optimize(loss, Optim.minimizer(res), NelderMead(), Optim.Options(time_limit=35))
            # with_logger(logg) do 
            #     @info "[Thread $(Threads.threadid())] I am thread $(Threads.threadid())! I just completed NM with loss $(Optim.minimum(nres))."
            # end
            
            Threads.lock(lck) do
                threadOut[Threads.threadid()] = (fitness = 9, params = Optim.minimizer(nres))
            end
            # res = bboptimize(
            #         loss, paramz;
            #         NumDimensions=length(paramz),
            #         #MaxSteps=50,
            #         MaxTime = 5,
            #         SearchRange = (-30, 30),
            #         TraceMode = :silent,
            #         PopulationSize = 17000,
            #         Method = :generating_set_search,
            #         lambda = 100,
            # )
            # Threads.lock(lck) do
            #     threadOut[Threads.threadid()] = (fitness = best_fitness(res), params = best_candidate(res))
            #     with_logger(logg) do 
            #         @info "[$Threads.threadid()] within lock, fitness = $(best_fitness(res)), params = $(best_candidate(res)) "
            #     end
            # end
            
        end
        
        with_logger(logg) do 
            @info "[$countz] training round concluded on $(Threads.nthreads()) threads, determining best"
        end

        consolidate = Vector{Union{Nothing, ThreadOutput}}(undef, Threads.nthreads())
        fill!(consolidate, nothing)
        for (i, output) in enumerate(threadOut)
            if output !== nothing
                consolidate[i] = (fitness = loss(output.params), params = output.params)
            end
        end

        
        
        
        for (i, output) in enumerate(consolidate)
            # with_logger(logg) do 
            #     @info output.fitness
            # end
            # with_logger(logg) do 
            #     @info "[$i] computed loss $(loss(output.params)), fitness $(output.fitness)"
            # end
            if output !== nothing && output.fitness < bestFitness
                
                bestFitness = output.fitness
                bestParams = output.params
            end
        end

        global finalLoss

        if finalLoss > bestFitness
            global finalLoss = bestFitness
            global finalParams = bestParams
            global paramz = finalParams
            setParams!(finalParams)

            with_logger(logg) do 
                @info "[$countz] loss updated as $finalLoss, updating $out and $newest"
            end
            writedlm(out, finalParams)
            writedlm(newest, finalLoss)
        else
            with_logger(logg) do 
                @info "[$countz] no change. current best $finalLoss < $bestFitness"
            end
        end
        with_logger(logg) do 
            @info "[$countz] ---------------------------- END ----------------------------"
        end
        global countz += 1;
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