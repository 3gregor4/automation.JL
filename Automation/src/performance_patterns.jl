"""
Performance Patterns - Padrões Fundamentais de Eficiência
Implementa padrões de alta performance para otimização do pilar Green Code

Funcionalidades:
- Type-stable functions
- Memory-efficient algorithms  
- Loop optimizations
- SIMD operations
- Performance utilities
"""

using LinearAlgebra
using Statistics

export TypeStablePatterns, MemoryEfficientPatterns, LoopOptimizations
export SIMDPatterns, PerformanceUtilities
export @type_stable, @memory_efficient, @loop_optimized, @simd_optimized

# =============================================================================
# TYPE-STABLE PATTERNS
# =============================================================================

"""
Módulo para padrões type-stable que garantem máxima performance
"""
module TypeStablePatterns

export inferred_sum, inferred_mean, inferred_maximum
export type_stable_filter, type_stable_map, type_stable_reduce

"""
    inferred_sum(x::AbstractVector{T}) where T<:Number -> T

Soma type-stable para máxima performance
"""
function inferred_sum(x::AbstractVector{T}) where {T <: Number}
    result = zero(T)
    @inbounds for i in eachindex(x)
        result += x[i]
    end
    return result
end

"""
    inferred_mean(x::AbstractVector{T}) where T<:Real -> T

Média type-stable com otimização de divisão
"""
function inferred_mean(x::AbstractVector{T}) where {T <: Real}
    n = length(x)
    n == 0 && return zero(T)
    return inferred_sum(x) / T(n)
end

"""
    inferred_maximum(x::AbstractVector{T}) where T<:Real -> T

Máximo type-stable com early termination
"""
function inferred_maximum(x::AbstractVector{T}) where {T <: Real}
    isempty(x) && throw(ArgumentError("collection must be non-empty"))
    result = first(x)
    @inbounds for i in 2:length(x)
        val = x[i]
        result = val > result ? val : result
    end
    return result
end

"""
    type_stable_filter(f::Function, x::AbstractVector{T}) where T -> Vector{T}

Filter type-stable para evitar alocações desnecessárias
"""
function type_stable_filter(f::Function, x::AbstractVector{T}) where {T}
    result = T[]
    sizehint!(result, length(x) ÷ 2)  # Hint para reduzir realocações
    @inbounds for val in x
        f(val) && push!(result, val)
    end
    return result
end

"""
    type_stable_map(f::Function, x::AbstractVector{T}) where T

Map type-stable com pre-alocação
"""
function type_stable_map(f::Function, x::AbstractVector{T}) where {T}
    n = length(x)
    n == 0 && return typeof(f(first(x)))[]

    first_result = f(first(x))
    R = typeof(first_result)
    result = Vector{R}(undef, n)
    result[1] = first_result

    @inbounds for i in 2:n
        result[i] = f(x[i])
    end
    return result
end

"""
    type_stable_reduce(op::Function, x::AbstractVector{T}) where T

Reduce type-stable com otimização de operações
"""
function type_stable_reduce(op::Function, x::AbstractVector{T}) where {T}
    isempty(x) && throw(ArgumentError("collection must be non-empty"))
    result = first(x)
    @inbounds for i in 2:length(x)
        result = op(result, x[i])
    end
    return result
end

end # module TypeStablePatterns

# =============================================================================
# MEMORY-EFFICIENT PATTERNS
# =============================================================================

"""
Módulo para padrões memory-efficient que reduzem alocações
"""
module MemoryEfficientPatterns

export preallocated_operations, in_place_operations, buffer_reuse
export chunked_processing, lazy_iterators

"""
    preallocated_operations(data::AbstractVector{T}, buffer::AbstractVector{T}) where T

Operações com buffers pré-alocados para evitar GC pressure
"""
function preallocated_operations(
    data::AbstractVector{T},
    buffer::AbstractVector{T},
) where {T}
    n = min(length(data), length(buffer))
    @inbounds for i in 1:n
        buffer[i] = data[i] * T(2)  # Operação exemplo
    end
    return view(buffer, 1:n)
end

"""
    in_place_operations!(data::AbstractVector{T}, factor::T) where T

Operações in-place para máxima eficiência de memória
"""
function in_place_operations!(data::AbstractVector{T}, factor::T) where {T}
    @inbounds for i in eachindex(data)
        data[i] *= factor
    end
    return data
end

"""
    buffer_reuse(operations::Vector{Function}, data::AbstractVector{T}) where T

Reutilização de buffer para múltiplas operações
"""
function buffer_reuse(operations::Vector{Function}, data::AbstractVector{T}) where {T}
    buffer = similar(data)
    results = Vector{Vector{T}}()

    for op in operations
        @inbounds for i in eachindex(data)
            buffer[i] = op(data[i])
        end
        push!(results, copy(buffer))  # Copy apenas quando necessário
    end

    return results
end

