function consolidatedLossES(params::Vector{Float64}, additionals::Vector{Int64}; returnforPlotting::Bool=false)::Any
    n̅ = additionals[1]
    # n=7
    n̅ = additionals[2]
    dt = 1e-4
    dataPath = "res/INaHEK/"
    
    rates = Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64,Float64}}(Edge(i::Int64, j::Int64) => (0,0,0) for i in 1:n, j in 1:n if i != j for idx in (2 * (i - 1) * (n - 1) + 2 * (j - 1) + 1):(2 * (i - 1) * (n - 1) + 2 * (j - 1) + 2))
    
    idx::Int = 1
    for e in sort(collect(keys(rates)))::Vector{Graphs.SimpleGraphs.SimpleEdge}
        rates[e] = (params[idx], params[idx + 1], params[idx + 2])::Tuple{Float64,Float64,Float64}
        idx += 3
    end

    """
    ACTIVATION PROTOCOL
    """
    #initialize
    activationErr = 1e3
    #TODO: get groundtruth :WTgv
    # activationProtocol= (protoData::NamedTuple)[:WTgv] #TODO

    # y = (readdlm(dataPath * "WTgv.dat"::String)::Matrix{Float64})[:, 2]::Vector{Float64}
    y::Vector{Float64} = vec([0.01  0.04  0.12  0.3  0.65  0.75  0.82  0.87  0.94  0.97  0.99])

    #simulate activation
    # data = readdlm(dataPath*activationProtocol["source"]::String)
    data = [-43.27  0.01  0.01
    -39.5   0.04  0.01
    -34.95  0.12  0.02
    -29.57  0.3   0.02
    -19.2   0.65  0.05
    -13.5   0.75  0.03
     -8.95  0.82  0.02
     -4.05  0.87  0.02
      5.74  0.94  0.01
     16.25  0.97  0.01
     20.76  0.99  0.01]
    initial = simulateSS(dt, rates, Q, -100.0)

    steps::Vector{Vector{Float64}} = []
    for V::Float64 ∈ data[:,1]
        
        step::Vector{Float64} = simulateStep(dt, rates, Q, V, 25.0, initial)::Vector{Float64}
        push!(steps, step)
    end

    oNormalized = []
    o::Vector{Float64} = [steps[i][n̅] for i in 1:size(steps)[1]]
    oNormalized::Vector{Float64} = o ./ findmax(o)[1]

    ŷ::Vector{Float64} = oNormalized

    activationErr::Float64 = mean((ŷ .- y) .^ 2)

    (isnan(activationErr) | isinf(activationErr)) ? activationErr = 1e3 : nothing

    y_activation = y
    ŷ_activation = ŷ


    """
    INACTIVATION PROTOCOL
    """
    #initialize
    inactivationErr = 1e3
    #TODO: get groundtruth :WTinac
    # inactivationProtocol = protoData[:WTinac] #TODO

    # y = readdlm(dataPath * inactivationProtocol["source"])[:, 2]
    y=vec([1.0  1.0  0.95  0.75  0.39  0.01])
    
    #simulate inactivation
    # data = readdlm(dataPath*inactivationProtocol["source"])
    data= [-110.0  1.0   0.01
    -100.0  1.0   0.01
     -80.0  0.95  0.01
     -70.0  0.75  0.02
     -60.0  0.39  0.03
     -40.0  0.01  0.01]
    initial = simulateSS(dt, rates, Q, -100.0)

    steps = []
    for V ∈ data[:,1]
        step::Vector{Float64} = simulateStep(dt, rates, Q, V, 500.0, initial)
        test::Vector{Float64} = simulateStep(dt, rates, Q, -10, 25.0, step)
        push!(steps, test)
    end

    oNormalized = []
    o = [steps[i][n̅] for i in 1:size(steps)[1]]
    oNormalized = o ./ findmax(o)[1]

    ŷ = oNormalized

    inactivationErr = mean((ŷ .- y) .^ 2)

    (isnan(inactivationErr) | isinf(inactivationErr)) ? inactivationErr = 1e3 : nothing

    y_inactivation = y
    ŷ_inactivation = ŷ


    """
    RECOVERY PROTOCOL
    """
    #initialize
    recoveryErr = 1e3
    #TODO: get groundtruth :WTrecovery
    # recoveryProtocol = protoData[:WTrecovery] #TODO

    # y = readdlm(dataPath * recoveryProtocol["source"])[:, 2]
    y=vec([0.05  0.8  0.82  0.86  0.93  0.95  0.99  0.99  0.99  0.99])
    
    #simulate recovery
    # data = readdlm(dataPath*recoveryProtocol["source"])
    data = [   0.5  0.05  0.02
    6.0  0.8   0.03
    8.9  0.82  0.04
   11.9  0.86  0.02
   20.6  0.93  0.01
   29.8  0.95  0.01
   58.0  0.99  0.01
   87.7  0.99  0.01
  120.6  0.99  0.01
  208.2  0.99  0.01]
    initial = simulateSS(dt, rates, Q, -100.0)

    #first pulse (depolarizing)
    step1::Vector{Float64} = simulateStep(dt, rates, Q, -10, 500.0, initial)

    steps = []
    for tDur ∈ data[:,1]
        #second pulses (hyperpolarizing)
        step2::Vector{Float64} = simulateStep(dt, rates, Q, -100, tDur, step1::Vector{Float64})
        #test pulse
        step3::Vector{Float64} = simulateStep(dt, rates, Q, -10.0, 25.0, step2::Vector{Float64})

        #save
        push!(steps, step3)
    end

    oNormalized = []
    o = [steps[i][n̅] for i in 1:size(steps)[1]::Int]
    oNormalized = o ./ findmax(o)[1]

    ŷ = oNormalized
    recoveryErr = mean((ŷ .- y) .^ 2)

    (isnan(recoveryErr) | isinf(recoveryErr)) ? recoveryErr = 1e3 : nothing

    y_recovery = y
    ŷ_recovery = ŷ

    """
    RECOVERY UDB PROTOCOL
    """
    #initialize
    recoveryUDBErr = 1e3
    #TODO: get groundtruth :WTRUDB
    # recoveryUDBProtocol = protoData[:WTRUDB] #TODO

    # y = readdlm(dataPath * recoveryUDBProtocol["source"])[:, 2]
    y=vec([0.02  0.07  0.51  0.72  0.89  0.96  0.99  1.0])
    
    #simulate recovery UDB
    # data = readdlm(dataPath*recoveryUDBProtocol["source"])
    data = [    0.49  0.02  0.01
    1.0   0.07  0.01
    8.89  0.51  0.05
   29.8   0.72  0.05
  298.0   0.89  0.02
  904.0   0.96  0.02
 2980.0   0.99  0.01
 8890.0   1.0   0.01]
    initial = simulateSS(dt, rates, Q, -100.0)

    step2 = initial
    #depolarizing pulse train
    for i ∈ 1:100
        step1= simulateStep(dt, rates, Q, -10, 25.0, step2::Vector{Float64})
        step2 = simulateStep(dt, rates, Q, -100, 15.0, step1::Vector{Float64})
        #note the math: dt=25ms in step1 + dt=15ms in step 2 is 40ms which is 25 Hz
    end

    steps = []
    for tDur ∈ data[:,1]
        #hyperpolarizing pulse
        step3::Vector{Float64} = simulateStep(dt, rates, Q, -100, tDur, step2::Vector{Float64})
        #test pulse
        step4::Vector{Float64} = simulateStep(dt, rates, Q, -10, 25.0, step3::Vector{Float64})

        #save
        push!(steps, step4)
    end

    oNormalized = []
    o = [steps[i][n̅] for i in 1:size(steps)[1]::Int]
    oNormalized = o ./ findmax(o)[1]

    ŷ = oNormalized
    recoveryUDBErr = mean((ŷ .- y) .^ 2)

    (isnan(recoveryUDBErr) | isinf(recoveryUDBErr)) ? recoveryUDBErr = 1e3 : nothing

    y_recoveryUDB = y
    ŷ_recoveryUDB = ŷ

    """
    MAXPO PROTOCOL
    """
    #initialize
    maxPOErr = 1e3
    #TODO: get groundtruth :WTmaxpo
    # maxPOProtocol = protoData[:WTmaxpo] #TODO

    # y = readdlm(dataPath * maxPOProtocol["source"])[:, 2]
    y_MAXPO = y
    ŷ_MAXPO = ŷ
    #simulate maxPO
    try
        # @show params
        # data = readdlm(dataPath*maxPOProtocol["source"])
        data = [ -20.0  0.31  0.05
        -10.0  0.31  0.05
          0.0  0.31  0.05]
        initial = simulateSS(dt, rates, Q, -100.0)
        peaks = []
        for V ∈ data[:,1]
            peak::Float64 = simulateStep(dt, rates, Q, V, 100.0, initial, peak=true, time=false)::Float64

            push!(peaks, peak::Float64)
        end
        
        y_MAXPO = vec([0.31 0.31 0.31])
        ŷ_MAXPO = convert(Vector{Float64}, peaks)

        maxPOErr = mean((convert(Vector{Float64}, peaks) .- vec([0.31 0.31 0.31])) .^ 2)
        (isnan(maxPOErr) | isinf(maxPOErr)) ? maxPOErr = 1e3 : nothing
    catch
        maxPOErr = 1e3
    end
    # @show maxPOErr

    

    """
    FALL PROTOCOL
    """
    #initialize
    fallErr = 1e3
    #TODO: get groundtruth :WTfall
    # fallProtocol = protoData[:WTfall] #TODO

    # y = readdlm(dataPath * fallProtocol["source"])[:, 2]
    y_FALL = y
    ŷ_FALL = ŷ
    #simulate fall
    try
        # data = readdlm(dataPath*fallProtocol["source"])
        data =[20.0  0.48  0.01
        15.0  0.5   0.01
        10.0  0.52  0.02
         5.0  0.55  0.02
        -5.0  0.65  0.03
       -10.0  0.73  0.03
       -15.0  0.84  0.03]
        initial = simulateSS(dt, rates, Q, -100.0)

        durations = []
        for V ∈ data[:,1]
            #for each voltage, we gather the time distribution of the open state
            #and isolate the peak, 50% of the peak, and determine the time between them
            duration::Float64 = simulateStep(dt, rates, Q, V, 500.0, initial, halfpeak=true)
            
            push!(durations, duration::Float64)
        end

        y_FALL = vec([0.48  0.5  0.52  0.55  0.65  0.73  0.84])
        ŷ_FALL = convert(Vector{Float64} ,durations)

        fallErr = mean((convert(Vector{Float64} ,durations) .- vec([0.48  0.5  0.52  0.55  0.65  0.73  0.84])) .^ 2)
        (isnan(fallErr) | isinf(fallErr)) ? fallErr = 1e3 : nothing
    catch
        fallErr = 1e3
    end
    # @show fallErr


    """
    TIME TO PEAK PROTOCOL
    """
    #initialize
    ttpErr = 1e3
    
    initial = simulateSS(dt, rates, Q, -100)

    y_TTP = [1]
    ŷ_TTP = [0]

    ttpS = []
    try
        timeToPeak::Float64 = simulateStep(dt, rates, Q, -10, 500.0, initial, peak=true,time=true)::Float64
        
        ŷ_TTP = [timeToPeak]
        ttpErr = mean((timeToPeak .- 1) .^ 2)
        (isnan(ttpErr) | isinf(ttpErr)) ? ttpErr = 1e3 : nothing
    catch
        ttpErr = 100
    end
    # @show ttpErr

    closed = simulateSS(dt, rates, Q, -100.0)
    activationErr += mean((closed[n̅] .- 0) .^ 2)

    
    
    errors::Vector{Float64} = [
        (4 * activationErr),
        (2 * inactivationErr),
        (3 * recoveryErr),
        (2 * recoveryUDBErr),
        (1* maxPOErr),
        (4 * fallErr),
        (1 * ttpErr)
    ]
    # weights::Vector{Float64} = [
    #     4,
    #     2,
    #     3,
    #     2,
    #     1,
    #     4
    # ]
    # weightedAvg::Float64 = sum(errors::Vector{Float64})::Float64 / sum(weights::Vector{Float64})::Float64

    if returnforPlotting
        return [weightedAvg, y_activation, y_inactivation, y_recovery, y_recoveryUDB, y_MAXPO, y_TTP, y_FALL, ŷ_activation, ŷ_inactivation, ŷ_recovery, ŷ_recoveryUDB, ŷ_MAXPO, ŷ_TTP, ŷ_FALL]
    end
    
    # return [activationErr, inactivationErr, recoveryErr, recoveryUDBErr, maxPOErr,fallErr,ttpErr], [0.0], [0.0] #g and h no constraints
    return [fallErr], [0.0], [0.0] #g and h no constraints
end

function objec_parallel(X,n; extra::Bool=false)
    N = size(X,1)
    nobjectives = 1
    fx, gx, hx = zeros(N,nobjectives), zeros(N,1), zeros(N,1)
    Threads.@threads for i in 1:N
        fx[i,:], gx[i,:], hx[i,:] = consolidatedLossES(X[i,:],n)
    end
    if extra
        return fx,gx,hx
    end
    return fx
end

# bounds = BoxConstrainedSpace(lb = zeros(length(pd)), ub = 100*ones(length(pd)))

# information = Information(f_optimum = 0.0)
# options = Metaheuristics.Options(iterations = 10000, parallel_evaluation=true)
# js = Metaheuristics.optimize(x -> objec_parallel(x, [7, 1]), bounds, WOA(N=1000, options=options, information =information), logger=logger)
# @show js.best_sol
# @show consolidatedLoss(minimizer(js), [7,1 ])
# @show minimum(js)

