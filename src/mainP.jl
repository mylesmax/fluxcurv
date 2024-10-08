using Pkg
Pkg.activate(".")

using Graphs
using Karnak, Colors, UnPack
using Optim, Distributed, Dagger, LinearAlgebra
using YAML, DelimitedFiles, Statistics
using ExponentialUtilities
using Logging, Printf, Dates, LoggingExtras
using Metaheuristics
include("traintils/cascade.jl")
include("traintils/pade.jl")
include("traintils/loss.jl")
include("traintils/newloss.jl")

modelID = Dates.format(now(), "mmddss")

p = joinpath("logs-2/", @sprintf("%s-log_%s.log", (modelID), Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")))
formatlogger = FormatLogger(p, append=true) do io, args
    println(io, args._module, " | $(Dates.format(now(), "eud @ I:M:Sp CDT")) | ", "[", args.level, "] ", args.message)
end
consolelogger = FormatLogger(stdout) do io, args
    println(io, "[", args.level, "] ", args.message)
end
logg = TeeLogger(formatlogger, consolelogger)
with_logger(logg) do 
    @info "This log can be found at $p."
    # @info "nprocs = $(nprocs())"
end


# THREADS = trunc(Int, nprocs()/2)
with_logger(logg) do 
    @info "Packages and prereqs loaded, running with allocated threads = $(Threads.nthreads())."
end

n=0
algo = ""
if length(ARGS) > 0
    n = parse(Int, ARGS[1])
    algo = ARGS[2]
else
    n = 7
end

with_logger(logg) do
    @info "n set to $n; algo set to $algo"
end
n̅ = 1
additionals = [n, n̅]
opath = "models/May28/$(modelID)_n=$n.yaml"
ndim = 3*(n*(n-1))

out = Dict(
    "iteration" => 0,
    "f calls" => 0,
    "total minimum" => 0.0,
    "minimum" => 0.0,
    "minimizer" => zeros(ndim)
)


logger(st) = begin
    if mod(st.iteration, 10) == 0
        cm = consolidatedLoss(minimizer(st), additionals)

        out["iteration"] = st.iteration
        out["f calls"] = st.f_calls
        out["total minimum"] = cm
        out["minimum"] = minimum(st)
        out["minimizer"] = minimizer(st)

        YAML.write_file(opath, out)
        with_logger(logg) do
            @info "[$(st.iteration), elapsed = ($(time()-t1)] logged. total minimum = $(cm), breakdown = $(minimum(st))"
        end
    end
end

bounds = BoxConstrainedSpace(lb = zeros(ndim), ub = 100*ones(ndim))

information = Information(f_optimum = 0.0)
options = Metaheuristics.Options(iterations = 100000000, parallel_evaluation=true)

t1 = time()
algorithm = Restart(WOA(N=99999, options=options, information =information), every=200)
# out = YAML.load_file("/storage1/jonsilva/Active/m.max/Projects/fluxcurv/models/May28/0528864_n=7.yaml")
# x0 = out["minimizer"]
# x0 = x0'

# set_user_solutions!(algorithm, x0, x->objec_parallel(x, additionals, extra=false));

res = Metaheuristics.optimize(x->objec_parallel(x, additionals, extra=false), bounds, algorithm , logger=logger)
# if algo == "WOA"
#     res = Metaheuristics.optimize(x -> objec_parallel(x, additionals, extra=false), bounds, Restart(WOA(N=17000, options=options, information =information), every=200), logger=logger)
# elseif algo == "NSGA3"
#     res = Metaheuristics.optimize(x -> objec_parallel(x, additionals, extra=true), bounds, Restart(NSGA3(N=1700, options=options, information =information), every=200), logger=logger)
# elseif algo == "ECA"
#     res = Metaheuristics.optimize(x -> objec_parallel(x, additionals, extra=false), bounds, Restart(ECA(N=1700, K=1000, options=options, information =information), every=200), logger=logger)
# end




# global ct = 0
# while true
#     local pd = vec(readdlm(out))
#     local curloss = consolidatedLoss(pd, additionals)

#     # with_logger(logg) do
#     #     global ct
#     #     @info "[$ct] instantiated with $(curloss)"
#     # end

#     t1 = time()

#     tasks = [Distributed.@spawn optimizationCascade(consolidatedLoss, pd, additionals) for _ in 1:THREADS]
#     results = map(Distributed.fetch, tasks)
#     indecks = argmin([Optim.minimum(results[i]) for i in 1:length(results)])
    
#     local pd = Optim.minimizer(results[indecks])
#     best = Optim.minimum(results[indecks])

#     with_logger(logg) do 
#         global ct
#         @info "[$ct] loss = $best. took $(time()-t1) sec. $(THREADS) threads."
#     end

#     writedlm(out, pd)

#     global ct += 1
# end

# """
# PLOTTING?
# """

# include("plot/plotting.jl")

# #Graph plotting
# include("plot/graphplotting.jl")