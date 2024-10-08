"""
abstraction of the Q matrix
"""
function Q(V::T, rates::Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64,Float64}}) where T <: Number
    function r(x::Int64, y::Int64)
        e = Edge(x,y)
        α, β, γ = rates[e]

        m, n, h = rates[Edge(999, 999)]

        # rate::Float64 = min(abs(200*γ), (max(0, 10*α + β*(V+75))))
        # rate::Float64 = max(-200*γ, (min(200*γ, (50*α+0.5*β*(V-150)))))
        
        
        # m = 3 #maximum speed of state velocity. 45 is too fast (RUDB not training well because recovery is too fast)
        # n = 120 #limit for opening state (hyperpolarized)
        # h = 30 #limit for opening state (depolarized)
        
        rate::Float64 = (min(m*γ, max(0, β*(V-((h+n)*α-n)))))^2

        # rate::Float64 = max(0, γ*tanh(α+β*V))

        return rate
    end
    
    q::Matrix{Float64} = zeros(n::Int,n::Int)

    for i::Int ∈ 1:n::Int
        for j::Int ∈ 1:n::Int
            i==j ? (q[i,j] = -sum(r(j, i)::Float64 for j in 1:n::Int if j != i)::Float64) : (q[i,j] = r(i,j))
        end
    end

    return q
end

"""
*An efficient way to simulate a step for a particular voltage*
"""
function simulateStep(dt::Float64, rates::Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64,Float64}}, Q::Function, V::S, dur::T, initial::Vector{Float64}; peak=false::Bool, halfpeak=false::Bool, time=true::Bool, debug = false::Bool) where {S, T <: Number}
    
    qv = Q(V,rates)
    (sum(isnan.(qv) + isinf.(qv)) > 0) ? (return initial) : nothing

    if debug
        try
            return expv_timestep(collect(range(start=0, stop=dur, step=1e-2)), qv, initial)
        catch
            return hcat(initial,initial)
        end
    end


    if !halfpeak
        if !peak
            try
                return expv_timestep(dur, qv, initial)
            catch
                return initial
            end
        else
            
            try
                newDt= 1e-2

                states = expv_timestep(collect(range(start=0, stop=25, step=newDt)), qv, initial)
                gatherOpens = states[n̅, :]

                inde::Int = argmax(gatherOpens)

                ind::Float64 = inde * newDt
                peakVal::Float64 = gatherOpens[inde]

                if time
                    return ind
                else
                    return peakVal
                end
            catch
                if time
                    return 99.0
                else
                    return 99.0
                end
            end
            
        end
    else
        try
            #step 1: find time to peak
            newDt::Float64 = 1e-2
            states = expv_timestep(collect(range(start=0, stop=25, step=newDt)), qv, initial)
            gatherOpens = states[n̅, :]

            peakIndex = argmax(gatherOpens)
            peakVal = gatherOpens[peakIndex]

            halfPeak = 0.50* peakVal
            halfPeakIndex = argmin(abs.(gatherOpens .- halfPeak))

            duration::Float64 = (halfPeakIndex - peakIndex) * newDt

            return duration
        catch
            return 99.0
        end
    end
end

"""
*An efficient way to compute the steady state occupancy for a particular voltage*

**simulateSS(Q, V)**

`Q ≡ Q Matrix`\n
`V ≡ Voltage to step to`\n

Returns a row vector for the probabilities in each state at steady state
"""
function simulateSS(rates::Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64,Float64}}, Q::Function, V::T) where T <: Number
    q::Matrix{Float64} = Q(V, rates)::Matrix{Float64}

    expv_timestep(500, q, [i == n̅ ? 1.0 : 0.0 for i in 1:size(q,1)])
end

"""
isValid will check to see if the Q and V pair is valid for computing inverse and matrix exponential
"""
function isValid(q, dur)
    #i guess i dont need this anymore
    return true
end

