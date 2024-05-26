#Inactivation
function inacError(protoInfo::Dict{Any, Any})
    y = readdlm(dataPath*protoInfo["source"])[:, 2]
    ŷ = SSI(protoInfo, Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for Inactivation: $(loss)")

    return loss
end

#Activation
function activationError(protoInfo::Dict{Any, Any})
    y = readdlm(dataPath*protoInfo["source"])[:, 2]
    ŷ = activation(protoInfo, Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for Activation: $(loss)")

    return loss
end

#Recovery
function recoveryError(protoInfo::Dict{Any,Any})
    y = readdlm(dataPath*protoInfo["source"])[:, 2]
    ŷ = recovery(protoInfo, Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for Recovery: $(loss)")

    return loss
end

#RecoveryUDB
function recoveryUDBError(protoInfo::Dict{Any,Any})
    y = readdlm(dataPath*protoInfo["source"])[:, 2]
    ŷ = recoveryUDB(protoInfo, Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for Recovery from UDB: $(loss)")

    return loss
end

#maxPO
function maxPOError(protoInfo::Dict{Any,Any})
    y = readdlm(dataPath*protoInfo["source"])[:, 2]
    ŷ = maxpo(protoInfo, Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for maxPO: $(loss)")

    return loss
end

#fall
function fall(protoInfo::Dict{Any,Any})
    y = readdlm(dataPath*protoInfo["source"])[:, 2]
    ŷ = fall(protoInfo, Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for fall: $(loss)")

    return loss
end

#time to peak
function ttp()
    y = 1.0
    ŷ = ttpeak(Q)
    # δ = readdlm(dataPath*protoInfo["source"])[:, 3]

    loss = mean((ŷ .- y) .^ 2)
    (isnan(loss) | isinf(loss)) ? loss = 1e3 : nothing

    # println("Error determined for fall: $(loss)")

    return loss
end


function loss(params)
    setParams!(params)
    # @show [activationError(WTgv), inacError(WTinac), recoveryError(WTrecovery), recoveryUDBError(WTRUDB), maxPOError(WTmaxpo),  fall(WTfall), ttp()]
    errors = [
        WTgv["weight"] * activationError(WTgv),
        WTinac["weight"] * inacError(WTinac),
        WTrecovery["weight"] * recoveryError(WTrecovery),
        WTRUDB["weight"] * recoveryUDBError(WTRUDB),
        WTmaxpo["weight"] * maxPOError(WTmaxpo),
        WTfall["weight"] * fall(WTfall),
        1 * ttp()
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

    # (weightedAvg < 1) ? (@show weightedAvg) : nothing
    @show return weightedAvg
end

# function validate() #excludes maxpo
#     errors = [
#         WTgv_val["weight"] * activationError(WTgv_val),
#         WTinac_val["weight"] * inacError(WTinac_val),
#         WTrecovery_val["weight"] * recoveryError(WTrecovery_val),
#         WTRUDB_val["weight"] * recoveryUDBError(WTRUDB_val),
#         WTfall_val["weight"] * fall(WTfall_val)
#     ]
#     weights = [
#         WTgv_val["weight"],
#         WTinac_val["weight"],
#         WTrecovery_val["weight"],
#         WTRUDB_val["weight"],
#         WTfall_val["weight"]
#     ]
#     return sum(errors) / sum(weights)
# end