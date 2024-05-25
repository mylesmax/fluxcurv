"""
abstraction of the Q matrix
"""
function Q(V::T, rates::Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64}}, args₁::Float64, args₂::Float64) where T <: Number
    function r(x::Int64, y::Int64)
        e = Edge(x,y)
        α, β = rates[e]

        rate::Float64 = min(abs(β), max(0, ((α * V - args₁)/args₂)))
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
function simulateStep(rates::Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64}}, args₁::Float64, args₂::Float64, Q::Function, V::S, dur::T, initial::Vector{Float64}; peak=false::Bool, all=false::Bool, time=true::Bool) where {S, T <: Number}
    
    qv = Q(V,rates, args₁, args₂)

    if (!isValid(qv::Matrix{Float64}, dt::Float64)::Bool || !isValid(qv::Matrix{Float64}, dur::Float64)::Bool || !isValid(qv::Matrix{Float64}, 1)::Bool)
        if !all
            if !peak
                return initial
            else
                if time
                    return dur
                else
                    return 1e10
                end
            end
        else
            newDt = 1 #TODO:change this if needed, copy from below
            
            expQ = 
            s=[initial]
            
            for (i, _) ∈ enumerate(1:newDt:dur)
                push!(s, initial)
            end

            return s
        end
        
    end


    if !all
        if !peak
            # expQ = exponential!(qv*dt)

            return exponential!(qv::Matrix{Float64}*dur::Float64)::Matrix{Float64}*initial

            # return expQ^(length(enumerate(1:dt:dur)))*initial
        else
            newDt::Float64 = 1e-7
            #we must change dt to 1e-3 to prevent LOOOOONG wait times
            expQ = exponential!(qv::Matrix{Float64}*newDt::Float64)::Matrix{Float64}
            comp1::Float64 = 0.0
            comp2::Float64 = 2.0
            i=0
            while comp2 > comp1
                # push!(s, expQ*s[i])
                c1::Vector{Float64} = (expQ::Matrix{Float64})^(i)*initial
                c2::Vector{Float64} = (expQ::Matrix{Float64})^(i+1)*initial

                comp1 = c1[n̅]*dt
                comp2 = c2[n̅]*dt

                i += 1;
            end
            if time
                return i
            else
                return comp1
            end
        end
    else
        newDt = 1
        #we must change dt to 1e-3 to prevent LOOOOONG wait times
        expQ = exponential!(qv*newDt)
        s::Vector{Vector{Float64}}=[initial]
        
        for (i, _) ∈ enumerate(1:newDt:dur)
            push!(s, expQ::Matrix{Float64}*s[i])
        end

        return s
    end
end

"""
*An efficient way to compute the steady state occupancy for a particular voltage*

**simulateSS(Q, V)**

`Q ≡ Q Matrix`\n
`V ≡ Voltage to step to`\n

Returns a row vector for the probabilities in each state at steady state
"""
function simulateSS(rates::Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64}}, args₁::Float64, args₂::Float64, Q::Function, V::T) where T <: Number
    q::Matrix{Float64} = Q(V, rates, args₁, args₂)::Matrix{Float64}

    # isValid(q, dt) ? nothing : (return zeros(length(q[1,:])))

    
    
    #here we choose 1 as our dummy state to fill, but can be any of the states
    q[1,:] = ones(length(q[1,:]))::Vector{Float64}
    openstate::Vector{Float64} = zeros(length(q[1,:]))::Vector{Float64}
    openstate[1]::Float64 = 1

    try
        return (inv(q::Matrix{Float64})::Matrix{Float64}* openstate)
    catch
        
        return zeros(length(q[1,:]::Vector{Float64})::Int)::Vector{Float64}
    end
end

"""
isValid will check to see if the Q and V pair is valid for computing inverse and matrix exponential
"""
function isValid(q, dur)

    try
        exponential!(q*dur)
    catch e
        return false
    end

    return true
end

