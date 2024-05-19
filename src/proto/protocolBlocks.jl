"""
*Simulate a step to a particular voltage for a particular duration*

**simulateStep(Q, V, dur, initial)**

`Q ≡ Q Matrix`\n
`V ≡ Voltage to step to`\n
`dur ≡ Duration of step (in ms)`\n
`initial ≡ Row vector for initial state`
`all ≡ Optional parameter to get all state values`

Returns a row vector for the probabilities in each state at the end of the duration
"""
function simulateStep(Q::Function, V::S, dur::T, initial::Vector{Float64}; all=false::Bool) where {S, T <: Number}
    isValid(Q, V) ? nothing : (return initial)
    
    expQ = exponential!(Q(V)*dt)
    s = [initial]
    for (i, _) ∈ enumerate(1:1:dur)
        push!(s, expQ*s[i])
    end
    
    !all ? (return s[end]) : (return s)
end

# """
# *Simulate a short (~25ms by default) test pulse to a particular voltage*

# **testPulse(Q, state; V = -10mV, dur = 25)**

# `Q ≡ Q Matrix`\n
# `state ≡ Row vector for initial state`\n
# Optional args: `V ≡ Voltage to test at (-10mV default)`, `dur ≡ Duration of step (in ms)`

# Returns a row vector for the probabilities in each state at the end of the test pulse
# """
# function testPulse(Q::Function, state::Vector{Float64}; V::T = -10, dur::T = 25) where T <: Number
#     simulateStep(Q, V, dur, state)
# end

"""
*An efficient way to compute the steady state occupancy for a particular voltage*

**simulateSS(Q, V)**

`Q ≡ Q Matrix`\n
`V ≡ Voltage to step to`\n

Returns a row vector for the probabilities in each state at steady state
"""
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

"""
isValid will check to see if the Q and V pair is valid for computing inverse and matrix exponential
"""
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