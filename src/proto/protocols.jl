function SSI(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen) #the range is my fallback
    data = readdlm("INaHEK/"*protoInfo["source"])
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
        o = [steps[i][openStateIndex] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    return oNormalized
end

function activation(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen)
    data = readdlm("INaHEK/"*protoInfo["source"])
    initial = simulateSS(Q, protoInfo["v0"])

    (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing
    steps = []
    for V ∈ range
        step = simulateStep(Q, V, protoInfo["step"][1]["dt"], initial)
        push!(steps, step)
    end

    oNormalized = []
    if protoInfo["normalize"] == 1
        o = [steps[i][openStateIndex] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    return oNormalized
end

"""
RECOVERY PROTOCOL\n
***protoInfo::Dict{Any, Any}***\n
***Q ≣ Q Matrix***\n
***trange::StepRangeLen***\n
```recovery(protoInfo::Dict{Any, Any}, Q::Function; trange::StepRangeLen)```\n
*From Kate Mangold, et al.:
"Steady-state probabilities were found at -100 mV. A depolarizing pulse at -10 mV for 500 ms was applied, followed by a hyperpolarizing pulse at -100 mV ranging between 0.5–210 ms. Peak current current was then recorded and normalized after a pulse at -10 mV for 25 ms. Ito,f: Steady-state probabilities were found at -70 mV. A depolarizing pulse at 40 mV for 500 ms was applied, followed by a hyperpolarizing pulse of -70 mV of variable time intervals (2–6000 ms). Peak current was then recorded and normalized after a pulse at 40 mV for 100 ms."*
"""
function recovery(protoInfo::Dict{Any, Any}, Q::Function; trange=StepRangeLen(0,1e-6,0)::StepRangeLen)
    data = readdlm("INaHEK/"*protoInfo["source"])
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
        o = [steps[i][openStateIndex] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    return oNormalized
end

"""
RECOVERY FROM USE DEPENDENT BLOCK PROTOCOL\n
***protoInfo::Dict{Any, Any}***\n
***Q ≣ Q Matrix***\n
***trange::StepRangeLen***\n
```recoveryUDB(protoInfo::Dict{Any, Any}, Q::Function; trange::StepRangeLen)```\n
*From Kate Mangold, et al.:
"Steady-state probabilities were found at -100 mV. A pulse train of a depolarization at -10 mV for 25 ms at 25 Hz was repeated for 100 pulses. A hyperpolarizing pulse at -100 mV for variable recovery intervals was applied for between 0.5–9000 ms. A test pulse followed at -10 mV for 25 ms and peak current was normalized to the maximum."*
"""
function recoveryUDB(protoInfo::Dict{Any, Any}, Q::Function; trange=StepRangeLen(0,1e-6,0)::StepRangeLen)    
    data = readdlm("INaHEK/"*protoInfo["source"])
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
        o = [steps[i][openStateIndex] for i in 1:size(steps)[1]]
        oNormalized = o ./ findmax(o)[1]
    end

    return oNormalized
end


"""
MAXIMUM OPEN PROBABILITY\n
***protoInfo::Dict{Any, Any}***\n
***Q ≣ Q Matrix***\n
***range::StepRangeLen***\n
```maxpo(protoInfo::Dict{Any, Any}, Q::Function; range::StepRangeLen)```\n
*From Kate Mangold, et al.:
"To constrain open probabilities, maximum open probabilities of 0.27, 0.31, 0.29 at -20, -10, 0 mV, respectively (calculated from ten Tusscher 2006[52] solved in MATLAB with ode15s) were enforced."*
"""
function maxpo(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen)    
    data = readdlm("INaHEK/"*protoInfo["source"])
    initial = simulateSS(Q, protoInfo["v0"])

    (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing

    peaks = []
    try
        for V ∈ range
            gather = simulateStep(Q, V, 500, initial, all=true)
            gatherOpens = [gather[i][openStateIndex] for i in 1:size(gather)[1]]
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

"""
TAU INACTIVATION PROTOCOL\n
***protoInfo::Dict{Any, Any}***\n
***Q ≣ Q Matrix***\n
***range::StepRangeLen***\n
```fall(protoInfo::Dict{Any, Any}, Q::Function; range::StepRangeLen)```\n
*From Kate Mangold, et al.:
"Steady-state probabilities were found at -100 mV. For voltages between -20 to 20 mV in 5 mV increments, the time to 50% decay of peak current was recorded."*
"""
function fall(protoInfo::Dict{Any, Any}, Q::Function; range=StepRangeLen(0,1e-6,0)::StepRangeLen)    
    data = readdlm("INaHEK/"*protoInfo["source"])
    initial = simulateSS(Q, protoInfo["v0"])

    (range==StepRangeLen(0,1e-6,0)) ? range = data[:,1] : nothing


    durations = []
    try
        for V ∈ range
            #for each voltage, we gather the time distribution of the open state
            #and isolate the peak, 50% of the peak, and determine the time between them
            gather = simulateStep(Q, V, 500, initial, all=true)
            gatherOpens = [gather[i][openStateIndex] for i in 1:size(gather)[1]]
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

"""
time to peak
constrain to 1ms
"""
function ttpeak(Q::Function)    
    initial = simulateSS(Q, -100)

    ttpS = []
    try
        gather = simulateStep(Q, -10, 500, initial, all=true)
        gatherOpens = [gather[i][openStateIndex] for i in 1:size(gather)[1]]
        timeToPeak = argmax(gatherOpens)

        push!(ttpS, timeToPeak)
        ttpS = convert(Vector{Float64}, ttpS)
        return ttpS
    catch
        return 100
    end
end