function consolidatedLoss(params, [n])
    function setParams!(params)
        global rates, args₁, args₂
        idx = 1
        for e in sort(collect(keys(rates)))
            rates[e] = (params[idx], params[idx + 1])
            idx += 2
        end
        args₁ = params[idx]
        args₂ = params[idx + 1]
        return
    end
    
    function Q(V::T) where T <: Number
        global rates, args₁, args₂
        
        function r(x::Int64, y::Int64)
            
            
            return rate
        end
        q = zeros(n,n)

        for i ∈ 1:n
            for j ∈ 1:n
                α, β = rates[Edge(i,j)]
                rate = min(β, max(0, ((α * V - args₁)/args₂)))

                i==j ? (q[i,j] = -sum(r(j, i) for j in 1:n if j != i)) : (q[i,j] = r(i,j))
            end
        end

        return q
    end

    function isValid(Q,V)
        q = Q(V)
    
        try
            inv(q)
        catch e
            return false
        end
    
        try
            exponential!(q*dt)
        catch e
            return false
        end
    
        return true
    end

    function simulateStep(Q::Function, V::S, dur::T, initial::Vector{Float64}; all=false::Bool) where {S, T <: Number}
        isValid(Q, V) ? nothing : (return initial)
        
        expQ = exponential!(Q(V)*dt)
        s = [initial]
        for (i, _) ∈ enumerate(1:1:dur)
            push!(s, expQ*s[i])
        end
        
        !all ? (return s[end]) : (return s)
    end
    
    function simulateSS(Q::Function, V::T) where T <: Number
        isValid(Q, V) ? nothing : (return zeros(length(Q(V)[1,:])))
        
        q = Q(V)
        q[1,:] = ones(length(q[1,:]))
        openstate = zeros(length(q[1,:]))
        openstate[1] = 1
        try
            return (inv(q)* openstate)
        catch
            return zeros(length(Q(V)[1,:]))
        end
    end

    function SSI(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen) #the range is my fallback
        data = readdlm(dataPath*protoInfo["source"])
        initial = simulateSS(Q, protoInfo["v0"])
        
    
        (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing
        steps = []
        for V ∈ range
            step = simulateStep(Q, V, protoInfo["step"][1]["dt"], initial)
            test = simulateStep(Q, protoInfo["step"][2]["vm"], protoInfo["step"][2]["dt"], step)
            push!(steps, test)
        end
    
        oNormalized = []
        if protoInfo["normalize"] == 1
            o = [steps[i][n̅] for i in 1:size(steps)[1]]
            oNormalized = o ./ findmax(o)[1]
        end
    
        return oNormalized
    end
    
    function activation(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen)
        data = readdlm(dataPath*protoInfo["source"])
        initial = simulateSS(Q, protoInfo["v0"])
    
        (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing
        steps = []
        for V ∈ range
            step = simulateStep(Q, V, protoInfo["step"][1]["dt"], initial)
            push!(steps, step)
        end
    
        oNormalized = []
        if protoInfo["normalize"] == 1
            o = [steps[i][n̅] for i in 1:size(steps)[1]]
            oNormalized = o ./ findmax(o)[1]
        end
    
        return oNormalized
    end
    
    
    function recovery(protoInfo::Dict{Any, Any}, Q::Function; trange=StepRangeLen(0,1e-6,0)::StepRangeLen)
        data = readdlm(dataPath*protoInfo["source"])
        initial = simulateSS(Q, protoInfo["v0"])
    
        (trange==StepRangeLen(0,1e-6,0)) ? trange = data[:,1] : nothing
        #first pulse (depolarizing)
        step1 = simulateStep(Q, protoInfo["step"][1]["vm"], protoInfo["step"][1]["dt"], initial)
    
        steps = []
        for tDur ∈ trange
            #second pulses (hyperpolarizing)
            step2 = simulateStep(Q, protoInfo["step"][2]["vm"], tDur, step1)
            #test pulse
            step3 = simulateStep(Q, protoInfo["step"][3]["vm"], protoInfo["step"][3]["dt"], step2)
    
            #save
            push!(steps, step3)
        end
    
        oNormalized = []
        if protoInfo["normalize"] == 1
            o = [steps[i][n̅] for i in 1:size(steps)[1]]
            oNormalized = o ./ findmax(o)[1]
        end
    
        return oNormalized
    end
    
    
    function recoveryUDB(protoInfo::Dict{Any, Any}, Q::Function; trange=StepRangeLen(0,1e-6,0)::StepRangeLen)    
        data = readdlm(dataPath*protoInfo["source"])
        initial = simulateSS(Q, protoInfo["v0"])
    
        (trange==StepRangeLen(0,1e-6,0)) ? trange = data[:,1] : nothing
    
        step2 = initial
        #depolarizing pulse train
        for i ∈ 1:100
            step1 = simulateStep(Q, protoInfo["Rstep"][1]["vm"], protoInfo["Rstep"][1]["dt"], step2)
            step2 = simulateStep(Q, protoInfo["Rstep"][2]["vm"], protoInfo["Rstep"][2]["dt"], step1)
            #note the math: dt=25ms in step1 + dt=15ms in step 2 is 40ms which is 25 Hz
        end
    
        steps = []
        for tDur ∈ trange
            #hyperpolarizing pulse
            step3 = simulateStep(Q, protoInfo["step"][1]["vm"], tDur, step2)
            #test pulse
            step4 = simulateStep(Q, protoInfo["step"][2]["vm"], protoInfo["step"][2]["dt"], step3)
    
            #save
            push!(steps, step4)
        end
    
        oNormalized = []
        if protoInfo["normalize"] == 1
            o = [steps[i][n̅] for i in 1:size(steps)[1]]
            oNormalized = o ./ findmax(o)[1]
        end
    
        return oNormalized
    end
    
    
   
    function maxpo(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen)    
        data = readdlm(dataPath*protoInfo["source"])
        initial = simulateSS(Q, protoInfo["v0"])
    
        (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing
    
        peaks = []
        try
            for V ∈ range
                gather = simulateStep(Q, V, 500, initial, all=true)
                gatherOpens = [gather[i][n̅] for i in 1:size(gather)[1]]
                peak = gatherOpens[argmax(gatherOpens)]
    
                # step = simulateStep(Q, V, protoInfo["step"][1]["dt"], initial)
                push!(peaks, peak)
            end
    
            peaks = convert(Vector{Float64}, peaks)
    
            return peaks
        catch
            return ones(length(range))
        end
    end
    
   
    function fall(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen)    
        data = readdlm(dataPath*protoInfo["source"])
        initial = simulateSS(Q, protoInfo["v0"])
    
        (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing
    
    
        durations = []
        try
            for V ∈ range
                #for each voltage, we gather the time distribution of the open state
                #and isolate the peak, 50% of the peak, and determine the time between them
                gather = simulateStep(Q, V, 500, initial, all=true)
                gatherOpens = [gather[i][n̅] for i in 1:size(gather)[1]]
                nmGatherOpens = gatherOpens ./ findmax(gatherOpens)[1]
                
                halfPeakValue = 0.50 * nmGatherOpens[argmax(nmGatherOpens)]
                halfPeakIndex = argmin(abs.(nmGatherOpens[argmax(nmGatherOpens)+1:end] .- halfPeakValue)) + argmax(nmGatherOpens)
                
                duration = (halfPeakIndex - argmax(gatherOpens))/100
                push!(durations, duration)
            end
    
            return convert(Vector{Float64} ,durations)
        catch
            return ones(length(range))
        end
    end
    
    
   
    
    
    function inacError(protoInfo::Dict{Any, Any}, params)
        y = readdlm(dataPath*protoInfo["source"])[:, 2]
        ŷ = SSI(protoInfo, Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
    
        loss = mean((ŷ .- y) .^ 2)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for Inactivation: $(loss)")
    
        return loss
    end
    
    #Activation
    function activationError(protoInfo::Dict{Any, Any}, params)
        y = readdlm(dataPath*protoInfo["source"])[:, 2]
        ŷ = activation(protoInfo, Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
    
        loss = mean((ŷ .- y) .^ 2)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for Activation: $(loss)")
    
        return loss
    end
    
    #Recovery
    function recoveryError(protoInfo::Dict{Any,Any}, params)
        y = readdlm(dataPath*protoInfo["source"])[:, 2]
        ŷ = recovery(protoInfo, Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
    
        loss = mean((ŷ .- y) .^ 2)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for Recovery: $(loss)")
    
        return loss
    end
    
    #RecoveryUDB
    function recoveryUDBError(protoInfo::Dict{Any,Any}, params)
        y = readdlm(dataPath*protoInfo["source"])[:, 2]
        ŷ = recoveryUDB(protoInfo, Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
    
        loss = mean((ŷ .- y) .^ 2)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for Recovery from UDB: $(loss)")
    
        return loss
    end
    
    #maxPO
    function maxPOError(protoInfo::Dict{Any,Any}, params)
        y = readdlm(dataPath*protoInfo["source"])[:, 2]
        ŷ = maxpo(protoInfo, Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
    
        loss = mean((ŷ .- y) .^ 2)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for maxPO: $(loss)")
    
        return loss
    end
    
    #fall
    function fall(protoInfo::Dict{Any,Any}, params)
        y = readdlm(dataPath*protoInfo["source"])[:, 2]
        ŷ = fall(protoInfo, Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
        

        loss = mean((ŷ .- y) .^ 2)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for fall: $(loss)")
    
        return loss
    end
    
    #time to peak
    function ttpeak(Q::Function)    
        initial = simulateSS(Q, -100)
    
        ttpS = []
        try
            gather = simulateStep(Q, -10, 500, initial, all=true)
            gatherOpens = [gather[i][n̅] for i in 1:size(gather)[1]]
            timeToPeak = argmax(gatherOpens)
    
            push!(ttpS, timeToPeak)
            ttpS = convert(Vector{Float64}, ttpS)
            return ttpS
        catch
            return 100
        end
    end

    function ttp()
        y = 1.0
        ŷ = ttpeak(Q)
        # δ = readdlm(dataPath*protoInfo["source"])[:, 3]
    
        loss = Flux.mse(ŷ, y)
        (isnan(loss) | isinf(loss)) ? loss = 1e2 : nothing
    
        # println("Error determined for fall: $(loss)")
    
        return loss
    end

    
    errors = [
        WTgv["weight"] * activationError(WTgv, params),
        WTinac["weight"] * inacError(WTinac, params),
        WTrecovery["weight"] * recoveryError(WTrecovery, params),
        WTRUDB["weight"] * recoveryUDBError(WTRUDB, params),
        WTmaxpo["weight"] * maxPOError(WTmaxpo, params),
        WTfall["weight"] * fall(WTfall, params),
        #1 * ttp()
    ]
    weights = [
        WTgv["weight"],
        WTinac["weight"],
        WTrecovery["weight"],
        WTRUDB["weight"],
        WTmaxpo["weight"],
        WTfall["weight"]
    ]
    weightedAvg = sum(errors) / sum(weights)

    @show return weightedAvg
end