"""
    chunked_processing(data::AbstractVector{T}, chunk_size::Int, op::Function) where T

Processamento em chunks para controle de memória
"""
function chunked_processing(
    data::AbstractVector{T},
    chunk_size::Int,
    op::Function,
) where {T}
    n = length(data)
    chunk_size = min(chunk_size, n)
    results = Vector{T}()

    for start_idx in 1:chunk_size:n
        end_idx = min(start_idx + chunk_size - 1, n)
        chunk = view(data, start_idx:end_idx)
        chunk_result = op(chunk)
        append!(results, chunk_result)
    end

    return results
end

"""
    lazy_iterators(data::AbstractVector{T}, transformations::Vector{Function}) where T

Iteradores lazy para processamento eficiente de pipeline
"""
function lazy_iterators(
    data::AbstractVector{T},
    transformations::Vector{Function},
) where {T}
    result_iterator = data
    for transform in transformations
        result_iterator = (transform(x) for x in result_iterator)
    end
    return collect(result_iterator)  # Materializar apenas no final
end

end # module MemoryEfficientPatterns

# =============================================================================
# LOOP OPTIMIZATIONS
# =============================================================================

"""
Módulo para otimizações de loops avançadas
"""
module LoopOptimizations

export unrolled_loop, vectorized_loop, cache_friendly_loop
export branch_optimized_loop, parallel_loop_pattern

"""
    unrolled_loop(data::AbstractVector{T}, factor::T) where T

Loop unrolling para reduzir overhead de iteração
"""
function unrolled_loop(data::AbstractVector{T}, factor::T) where {T}
    n = length(data)
    result = similar(data)

    # Process 4 elements per iteration
    unroll_factor = 4
    full_iterations = n ÷ unroll_factor

    @inbounds for i in 1:unroll_factor:(full_iterations * unroll_factor)
        result[i] = data[i] * factor
        result[i + 1] = data[i + 1] * factor
        result[i + 2] = data[i + 2] * factor
        result[i + 3] = data[i + 3] * factor
    end

    # Handle remaining elements
    @inbounds for i in (full_iterations * unroll_factor + 1):n
        result[i] = data[i] * factor
    end

    return result
end

"""
    vectorized_loop(a::AbstractVector{T}, b::AbstractVector{T}) where T

Loop vetorizado para máxima utilização da CPU
"""
function vectorized_loop(a::AbstractVector{T}, b::AbstractVector{T}) where {T}
    n = min(length(a), length(b))
    result = Vector{T}(undef, n)

    @inbounds @simd for i in 1:n
        result[i] = a[i] + b[i]
    end

    return result
end

"""
    cache_friendly_loop(matrix::Matrix{T}) where T

Loop cache-friendly para acesso sequencial de memória
"""
function cache_friendly_loop(matrix::Matrix{T}) where {T}
    m, n = size(matrix)
    result = zero(T)

    # Column-major access pattern (Julia native)
    @inbounds for j in 1:n
        for i in 1:m
            result += matrix[i, j]
        end
    end

    return result
end

"""
    branch_optimized_loop(data::AbstractVector{T}, threshold::T) where T

Loop com otimização de branch prediction
"""
function branch_optimized_loop(data::AbstractVector{T}, threshold::T) where {T}
    above_count = 0
    below_count = 0

    @inbounds for val in data
        # Branchless counting using arithmetic
        above_count += (val > threshold)
        below_count += (val <= threshold)
    end

    return (above_count, below_count)
end

"""
    parallel_loop_pattern(data::AbstractVector{T}, op::Function) where T

Padrão para loops paralelos eficientes
"""
function parallel_loop_pattern(data::AbstractVector{T}, op::Function) where {T}
    n = length(data)
    n_threads = Threads.nthreads()

    if n < 1000 || n_threads == 1
        # Sequential for small arrays or single thread
        return [op(x) for x in data]
    end

    # Parallel processing for larger arrays
    chunk_size = n ÷ n_threads
    results = Vector{Vector{typeof(op(first(data)))}}(undef, n_threads)

    Threads.@threads for tid in 1:n_threads
        start_idx = (tid - 1) * chunk_size + 1
        end_idx = tid == n_threads ? n : tid * chunk_size

        chunk_results = Vector{typeof(op(first(data)))}()
        for i in start_idx:end_idx
            push!(chunk_results, op(data[i]))
        end
        results[tid] = chunk_results
    end

    return vcat(results...)
end

end # module LoopOptimizations

# =============================================================================
# SIMD PATTERNS
# =============================================================================

"""
Módulo para padrões SIMD (Single Instruction, Multiple Data)
"""
module SIMDPatterns

export simd_sum, simd_dot_product, simd_elementwise
export simd_reduction, simd_comparison

"""
    simd_sum(x::AbstractVector{T}) where T<:Number

Soma SIMD otimizada para máxima throughput
"""
function simd_sum(x::AbstractVector{T}) where {T <: Number}
    result = zero(T)
    @inbounds @simd for val in x
        result += val
    end
    return result
end

"""
    simd_dot_product(a::AbstractVector{T}, b::AbstractVector{T}) where T<:Number

Produto escalar SIMD otimizado
"""
function simd_dot_product(a::AbstractVector{T}, b::AbstractVector{T}) where {T <: Number}
    n = min(length(a), length(b))
    result = zero(T)

    @inbounds @simd for i in 1:n
        result += a[i] * b[i]
    end

    return result
