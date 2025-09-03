"""
Green Code Optimizations Benchmark
Benchmark das otimizações implementadas para o pilar Green Code
"""

using BenchmarkTools
using Statistics
using LinearAlgebra

# Include the optimization modules
include("../src/cpu_efficiency.jl")
include("../src/memory_optimization.jl")
include("../src/algorithm_optimizations.jl")

using .CPUEfficiency
using .MemoryOptimization
using .AlgorithmOptimizations

function benchmark_green_code_optimizations()
    println("🌱 GREEN CODE OPTIMIZATIONS BENCHMARK")
    println("="^50)

    results = Dict{String,Any}()

    # 1. CPU Efficiency Optimizations
    println("\n⚡ CPU Efficiency Optimizations:")

    # Matrix multiplication benchmark
    println("   Matrix Multiplication:")
    A = rand(Float64, 150, 150)
    B = rand(Float64, 150, 150)

    opt_time = @belapsed CPUEfficiency.optimized_matrix_multiply($A, $B)
    builtin_time = @belapsed $A * $B
    matrix_speedup = builtin_time / opt_time

    results["matrix_multiplication"] = matrix_speedup
    println("     Optimized: $(round(opt_time*1000, digits=2))ms")
    println("     Builtin: $(round(builtin_time*1000, digits=2))ms")
    println("     Speedup: $(round(matrix_speedup, digits=2))x")

    # Parallel reduction benchmark
    println("   Parallel Reduction:")
    data = rand(Float64, 100000)

    opt_reduce_time = @belapsed CPUEfficiency.memory_efficient_parallel_reduce($data, +, 0.0)
    builtin_reduce_time = @belapsed reduce(+, $data)
    reduce_speedup = builtin_reduce_time / opt_reduce_time

    results["parallel_reduction"] = reduce_speedup
    println("     Optimized: $(round(opt_reduce_time*1000, digits=2))ms")
    println("     Builtin: $(round(builtin_reduce_time*1000, digits=2))ms")
    println("     Speedup: $(round(reduce_speedup, digits=2))x")

    # 2. Memory Optimization Benchmarks
    println("\n💾 Memory Optimization Benchmarks:")

    # Scalable memory pool benchmark
    println("   Scalable Memory Pool:")
    # Create a simpler test without benchmarking macro to avoid scope issues
    pool = MemoryOptimization.ScalableMemoryPool{Vector{Float64}}(10, 50, 1.5)

    # Time the pool operations
    start_time = time()
    for i in 1:100
        arr = MemoryOptimization.acquire_scalable!(pool)
        resize!(arr, 50)
        fill!(arr, Float64(i))
        _ = sum(arr)
        MemoryOptimization.release_scalable!(pool, arr)
    end
    pool_time = time() - start_time

    # Time without pool
    start_time = time()
    for i in 1:100
        arr = Vector{Float64}(undef, 50)
        fill!(arr, Float64(i))
        _ = sum(arr)
    end
    no_pool_time = time() - start_time

    # Calculate speedup (if applicable)
    pool_speedup = no_pool_time / pool_time
    results["memory_pool"] = pool_speedup
    println("     With Pool: $(round(pool_time*1000, digits=2))ms")
    println("     No Pool: $(round(no_pool_time*1000, digits=2))ms")
    println("     Speedup: $(round(pool_speedup, digits=2))x")

    # 3. Algorithm Optimization Benchmarks
    println("\n🔄 Algorithm Optimization Benchmarks:")

    # Parallel merge sort benchmark
    println("   Parallel Merge Sort:")
    sort_data = rand(Int, 50000)

    parallel_sort_time = @belapsed AlgorithmOptimizations.parallel_merge_sort!(copy($sort_data))
    builtin_sort_time = @belapsed sort!(copy($sort_data))
    sort_speedup = builtin_sort_time / parallel_sort_time

    results["parallel_merge_sort"] = sort_speedup
    println("     Parallel: $(round(parallel_sort_time*1000, digits=2))ms")
    println("     Builtin: $(round(builtin_sort_time*1000, digits=2))ms")
    println("     Speedup: $(round(sort_speedup, digits=2))x")

    # Cache optimized search benchmark
    println("   Cache Optimized Search:")
    search_data = sort(rand(Int, 10000))
    target = search_data[length(search_data)÷2]

    cache_search_time = @belapsed AlgorithmOptimizations.cache_optimized_search($search_data, $target)
    builtin_search_time = @belapsed findfirst(==($target), $search_data)

    # Handle case where findfirst might return nothing
    if builtin_search_time !== nothing
        search_speedup = builtin_search_time / cache_search_time
        results["cache_optimized_search"] = search_speedup
        println("     Cache Optimized: $(round(cache_search_time*1000, digits=2))ms")
        println("     Builtin: $(round(builtin_search_time*1000, digits=2))ms")
        println("     Speedup: $(round(search_speedup, digits=2))x")
    else
        println("     Cache Optimized: $(round(cache_search_time*1000, digits=2))ms")
        println("     Builtin: Not found")
    end

    # Summary
    println("\n📊 BENCHMARK SUMMARY:")
    valid_speedups = filter(x -> x !== nothing, collect(values(results)))
    if !isempty(valid_speedups)
        avg_speedup = mean(valid_speedups)
        println("   Average Speedup: $(round(avg_speedup, digits=2))x")

        # Estimate Green Code score improvement
        # Assuming each 2x speedup contributes ~5 points to Green Code score
        estimated_improvement = min(20.0, avg_speedup * 2.5)
        println("   Estimated Green Code Improvement: +$(round(estimated_improvement, digits=1)) points")
    else
        println("   No valid benchmarks completed")
    end

    return results
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    benchmark_green_code_optimizations()
end
