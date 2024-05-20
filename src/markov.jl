# """MENON 6 state"""

# function updateRates!(optimizable)
#     global rates = Dict(
#         31 => (optimizable[1], optimizable[2]),
#         32 => (optimizable[3], optimizable[4]),
#         52 => (optimizable[5], optimizable[6]),
#         43 => (optimizable[7], optimizable[8]),
#         63 => (optimizable[9], optimizable[10]),
#         54 => (optimizable[11], optimizable[12]),
#         65 => (optimizable[13], optimizable[14]),
#         13 => (optimizable[15], optimizable[16]),
#         23 => (optimizable[17], optimizable[18]),
#         25 => (optimizable[19], optimizable[20]),
#         34 => (optimizable[21], optimizable[22]),
#         36 => (optimizable[23], optimizable[24]),
#         45 => (optimizable[25], optimizable[26]),
#         56 => (optimizable[27], optimizable[28]),
#         999 => (optimizable[29], optimizable[30])
#     )
# end

# function Q(V::T) where T <: Number
#     global rates
    
#     function r(i::Int64)
#         return exp(rates[i][1] + (rates[i][2] * tanh((V + rates[999][1])/rates[999][2])))
#     end
#     q = zeros(6,6)

#     q[1,:] = [-r(31), 0, r(13), 0, 0, 0]
#     q[2,:] = [0, -(r(52)+r(32)), r(23), 0, r(25), 0]
#     q[3,:] = [r(31), r(32), -(r(13)+r(23)+r(43)+r(63)), r(34), 0, r(36)]
#     q[4,:] = [0, 0, r(43), -(r(34)+r(54)), r(45), 0]
#     q[5,:] = [0, r(52), 0, r(54), -(r(25)+r(45)+r(65)), r(56)]
#     q[6,:] = [0, 0, r(63), 0, r(65), -(r(36)+r(56))]

#     return q
# end

# """
# my new 7 state
# """

# function updateRates!(optimizable)
#     global rates = Dict(
#         21 => (optimizable[1], optimizable[2]),
#         12 => (optimizable[3], optimizable[4]),
#         32 => (optimizable[5], optimizable[6]),
#         23 => (optimizable[7], optimizable[8]),
#         35 => (optimizable[9], optimizable[10]),
#         53 => (optimizable[11], optimizable[12]),
#         73 => (optimizable[13], optimizable[14]),
#         37 => (optimizable[15], optimizable[16]),
#         57 => (optimizable[17], optimizable[18]),
#         75 => (optimizable[19], optimizable[20]),
#         52 => (optimizable[21], optimizable[22]),
#         25 => (optimizable[23], optimizable[24]),
#         54 => (optimizable[25], optimizable[26]),
#         45 => (optimizable[27], optimizable[28]),
#         76 => (optimizable[29], optimizable[30]),
#         67 => (optimizable[31], optimizable[32]),
#         14 => (optimizable[33], optimizable[34]),
#         41 => (optimizable[35], optimizable[36]),
#         64 => (optimizable[37], optimizable[38]),
#         46 => (optimizable[39], optimizable[40]),
#         999 => (optimizable[41], optimizable[42])
#     )
# end

# function Q(V::T) where T <: Number
#     global rates
    
#     function r(i::Int64)
#         return exp(rates[i][1] + (rates[i][2] * tanh((V + rates[999][1])/rates[999][2])))
#     end
#     q = zeros(7,7)

#     q[1,:] = [-(r(21)+r(41)), r(12), 0, r(14), 0, 0, 0]
#     q[2,:] = [r(21), -(r(12)+r(32)+r(52)), r(23), 0, r(25), 0, 0]
#     q[3,:] = [0, r(32), -(r(23)+r(53)+r(73)), 0, r(35), 0,r(37)]
#     q[4,:] = [r(41), 0, 0, -(r(14)+r(54)+r(64)), r(45), r(46),0]
#     q[5,:] = [0, r(52), r(53), r(54), -(r(25)+r(35)+r(45)+r(75)), 0,r(57)]
#     q[6,:] = [0, 0, 0, r(64), 0, -(r(46)+r(76)), r(67)]
#     q[7,:] = [0, 0, r(73), 0, r(75), r(76), -(r(37)+r(57)+r(67))]

#     return q
# end


# """
# why dont we just let them all connect
# """

