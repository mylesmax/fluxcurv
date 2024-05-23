using Pkg
Pkg.activate(".")

using Graphs, Karnak, Colors, Optim, Distributed, Dagger
using YAML, DelimitedFiles,Statistics
using ExponentialUtilities, UnPack
using Logging, Printf, Dates, LoggingExtras
include("proto/protoImport.jl")

#-------------------------#

n=7
n̅ = 1
dt = 1e-12 #dt has to be set this low to allow for convergence between machines and fitting accuracy
dataPath = "res/INaHEK/"
protoData = protoImport(dataPath)
out = "out.txt"
newest = "newest.txt"

mutable struct Addits
    n::Int
    n̅::Int
    dt::Float64
    dataPath::String
    protoData::NamedTuple
end

#-------------------------#

include("traintils/consolidatedLoss.jl")

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
    @info "Threads allocated = $(Threads.nthreads())."
end

begin  
    local params
    local finalLoss
    local finalParams
    local ct

    additionals = Addits(n, n̅, dt, dataPath, protoData)

    # #GRAPH
    # s=1.5
    # g = complete_graph(n)
    # @drawsvg begin
    # background("grey10")
    # sethue("pink")
    # drawgraph(g, vertexlabels = vertices(g),vertexshapesizes = (v) -> v ∈ (n̅) ? 25 : 20,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
    # end 500*s 400*s

    params = rand(2*(n*(n-1))+2)
    try
        params = vec(readdlm(out))
    catch
        writedlm(out, params)

        with_logger(logg) do
            @info "wrote new params to $out"
        end
    end
    

    finalParams = params
    finalLoss = consolidatedLoss(params, additionals)
    ThreadOutput = NamedTuple{(:fitness, :params), Tuple{Float64, Any}}

    ct = 0
    while true
        params = vec(readdlm(out))
        with_logger(logg) do
            @info "[$ct] instantiated with $(consolidatedLoss(params, additionals))"
        end

        bestFitness = Inf
        bestParams = params
        bestWorker = -1
        
        threadOut = Vector{Union{Nothing, ThreadOutput}}(undef, Threads.nthreads())
        fill!(threadOut, nothing)
        
        with_logger(logg) do
            @info "[$ct] training"
        end
        
        lck = ReentrantLock()
        Threads.@threads for i ∈ 1:(Threads.nthreads())
            res = optimize(x -> consolidatedLoss(x, additionals), params, ParticleSwarm(n_particles = 11), Optim.Options(time_limit=170))
            # with_logger(logg) do
            #     @info "[Thread $(Threads.threadid())] I just completed PSO with loss $(Optim.minimum(res))."
            # end

            nres = optimize(x -> consolidatedLoss(x, additionals), Optim.minimizer(res), NelderMead(), Optim.Options(time_limit=35))
            # with_logger(logg) do
            #     @info "[Thread $(Threads.threadid())] I just completed NM with loss $(Optim.minimum(nres))."
            # end

            Threads.lock(lck) do
                threadOut[Threads.threadid()] = (fitness = Optim.minimum(nres), params = Optim.minimizer(nres))
                # threadOut[Threads.threadid()] = (fitness = Optim.minimum(res), params = Optim.minimizer(res))
                # with_logger(logg) do
                #     # @info "[Thread $(Threads.threadid())] Locked in fitness $(Optim.minimum(nres))."
                #     @info "[Thread $(Threads.threadid())] Locked in fitness $(Optim.minimum(res))."
                # end
            end
        end
        
        @info "[$ct] training round concluded on $(Threads.nthreads()) threads, determining best"

        # consolidate = Vector{Union{Nothing, ThreadOutput}}(undef, Threads.nthreads())
        # fill!(consolidate, nothing)
        # for (i, output) in enumerate(threadOut)
        #     if output !== nothing
        #         consolidate[i] = (fitness = loss(output.params), params = output.params)
        #     end
        # end

        
    
        for (i, output) in enumerate(threadOut)
            # with_logger(logg) do 
            #     @info output.fitness
            # end
            with_logger(logg) do
                @info "[$i] computed loss $(consolidatedLoss(output.params, additionals)), fitness $(output.fitness)"
            end

            if output !== nothing && output.fitness < bestFitness
                bestFitness = output.fitness
                bestParams = output.params
            end
        end

        if finalLoss > bestFitness
            finalLoss = bestFitness
            finalParams = bestParams
            params = finalParams

            with_logger(logg) do
                @info "[$ct] loss updated as $finalLoss, updating $out and $newest"
            end

            writedlm(out, finalParams)
            writedlm(newest, finalLoss)
        else
            with_logger(logg) do
                @info "[$ct] no change. current best $finalLoss < $bestFitness"
            end
        end
        with_logger(logg) do
            @info "[$ct] ---------------------------- END ----------------------------"
        end
        ct += 1;
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