function consolidatedLoss(params::Vector{Float64}, additionals::Addits)
    @unpack n, n̅, dt, dataPath, protoData = additionals

    rates = Dict{Edge, Tuple{Float64, Float64}}(Edge(i, j) => (0,0) for i in 1:n, j in 1:n if i != j for idx in (2 * (i - 1) * (n - 1) + 2 * (j - 1) + 1):(2 * (i - 1) * (n - 1) + 2 * (j - 1) + 2))
    
    idx::Int = 1
    for e in sort(collect(keys(rates)))
        rates[e] = (params[idx], params[idx + 1])::Tuple{Float64,Float64}
        idx += 2
    end
    args₁ = params[idx]
    args₂ = params[idx + 1]

    """
    ACTIVATION PROTOCOL
    """
    #initialize
    activationErr = 1e3
    #TODO: get groundtruth :WTgv
    activationProtocol= (protoData::NamedTuple)[:WTgv] #TODO

    y = (readdlm(dataPath * activationProtocol["source"]::String)::Matrix{Float64})[:, 2]::Vector{Float64}
    
    #simulate activation
    data = readdlm(dataPath*activationProtocol["source"]::String)
    initial = simulateSS(rates, args₁, args₂, Q, activationProtocol["v0"]::Float64)

    steps = []
    for V ∈ data[:,1]
        
        step = simulateStep(rates, args₁, args₂, Q, V, activationProtocol["step"][1]["dt"], initial)
        push!(steps, step)
    end

    oNormalized = []
    if activationProtocol["normalize"] == 1
        o = [steps[i][n̅] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    ŷ = oNormalized

    activationErr = mean((ŷ .- y) .^ 2)

    (isnan(activationErr) | isinf(activationErr)) ? activationErr = 1e3 : nothing


    """
    INACTIVATION PROTOCOL
    """
    #initialize
    inactivationErr = 1e3
    #TODO: get groundtruth :WTinac
    inactivationProtocol = protoData[:WTinac] #TODO

    y = readdlm(dataPath * inactivationProtocol["source"])[:, 2]
    
    #simulate inactivation
    data = readdlm(dataPath*inactivationProtocol["source"])
    initial = simulateSS(rates, args₁, args₂, Q, inactivationProtocol["v0"])

    steps = []
    for V ∈ data[:,1]
        step = simulateStep(rates, args₁, args₂, Q, V, inactivationProtocol["step"][1]["dt"], initial)
        test = simulateStep(rates, args₁, args₂, Q, inactivationProtocol["step"][2]["vm"], inactivationProtocol["step"][2]["dt"], step)
        push!(steps, test)
    end

    oNormalized = []
    if inactivationProtocol["normalize"] == 1
        o = [steps[i][n̅] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    ŷ = oNormalized

    inactivationErr = mean((ŷ .- y) .^ 2)

    (isnan(inactivationErr) | isinf(inactivationErr)) ? inactivationErr = 1e3 : nothing

    """
    RECOVERY PROTOCOL
    """
    #initialize
    recoveryErr = 1e3
    #TODO: get groundtruth :WTrecovery
    recoveryProtocol = protoData[:WTrecovery] #TODO

    y = readdlm(dataPath * recoveryProtocol["source"])[:, 2]
    
    #simulate recovery
    data = readdlm(dataPath*recoveryProtocol["source"])
    initial = simulateSS(rates, args₁, args₂, Q, recoveryProtocol["v0"])

    #first pulse (depolarizing)
    step1 = simulateStep(rates, args₁, args₂, Q, recoveryProtocol["step"][1]["vm"], recoveryProtocol["step"][1]["dt"], initial)

    steps = []
    for tDur ∈ data[:,1]
        #second pulses (hyperpolarizing)
        step2 = simulateStep(rates, args₁, args₂, Q, recoveryProtocol["step"][2]["vm"], tDur, step1)
        #test pulse
        step3 = simulateStep(rates, args₁, args₂, Q, recoveryProtocol["step"][3]["vm"], recoveryProtocol["step"][3]["dt"], step2)

        #save
        push!(steps, step3)
    end

    oNormalized = []
    if recoveryProtocol["normalize"] == 1
        o = [steps[i][n̅] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    ŷ = oNormalized
    recoveryErr = mean((ŷ .- y) .^ 2)
    (isnan(recoveryErr) | isinf(recoveryErr)) ? recoveryErr = 1e3 : nothing


    """
    RECOVERY UDB PROTOCOL
    """
    #initialize
    recoveryUDBErr = 1e3
    #TODO: get groundtruth :WTRUDB
    recoveryUDBProtocol = protoData[:WTRUDB] #TODO

    y = readdlm(dataPath * recoveryUDBProtocol["source"])[:, 2]
    
    #simulate recovery UDB
    data = readdlm(dataPath*recoveryUDBProtocol["source"])
    initial = simulateSS(rates, args₁, args₂, Q, recoveryUDBProtocol["v0"])

    step2 = initial
    #depolarizing pulse train
    for i ∈ 1:100
        step1 = simulateStep(rates, args₁, args₂, Q, recoveryUDBProtocol["Rstep"][1]["vm"], recoveryUDBProtocol["Rstep"][1]["dt"], step2)
        step2 = simulateStep(rates, args₁, args₂, Q, recoveryUDBProtocol["Rstep"][2]["vm"], recoveryUDBProtocol["Rstep"][2]["dt"], step1)
        #note the math: dt=25ms in step1 + dt=15ms in step 2 is 40ms which is 25 Hz
    end

    steps = []
    for tDur ∈ data[:,1]
        #hyperpolarizing pulse
        step3 = simulateStep(rates, args₁, args₂, Q, recoveryUDBProtocol["step"][1]["vm"], tDur, step2)
        #test pulse
        step4 = simulateStep(rates, args₁, args₂, Q, recoveryUDBProtocol["step"][2]["vm"], recoveryUDBProtocol["step"][2]["dt"], step3)

        #save
        push!(steps, step4)
    end

    oNormalized = []
    if recoveryUDBProtocol["normalize"] == 1
        o = [steps[i][n̅] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    ŷ = oNormalized
    recoveryUDBErr = mean((ŷ .- y) .^ 2)
    (isnan(recoveryUDBErr) | isinf(recoveryUDBErr)) ? recoveryUDBErr = 1e3 : nothing

    """
    MAXPO PROTOCOL
    """
    #initialize
    maxPOErr = 1e3
    #TODO: get groundtruth :WTmaxpo
    maxPOProtocol = protoData[:WTmaxpo] #TODO

    y = readdlm(dataPath * maxPOProtocol["source"])[:, 2]
    
    #simulate recovery UDB
    try
        data = readdlm(dataPath*maxPOProtocol["source"])
        initial = simulateSS(rates, args₁, args₂, Q, maxPOProtocol["v0"])
        peaks = []
        for V ∈ data[:,1]
            peak = simulateStep(rates, args₁, args₂, Q, V, 100, initial, peak=true, all=false, time=false)
            # gatherOpens = [gather[i][n̅] for i in 1:size(gather)[1]]
            # peak = gatherOpens[argmax(gatherOpens)]

            # step = simulateStep(Q, V, protoInfo["step"][1]["dt"], initial)
            push!(peaks, peak)
        end
        
        ŷ  = convert(Vector{Float64}, peaks)
        maxPOErr = mean((ŷ .- y) .^ 2)
        (isnan(maxPOErr) | isinf(maxPOErr)) ? maxPOErr = 1e3 : nothing
    catch
        maxPOErr = 1e3
    end

    """
    FALL PROTOCOL
    """
    #initialize
    fallErr = 1e3
    #TODO: get groundtruth :WTfall
    fallProtocol = protoData[:WTfall] #TODO

    y = readdlm(dataPath * fallProtocol["source"])[:, 2]
    
    #simulate fall
    try
        data = readdlm(dataPath*fallProtocol["source"])
        initial = simulateSS(rates, args₁, args₂, Q, fallProtocol["v0"])

        durations = []
        for V ∈ data[:,1]
            #for each voltage, we gather the time distribution of the open state
            #and isolate the peak, 50% of the peak, and determine the time between them
            gather = simulateStep(rates, args₁, args₂, Q, V, 500, initial, all=true)
            gatherOpens = [gather[i][n̅] for i in 1:size(gather)[1]]
            nmGatherOpens = gatherOpens ./ findmax(gatherOpens)[1]
            
            halfPeakValue = 0.50 * nmGatherOpens[argmax(nmGatherOpens)]
            halfPeakIndex = argmin(abs.(nmGatherOpens[argmax(nmGatherOpens)+1:end] .- halfPeakValue)) + argmax(nmGatherOpens)
            
            duration = (halfPeakIndex - argmax(gatherOpens))/100
            push!(durations, duration)
        end

        ŷ  =  convert(Vector{Float64} ,durations)
        fallErr = mean((ŷ .- y) .^ 2)
        (isnan(fallErr) | isinf(fallErr)) ? fallErr = 1e3 : nothing
    catch
        fallErr = 1e3
    end


    """
    TIME TO PEAK PROTOCOL
    """
    #initialize
    ttpErr = 1e3
    
    initial = simulateSS(rates, args₁, args₂, Q, -100)

    ttpS = []
    try
        gather = simulateStep(rates, args₁, args₂, Q, -10, 500, initial, all=true)
        gatherOpens = [gather[i][n̅] for i in 1:size(gather)[1]]
        timeToPeak = argmax(gatherOpens) #TODO:CHANGE THIS TO THE DT OF THE SIMULATESTEP ALL=TRUE

        ŷ  = timeToPeak
        y=1

        ttpErr = mean((ŷ .- y) .^ 2)
        (isnan(ttpErr) | isinf(ttpErr)) ? ttpErr = 1e3 : nothing
    catch
        ttpErr = 100
    end

    

    
    errors = [
        protoData[:WTgv]["weight"] * activationErr,
        protoData[:WTinac]["weight"] * inactivationErr,
        protoData[:WTrecovery]["weight"] * recoveryErr,
        protoData[:WTRUDB]["weight"] * recoveryUDBErr,
        protoData[:WTmaxpo]["weight"] * maxPOErr,
        protoData[:WTfall]["weight"] * fallErr,
        1 * ttpErr
    ]
    weights = [
        protoData[:WTgv]["weight"],
        protoData[:WTinac]["weight"],
        protoData[:WTrecovery]["weight"],
        protoData[:WTRUDB]["weight"],
        protoData[:WTmaxpo]["weight"],
        protoData[:WTfall]["weight"]
    ]
    weightedAvg = sum(errors) / sum(weights)

    # (weightedAvg < 1) ? (@show weightedAvg) : nothing
    @show return weightedAvg
end