# function updateRates!(optimizable)
#     global rates = Dict(
#         21 => (optimizable[1], optimizable[2]),
#         12 => (optimizable[3], optimizable[4]),
#         32 => (optimizable[5], optimizable[6]),
#         23 => (optimizable[7], optimizable[8]),
#         43 => (optimizable[9], optimizable[10]),
#         34 => (optimizable[11], optimizable[12]),
#         54 => (optimizable[13], optimizable[14]),
#         45 => (optimizable[15], optimizable[16]),
#         65 => (optimizable[17], optimizable[18]),
#         56 => (optimizable[19], optimizable[20]),
#         76 => (optimizable[21], optimizable[22]),
#         67 => (optimizable[23], optimizable[24]),
#         17 => (optimizable[25], optimizable[26]),
#         71 => (optimizable[27], optimizable[28]),
#         27 => (optimizable[29], optimizable[30]),
#         72 => (optimizable[31], optimizable[32]),
#         37 => (optimizable[33], optimizable[34]),
#         73 => (optimizable[35], optimizable[36]),
#         47 => (optimizable[37], optimizable[38]),
#         74 => (optimizable[39], optimizable[40]),
#         57 => (optimizable[41], optimizable[42]),
#         75 => (optimizable[43], optimizable[44]),
#         61 => (optimizable[45], optimizable[46]),
#         16 => (optimizable[47], optimizable[48]),
#         62 => (optimizable[49], optimizable[50]),
#         26 => (optimizable[51], optimizable[52]),
#         63 => (optimizable[53], optimizable[54]),
#         36 => (optimizable[55], optimizable[56]),
#         64 => (optimizable[57], optimizable[58]),
#         46 => (optimizable[59], optimizable[60]),
#         51 => (optimizable[61], optimizable[62]),
#         15 => (optimizable[63], optimizable[64]),
#         52 => (optimizable[65], optimizable[66]),
#         25 => (optimizable[67], optimizable[68]),
#         53 => (optimizable[69], optimizable[70]),
#         35 => (optimizable[71], optimizable[72]),
#         41 => (optimizable[73], optimizable[74]),
#         14 => (optimizable[75], optimizable[76]),
#         42 => (optimizable[77], optimizable[78]),
#         24 => (optimizable[79], optimizable[80]),
#         31 => (optimizable[81], optimizable[82]),
#         13 => (optimizable[83], optimizable[84]),
#         999 => (optimizable[85], optimizable[86])
#     )
# end

# function rates2Params(r)
#     optimizable = zeros(Float64, 86)

#     optimizable[1] = r[21][1]
#     optimizable[2] = r[21][2]
#     optimizable[3] = r[12][1]
#     optimizable[4] = r[12][2]
#     optimizable[5] = r[32][1]
#     optimizable[6] = r[32][2]
#     optimizable[7] = r[23][1]
#     optimizable[8] = r[23][2]
#     optimizable[9] = r[43][1]
#     optimizable[10] = r[43][2]
#     optimizable[11] = r[34][1]
#     optimizable[12] = r[34][2]
#     optimizable[13] = r[54][1]
#     optimizable[14] = r[54][2]
#     optimizable[15] = r[45][1]
#     optimizable[16] = r[45][2]
#     optimizable[17] = r[65][1]
#     optimizable[18] = r[65][2]
#     optimizable[19] = r[56][1]
#     optimizable[20] = r[56][2]
#     optimizable[21] = r[76][1]
#     optimizable[22] = r[76][2]
#     optimizable[23] = r[67][1]
#     optimizable[24] = r[67][2]
#     optimizable[25] = r[17][1]
#     optimizable[26] = r[17][2]
#     optimizable[27] = r[71][1]
#     optimizable[28] = r[71][2]
#     optimizable[29] = r[27][1]
#     optimizable[30] = r[27][2]
#     optimizable[31] = r[72][1]
#     optimizable[32] = r[72][2]
#     optimizable[33] = r[37][1]
#     optimizable[34] = r[37][2]
#     optimizable[35] = r[73][1]
#     optimizable[36] = r[73][2]
#     optimizable[37] = r[47][1]
#     optimizable[38] = r[47][2]
#     optimizable[39] = r[74][1]
#     optimizable[40] = r[74][2]
#     optimizable[41] = r[57][1]
#     optimizable[42] = r[57][2]
#     optimizable[43] = r[75][1]
#     optimizable[44] = r[75][2]
#     optimizable[45] = r[61][1]
#     optimizable[46] = r[61][2]
#     optimizable[47] = r[16][1]
#     optimizable[48] = r[16][2]
#     optimizable[49] = r[62][1]
#     optimizable[50] = r[62][2]
#     optimizable[51] = r[26][1]
#     optimizable[52] = r[26][2]
#     optimizable[53] = r[63][1]
#     optimizable[54] = r[63][2]
#     optimizable[55] = r[36][1]
#     optimizable[56] = r[36][2]
#     optimizable[57] = r[64][1]
#     optimizable[58] = r[64][2]
#     optimizable[59] = r[46][1]
#     optimizable[60] = r[46][2]
#     optimizable[61] = r[51][1]
#     optimizable[62] = r[51][2]
#     optimizable[63] = r[15][1]
#     optimizable[64] = r[15][2]
#     optimizable[65] = r[52][1]
#     optimizable[66] = r[52][2]
#     optimizable[67] = r[25][1]
#     optimizable[68] = r[25][2]
#     optimizable[69] = r[53][1]
#     optimizable[70] = r[53][2]
#     optimizable[71] = r[35][1]
#     optimizable[72] = r[35][2]
#     optimizable[73] = r[41][1]
#     optimizable[74] = r[41][2]
#     optimizable[75] = r[14][1]
#     optimizable[76] = r[14][2]
#     optimizable[77] = r[42][1]
#     optimizable[78] = r[42][2]
#     optimizable[79] = r[24][1]
#     optimizable[80] = r[24][2]
#     optimizable[81] = r[31][1]
#     optimizable[82] = r[31][2]
#     optimizable[83] = r[13][1]
#     optimizable[84] = r[13][2]
#     optimizable[85] = r[999][1]
#     optimizable[86] = r[999][2]