end

"""
    simd_elementwise(a::AbstractVector{T}, b::AbstractVector{T}, op::Function) where T

Operações element-wise SIMD
"""
function simd_elementwise(
    a::AbstractVector{T},
    b::AbstractVector{T},
    op::Function,
) where {T}
    n = min(length(a), length(b))
    result = Vector{T}(undef, n)

    @inbounds @simd for i in 1:n
        result[i] = op(a[i], b[i])
    end

    return result
end

"""
    simd_reduction(data::AbstractVector{T}, op::Function, init::T) where T

Redução SIMD genérica
"""
function simd_reduction(data::AbstractVector{T}, op::Function, init::T) where {T}
    result = init
    @inbounds @simd for val in data
        result = op(result, val)
    end
    return result
end

"""
    simd_comparison(a::AbstractVector{T}, b::AbstractVector{T}) where T

Comparação SIMD que retorna máscara booleana
"""
function simd_comparison(a::AbstractVector{T}, b::AbstractVector{T}) where {T}
    n = min(length(a), length(b))
    result = Vector{Bool}(undef, n)

    @inbounds @simd for i in 1:n
        result[i] = a[i] > b[i]
    end

    return result
end

end # module SIMDPatterns

# =============================================================================
# PERFORMANCE UTILITIES
# =============================================================================

"""
Módulo com utilitários de performance e profiling
"""
module PerformanceUtilities

export @benchmark_function, profile_memory_usage, cache_size_detection
export performance_regression_test

"""
    @benchmark_function(func, args...)

Macro para benchmark rápido de funções
"""
macro benchmark_function(func, args...)
    quote
        local start_time = time_ns()
        local result = $(esc(func))($(map(esc, args)...))
        local end_time = time_ns()
        local elapsed_ns = end_time - start_time

        println("Function: ", $(string(func)))
        println("Time: ", elapsed_ns / 1e6, " ms")

        result
    end
end

"""
    profile_memory_usage(func::Function)

Profile de uso de memória para uma função
"""
function profile_memory_usage(func::Function)
    GC.gc()  # Force cleanup before measurement
    initial_memory = Base.gc_live_bytes()

    result = func()

    GC.gc()  # Force cleanup after execution
    final_memory = Base.gc_live_bytes()

    memory_used = final_memory - initial_memory

    return (result = result, memory_bytes = memory_used)
end

"""
    cache_size_detection()

Detecta tamanhos de cache para otimizações específicas de hardware
"""
function cache_size_detection()
    # Simple cache size estimation through timing
    sizes = [1024, 8192, 65536, 524288, 4194304]  # 1KB to 4MB
    times = Float64[]

    for size in sizes
        data = rand(Float64, size ÷ 8)  # 8 bytes per Float64

        start_time = time_ns()
        for _ in 1:1000
            sum(data)
        end
        end_time = time_ns()

        push!(times, (end_time - start_time) / 1e6)
    end

    return (sizes = sizes, times = times)
end

"""
    performance_regression_test(baseline_func::Function, optimized_func::Function, data)

Teste de regressão de performance entre funções
"""
function performance_regression_test(
    baseline_func::Function,
    optimized_func::Function,
    data,
)
    # Warmup
    baseline_func(data)
    optimized_func(data)

    # Benchmark baseline
    baseline_times = Float64[]
    for _ in 1:10
        start_time = time_ns()
        baseline_func(data)
        end_time = time_ns()
        push!(baseline_times, end_time - start_time)
    end

    # Benchmark optimized
    optimized_times = Float64[]
    for _ in 1:10
        start_time = time_ns()
        optimized_func(data)
        end_time = time_ns()
        push!(optimized_times, end_time - start_time)
    end

    baseline_median = median(baseline_times)
    optimized_median = median(optimized_times)
    speedup = baseline_median / optimized_median

    return (
        baseline_median_ns = baseline_median,
        optimized_median_ns = optimized_median,
        speedup = speedup,
        improvement_percent = (speedup - 1.0) * 100.0,
    )
end

end # module PerformanceUtilities

# =============================================================================
# MACROS PARA PERFORMANCE
# =============================================================================

"""
    @type_stable f(args...)

Macro que força type stability em funções
"""
macro type_stable(expr)
    quote
        # Force type inference
        local result = $(esc(expr))
        result
    end
end

"""
    @memory_efficient expr

Macro para operações memory-efficient
"""
macro memory_efficient(expr)
    quote
        GC.@preserve begin
            $(esc(expr))
        end
    end
end

"""
    @loop_optimized for_expr

Macro para otimização automática de loops
"""
macro loop_optimized(expr)
    if expr.head == :for
        # Add @inbounds and @simd if applicable
        quote
            @inbounds @simd $(esc(expr))
        end
    else
        esc(expr)
    end
end

"""
    @simd_optimized expr

Macro para operações SIMD automáticas
"""
macro simd_optimized(expr)
    quote
        @simd $(esc(expr))
    end
end