function getMNH(mNorm,nNorm,hNorm)
    maxVelo = 4.5 + (5.5 - 4.5) * mNorm
    nStart = 120 + (130 - 120) * nNorm
    hEnd = 20 + (30 - 20) * hNorm

    maxVelo, nStart, hEnd
end

#CHANGE BACK TO SVECTOR AFTER, SVector{86,Float64} and SVector{2,Int}
# function consolidatedLoss(params::Vector{Float64}, additionals::Vector{Int})::Float64
function consolidatedLoss(params::Vector{Float64}, additionals::Vector{Int64}; returnforPlotting::Bool=false)::Any
    # params= StochasticAD.value.(p)
    
    global n = additionals[1]
    # n=7
    global n̅ = additionals[2]
    dt = 1e-4
    dataPath = "res/INaHEK/"
    
    rates = Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64,Float64}}(Edge(i::Int64, j::Int64) => (0,0,0) for i in 1:n, j in 1:n if i != j for idx in (2 * (i - 1) * (n - 1) + 2 * (j - 1) + 1):(2 * (i - 1) * (n - 1) + 2 * (j - 1) + 2))
    
    idx::Int = 1
    for e in sort(collect(keys(rates)))::Vector{Graphs.SimpleGraphs.SimpleEdge}
        rates[e] = (params[idx], params[idx + 1], params[idx + 2])::Tuple{Float64,Float64,Float64}
        idx += 3
    end

    #store m,n,h
    rates[Edge(999,999)] = getMNH(params[end-2],params[end-1],params[end])

    """
    GLOBAL INITIAL STATE
    """

    initial = simulateSS(rates, Q, -100.0)


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

    steps = []
    for V::Float64 ∈ data[:,1]
        
        s4 = simulateStep(dt, rates, Q, V, 25.0, initial, peak=true, time=false)
        push!(steps, s4)
    end

    # oNormalized = []
    # o::Vector{Float64} = [steps[i][n̅] for i in 1:size(steps)[1]]
    oNormalized = steps ./ findmax(steps)[1]

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
    # initial = simulateSS(rates, Q, -100.0)

    steps = []
    for V ∈ data[:,1]
        step::Vector{Float64} = simulateStep(dt, rates, Q, V, 500.0, initial)
        s4 = simulateStep(dt, rates, Q, -10, 25.0, step, peak=true,time=false)
        push!(steps, s4)
    end

    # oNormalized = []
    # o = [steps[i][n̅] for i in 1:size(steps)[1]]
    oNormalized = steps ./ findmax(steps)[1]

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
    # initial = simulateSS(rates, Q, -100.0)

    #first pulse (depolarizing)
    step1::Vector{Float64} = simulateStep(dt, rates, Q, -10, 500.0, initial)

    steps = []
    for tDur ∈ data[:,1]
        #second pulses (hyperpolarizing)
        step2::Vector{Float64} = simulateStep(dt, rates, Q, -100, tDur, step1::Vector{Float64})
        #test pulse
        s4 = simulateStep(dt, rates, Q, -10.0, 25.0, step2::Vector{Float64}, peak=true, time=false)

        #save
        push!(steps, s4)
    end

    # oNormalized = []
    # o = [steps[i][n̅] for i in 1:size(steps)[1]::Int]
    oNormalized = steps ./ findmax(steps)[1]

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
    # initial = simulateSS(rates, Q, -100.0)

    step1 = initial
    step2 = initial
    #depolarizing pulse train
    for i ∈ 1:100
        step1= simulateStep(dt, rates, Q, -10, 25.0, step2::Vector{Float64})
        step2 = simulateStep(dt, rates, Q, -100, 15.0, step1::Vector{Float64})
        #note the math: dt=25ms in step1 + dt=15ms in step 2 is 40ms which is 25 Hz
    end

    steps = []
    for tDur ∈ data[:, 1]
        #hyperpolarizing pulse, use STEP1 NOT STEP2 (we are varying recovery duration)!!
        step3::Vector{Float64} = simulateStep(dt, rates, Q, -100, tDur, step1::Vector{Float64})
        #test pulse
        s4= simulateStep(dt, rates, Q, -10, 25.0, step3::Vector{Float64}, peak=true, time=false)

        #save
        push!(steps, s4)
    end

    # oNormalized = []
    # o = [steps[i][n̅] for i in 1:size(steps)[1]::Int]
    oNormalized = steps ./ findmax(steps)[1]

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
    y_MAXPO = vec([0.30, 0.31, 0.33])
    ŷ_MAXPO = vec([0.30, 0.31, 0.33])
    #simulate maxPO

    data = [ -20.0  0.30  0.05
        -10.0  0.31  0.05
            0.0  0.33  0.05]
    # data = [-10.0  0.31  0.05]
    initial = simulateSS(rates, Q, -100.0)
    peaks = []
    for V ∈ data[:,1]
        peak = simulateStep(dt, rates, Q, V, 100.0, initial, peak=true, time=false)

        push!(peaks, peak)
    end

    # y_MAXPO = vec([0.31 0.31 0.31])
    y_MAXPO = vec([0.30, 0.31, 0.33])
    ŷ_MAXPO = convert(Vector{Float64}, peaks)

    maxPOErr = mean((convert(Vector{Float64}, peaks) .- y_MAXPO) .^ 2)
    (isnan(maxPOErr) | isinf(maxPOErr)) ? maxPOErr = 1e3 : nothing
    # try
    #     # @show params
    #     # data = readdlm(dataPath*maxPOProtocol["source"])
    #     data = [ -20.0  0.31  0.05
    #     -10.0  0.31  0.05
    #         0.0  0.31  0.05]
    #     initial = simulateSS(rates, Q, -100.0)
    #     peaks = []
    #     for V ∈ data[:,1]
    #         peak::Float64 = simulateStep(dt, rates, Q, V, 100.0, initial, peak=true, time=false)::Float64

    #         push!(peaks, peak::Float64)
    #     end

    #     y_MAXPO = vec([0.31 0.31 0.31])
    #     ŷ_MAXPO = convert(Vector{Float64}, peaks)

    #     maxPOErr = mean((convert(Vector{Float64}, peaks) .- vec([0.31 0.31 0.31])) .^ 2)
    #     (isnan(maxPOErr) | isinf(maxPOErr)) ? maxPOErr = 1e3 : nothing
    # catch
    #     maxPOErr = 1e3
    # end
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
    data =[20.0  0.48  0.01
        15.0  0.5   0.01
        10.0  0.52  0.02
         5.0  0.55  0.02
        -5.0  0.65  0.03
       -10.0  0.73  0.03
       -15.0  0.84  0.03]
    # initial = simulateSS(rates, Q, -100.0)

    durations = []
    for V ∈ data[:,1]
        #for each voltage, we gather the time distribution of the open state
        #and isolate the peak, 50% of the peak, and determine the time between them
        duration::Float64 = simulateStep(dt, rates, Q, V, 500.0, initial, halfpeak=true)
        
        push!(durations, duration)
    end

    y_FALL = vec([0.48  0.5  0.52  0.55  0.65  0.73  0.84])
    ŷ_FALL = convert(Vector{Float64} ,durations)

    fallErr = mean((convert(Vector{Float64} ,durations) .- vec([0.48  0.5  0.52  0.55  0.65  0.73  0.84])) .^ 2)
    (isnan(fallErr) | isinf(fallErr)) ? fallErr = 1e3 : nothing
    # try
    #     # data = readdlm(dataPath*fallProtocol["source"])
    #     data =[20.0  0.48  0.01
    #     15.0  0.5   0.01
    #     10.0  0.52  0.02
    #      5.0  0.55  0.02
    #     -5.0  0.65  0.03
    #    -10.0  0.73  0.03
    #    -15.0  0.84  0.03]
    #     initial = simulateSS(rates, Q, -100.0)

    #     durations = []
    #     for V ∈ data[:,1]
    #         #for each voltage, we gather the time distribution of the open state
    #         #and isolate the peak, 50% of the peak, and determine the time between them
    #         duration::Float64 = simulateStep(dt, rates, Q, V, 500.0, initial, halfpeak=true)
            
    #         push!(durations, duration::Float64)
    #     end

    #     y_FALL = vec([0.48  0.5  0.52  0.55  0.65  0.73  0.84])
    #     ŷ_FALL = convert(Vector{Float64} ,durations)

    #     fallErr = mean((convert(Vector{Float64} ,durations) .- vec([0.48  0.5  0.52  0.55  0.65  0.73  0.84])) .^ 2)
    #     (isnan(fallErr) | isinf(fallErr)) ? fallErr = 1e3 : nothing
    # catch
    #     fallErr = 1e3
    # end
    # @show fallErr


    """
    TIME TO PEAK PROTOCOL
    """
    #initialize
    ttpErr = 1e3
    
    # initial = simulateSS(rates, Q, -100)

    y_TTP = [1]
    ŷ_TTP = [0]

    ttpS = []
    timeToPeak::Float64 = simulateStep(dt, rates, Q, -10, 500.0, initial, peak=true,time=true)::Float64
        
    ŷ_TTP = [timeToPeak]
    ttpErr = mean((timeToPeak .- 1) .^ 2)
    (isnan(ttpErr) | isinf(ttpErr)) ? ttpErr = 1e3 : nothing
    # try
    #     timeToPeak::Float64 = simulateStep(dt, rates, Q, -10, 500.0, initial, peak=true,time=true)::Float64
        
    #     ŷ_TTP = [timeToPeak]
    #     ttpErr = mean((timeToPeak .- 1) .^ 2)
    #     (isnan(ttpErr) | isinf(ttpErr)) ? ttpErr = 1e3 : nothing
    # catch
    #     ttpErr = 100
    # end
    # @show ttpErr

    # closed = simulateSS(dt, rates, Q, -100.0)
    # activationErr += mean((closed[n̅] .- 0) .^ 2)


    # """
    # edges
    # """
    # # initial = simulateSS(rates, Q, -100)
    # edgeChecks = [-65, -25, -10, 0, 10, 25, 30, 45]
    # edges = []
    # for V ∈ edgeChecks
    #     e = simulateStep(dt, rates, Q, V, 5000., initial)[n̅,:]

    #     push!(edges, e)
    # end

    # edgeError = 10 * sum( vcat(edges...))
    
    # errors::Vector{Float64} = [
    #     (4 * activationErr),
    #     (2 * inactivationErr),
    #     (2 * recoveryErr),
    #     (4 * recoveryUDBErr),
    #     (2* maxPOErr),
    #     (4 * fallErr),
    #     (1 * ttpErr)
    #     # (4*edgeError)
    # ]
    # weights::Vector{Float64} = [
    #     4,
    #     2,
    #     2,
    #     4,
    #     2,
    #     4,
    #     1
    #     # 4
    # ]
    errors::Vector{Float64} = [
        (1 * activationErr),
        (1 * inactivationErr),
        (1 * recoveryErr),
        (1 * recoveryUDBErr),
        (1* maxPOErr),
        (1 * fallErr),
        (1 * ttpErr)
        # (4*edgeError)
    ]
    weights::Vector{Float64} = [
        1,
        1,
        1,
        1,
        1,
        1,
        1
        # 4
    ]
    weightedAvg::Float64 = sum(errors::Vector{Float64})::Float64 / sum(weights::Vector{Float64})::Float64

    if returnforPlotting
        return [weightedAvg, y_activation, y_inactivation, y_recovery, y_recoveryUDB, y_MAXPO, y_TTP, y_FALL, ŷ_activation, ŷ_inactivation, ŷ_recovery, ŷ_recoveryUDB, ŷ_MAXPO, ŷ_TTP, ŷ_FALL]
    end
    
    return weightedAvg
end