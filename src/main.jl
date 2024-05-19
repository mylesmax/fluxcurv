# using BayesNets

# # Initialize the Bayesian Network
# bn = BayesNet()

# # Define the CPDs
# push!(bn, StaticCPD(:Vm, Normal(0, 1)))
# push!(bn, LinearGaussianCPD(:DI, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DII, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DIV, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:DIII_Inac, [:Vm], [1.0], 0.0, 1.0))
# push!(bn, LinearGaussianCPD(:Po, [:DI, :DII, :DIV, :DIII_Inac, :Vm], [1.0, 1.0, 1.0, 1.0, 1.0], 0.0, 1.0))

# plot = BayesNets.plot(bn)
# samples = rand(bn, 100)
# println(samples)

using BayesNets
using Distributions
using DataFrames
using Turing
using StatsPlots
using ExponentialUtilities

# Initialize the Bayesian Network
bn = BayesNet()

# Define the CPDs for Vm, DI, DII, DIII, DIV, Po (Pore), and I (Inactivation)
push!(bn, StaticCPD(:Vm, Normal(0, 1)))
push!(bn, LinearGaussianCPD(:DI, [:Vm], [1.0], 0.0, 1.0))
push!(bn, LinearGaussianCPD(:DII, [:Vm], [1.0], 0.0, 1.0))
push!(bn, LinearGaussianCPD(:DIII, [:Vm], [1.0], 0.0, 1.0))
push!(bn, LinearGaussianCPD(:DIV, [:Vm], [1.0], 0.0, 1.0))
push!(bn, LinearGaussianCPD(:Po, [:DI, :DII, :DIII, :DIV, :Vm], [1.0, 1.0, 1.0, 1.0, 1.0], 0.0, 1.0))
push!(bn, LinearGaussianCPD(:I, [:DIII, :DIV], [1.0, 1.0], 0.0, 1.0))

theme(:vibrant)
BayesNets.plot(bn)
