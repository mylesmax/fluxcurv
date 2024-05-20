using Distributed
addprocs()
using Dagger, DTables
using BlackBoxOptim

# Define the optimization function
function loss(params)
    return sum(params.^2)  # Example loss function
end

# Define a worker function that performs the optimization and returns the best parameters and loss
function optimize_worker(initial_params, duration)
    res = bboptimize(
        loss, initial_params;
        NumDimensions=length(initial_params),
        MaxTime=duration,
        SearchRange=(-17, 17),
        TraceMode=:silent,
        PopulationSize=5000,
        Method=:probabilistic_descent,
        lambda=100,
    )
    best_params = best_candidate(res)
    best_fitness = best_fitness(res)
    return (best_params=best_params, best_fitness=best_fitness)
end

# Initialize parameters
initial_params = rand(10)  # Example initial guess for parameters

# Define the number of iterations and duration for each optimization
iterations = 10  # Number of optimization cycles
duration = 20  # Time for each worker to optimize (seconds)

# Initialize the best parameters and fitness
best_params = initial_params
best_fitness = Inf
table = (a=[1, 2, 3, 4, 5], b=[6, 7, 8, 9, 10]);
DTable(table,2)
# Perform parallel optimization using Dagger.jl and DTable
for i in 1:iterations
    dt = DTable((params=best_params, fitness=best_fitness), nworkers())
    results = Dagger.@sync begin
        map(row -> optimize_worker(row.params, duration), dt)
    end
    
    # Reduce to find the best result among all workers
    best_result = reduce((x, y) -> x.best_fitness < y.best_fitness ? x : y, fetch(results))

    # Update global best parameters and fitness
    if best_result.best_fitness < best_fitness
        best_params = best_result.best_params
        best_fitness = best_result.best_fitness
    end

    println("Iteration $i: Best fitness = $best_fitness")
end

println("Final best parameters: ", best_params)
println("Final best fitness: ", best_fitness)
