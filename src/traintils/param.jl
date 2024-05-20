function getParams()
    global rates, args₁, args₂
    params = []
    for e in sort(collect(keys(rates))) #sort for consistency
        α, β = rates[e]
        push!(params, α)
        push!(params, β)
    end
    push!(params, args₁)
    push!(params, args₂)
    return vcat(params...)
end

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