#     return optimizable
# end

# function Q(V::T) where T <: Number
#     global rates
    
#     function r(i::Int64)
#         return exp(rates[i][1] + (rates[i][2] * tanh((V + rates[999][1])/rates[999][2])))
#     end
#     q = zeros(7,7)

#     q[1,:] = [-(r(21)+r(31)+r(41)+r(51)+r(61)+r(71)), r(12), r(13), r(14), r(15), r(16), r(17)]
#     q[2,:] = [r(21), -(r(12)+r(32)+r(42)+r(52)+r(62)+r(72)), r(23), r(24), r(25), r(26), r(27)]
#     q[3,:] = [r(31), r(32), -(r(13)+r(23)+r(43)+r(53)+r(63)+r(73)), r(34), r(35), r(36),r(37)]
#     q[4,:] = [r(41), r(42), r(43), -(r(14)+r(24)+r(34)+r(54)+r(64)+r(74)), r(45), r(46),r(47)]
#     q[5,:] = [r(51), r(52), r(53), r(54), -(r(15)+r(25)+r(35)+r(45)+r(65)+r(75)), r(56),r(57)]
#     q[6,:] = [r(61), r(62), r(63), r(64), r(65), -(r(16)+r(26)+r(36)+r(46)+r(56)+r(76)), r(67)]
#     q[7,:] = [r(71), r(72), r(73), r(74), r(75), r(76), -(r(17)+r(27)+r(37)+r(47)+r(57)+r(67))]

#     return q
# end
















# # rates = readdlm("rates.txt", ',')

# # args₁ = rates[end-1]
# # args₂ = rates[end]

# # l = Int64(0.5 * (length(rates)-2)) #gather number of each rate

# # α(i) = (0 ≤ i ≤ l) ? rates[i] : error("indexed alphas wrong")
# # β(i) = (0 ≤ i ≤ l) ? rates[i+l] : error("indexed betas wrong")

# # r(i) = exp(α(i) + (β(i) * tanh((V + args₁)/args₂)))

# # function enforceIO!(m::Matrix)
# #     for i ∈ 1:size(m)[1]
# #         curRow = m[i,:]
# #         index = findall(isnan.(curRow))
# #         s = sum(curRow[.!isnan.(curRow)])

# #         m[i, index] .= -s
# #     end
# # end

# # function Q(V::Int64)
# #     q = zeros(6,6)
# #     q[1,:] = [NaN, 0, r(3), r(4), r(5), r(6)]
# #     q[2,:] = [0, NaN, r(3), r(4), r(5), r(6)]
# #     q[3,:] = [r(1), r(2), NaN, 0, 0, r(6)]
# #     q[4,:] = [r(1), r(2), 0, NaN, r(5), r(6)]
# #     q[5,:] = [r(1), r(2), 0, r(4), NaN, 0]
# #     q[6,:] = [r(1), r(2), r(3), r(4), 0, NaN]
# #     enforceIO!(q)

# #     @show q
# # end

# # Q(20)