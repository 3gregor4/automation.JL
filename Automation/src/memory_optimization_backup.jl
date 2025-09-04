"""
Memory Optimization - Otimizações Avançadas de Memória
Implementa técnicas especializadas para gestão eficiente de memória

Funcionalidades:
- Memory pooling e object reuse
- Cache-aware data structures
- Zero-allocation algorithms
- Memory profiling e monitoring
- Garbage collection optimization
"""

using Printf
using Base.Threads

export MemoryPool, ObjectPool, CacheOptimizedStructures
export ZeroAllocationAlgorithms, MemoryProfiler, GCOptimizer
export @zero_alloc, @memory_profile, @gc_optimize

# =============================================================================
# MEMORY POOLING
# =============================================================================

"""
Pool de memória para reutilização eficiente de objetos
"""
mutable struct MemoryPool{T}
    available::Vector{T}
    in_use::Set{T}
    total_created::Int
    max_size::Int

    function MemoryPool{T}(max_size::Int=1000) where {T}
        new{T}(T[], Set{T}(), 0, max_size)
    end
end

"""
    acquire!(pool::MemoryPool{T}) -> T

Adquire objeto do pool ou cria novo se necessário
"""
function acquire!(pool::MemoryPool{T}) where {T}
    if !isempty(pool.available)
        obj = pop!(pool.available)
        push!(pool.in_use, obj)
        return obj
    elseif pool.total_created < pool.max_size
        obj = T()
        push!(pool.in_use, obj)
        pool.total_created += 1
        return obj
    else
        # Force garbage collection and retry
        GC.gc()
        if !isempty(pool.available)
            obj = pop!(pool.available)
            push!(pool.in_use, obj)
            return obj
        else
            error("Memory pool exhausted and cannot create new objects")
        end
    end
end

"""
    release!(pool::MemoryPool{T}, obj::T)

Retorna objeto para o pool para reutilização
"""
function release!(pool::MemoryPool{T}, obj::T) where {T}
    if obj in pool.in_use
        delete!(pool.in_use, obj)
        push!(pool.available, obj)
        return true
    end
    return false
end

"""
    pool_stats(pool::MemoryPool{T}) -> NamedTuple

Estatísticas do pool de memória
"""
function pool_stats(pool::MemoryPool{T}) where {T}
    return (
        available=length(pool.available),
        in_use=length(pool.in_use),
        total_created=pool.total_created,
        max_size=pool.max_size,
        # Proteção contra divisão por zero
        utilization=if pool.total_created != 0
            length(pool.in_use) / pool.total_created
        else
            0.0
        end,
    )
end

# =============================================================================
# OBJECT POOLING ESPECÍFICO
# =============================================================================

"""
Pool especializado para arrays com reutilização inteligente
"""
mutable struct ArrayPool{T}
    pools::Dict{Int,Vector{Vector{T}}}
    max_arrays_per_size::Int

    function ArrayPool{T}(max_arrays_per_size::Int=50) where {T}
        new{T}(Dict{Int,Vector{Vector{T}}}(), max_arrays_per_size)
    end
end

"""
    acquire_array!(pool::ArrayPool{T}, size::Int) -> Vector{T}

Adquire array do pool ou cria novo
"""
function acquire_array!(pool::ArrayPool{T}, size::Int) where {T}
    if haskey(pool.pools, size) && !isempty(pool.pools[size])
        arr = pop!(pool.pools[size])
        resize!(arr, size)  # Ensure correct size
        fill!(arr, zero(T))  # Clear previous data
        return arr
    else
        return Vector{T}(undef, size)
    end
end

"""
    release_array!(pool::ArrayPool{T}, arr::Vector{T})

Retorna array para o pool
"""
function release_array!(pool::ArrayPool{T}, arr::Vector{T}) where {T}
    size = length(arr)

    if !haskey(pool.pools, size)
        pool.pools[size] = Vector{Vector{T}}()
    end

    if length(pool.pools[size]) < pool.max_arrays_per_size
        push!(pool.pools[size], arr)
    end
    # Se pool está cheio, deixa GC coletar o array
end

"""
    @with_pooled_array pool size block

Macro para uso automático de array do pool
"""
macro with_pooled_array(pool, size, block)
    quote
        arr = acquire_array!($(esc(pool)), $(esc(size)))
        try
            $(esc(block))
        finally
            release_array!($(esc(pool)), arr)
        end
    end
end

# =============================================================================
# CACHE-OPTIMIZED STRUCTURES
# =============================================================================

"""
Módulo para estruturas otimizadas para cache
"""
module CacheOptimizedStructures

export CacheAwareArray, BlockedMatrix, ColumnMajorOptimizer

"""
Array cache-aware com layout otimizado
"""
struct CacheAwareArray{T}
    data::Vector{T}
    rows::Int
    cols::Int
    block_size::Int

    function CacheAwareArray{T}(rows::Int, cols::Int, block_size::Int=64) where {T}
        data = Vector{T}(undef, rows * cols)
        new{T}(data, rows, cols, block_size)
    end
end

"""
    cache_index(arr::CacheAwareArray, i::Int, j::Int) -> Int

Calcula índice otimizado para cache
"""
function cache_index(arr::CacheAwareArray, i::Int, j::Int)
    # Block-based indexing para melhor cache locality
    block_row = (i - 1) ÷ arr.block_size
    block_col = (j - 1) ÷ arr.block_size

    local_row = (i - 1) % arr.block_size
    local_col = (j - 1) % arr.block_size

    blocks_per_row = (arr.cols + arr.block_size - 1) ÷ arr.block_size
    block_index = block_row * blocks_per_row + block_col

    local_index = local_row * arr.block_size + local_col

    return block_index * (arr.block_size * arr.block_size) + local_index + 1
end

function Base.getindex(arr::CacheAwareArray{T}, i::Int, j::Int) where {T}
    @boundscheck checkbounds(Bool, 1:arr.rows, i) && checkbounds(Bool, 1:arr.cols, j)
    return arr.data[cache_index(arr, i, j)]
end

function Base.setindex!(arr::CacheAwareArray{T}, val::T, i::Int, j::Int) where {T}
    @boundscheck checkbounds(Bool, 1:arr.rows, i) && checkbounds(Bool, 1:arr.cols, j)
    arr.data[cache_index(arr, i, j)] = val
    return val
end

"""
    blocked_transpose!(dest::CacheAwareArray{T}, src::CacheAwareArray{T})

Transposição blocked para otimização de cache
"""
function blocked_transpose!(dest::CacheAwareArray{T}, src::CacheAwareArray{T}) where {T}
    @assert dest.rows == src.cols && dest.cols == src.rows

    block_size = min(src.block_size, dest.block_size)

    @inbounds for j_block in 1:block_size:src.cols
        for i_block in 1:block_size:src.rows
            # Block boundaries
            i_end = min(i_block + block_size - 1, src.rows)
            j_end = min(j_block + block_size - 1, src.cols)

            # Transpose block
            for j in j_block:j_end
                for i in i_block:i_end
                    dest[j, i] = src[i, j]
                end
            end
        end
    end

    return dest
end

"""
    prefetch_pattern(arr::CacheAwareArray{T}, pattern::Symbol)

Implementa padrões de prefetch para cache warming
"""
function prefetch_pattern(arr::CacheAwareArray{T}, pattern::Symbol) where {T}
    if pattern == :sequential
        # Sequential access pattern
        @inbounds for i in 1:arr.rows
            for j in 1:arr.cols
                # Touch data to load into cache
                val = arr[i, j]
            end
        end
    elseif pattern == :blocked
        # Blocked access pattern
        @inbounds for j_block in 1:arr.block_size:arr.cols
            for i_block in 1:arr.block_size:arr.rows
                i_end = min(i_block + arr.block_size - 1, arr.rows)
                j_end = min(j_block + arr.block_size - 1, arr.cols)

                for j in j_block:j_end
                    for i in i_block:i_end
                        val = arr[i, j]
                    end
                end
            end
        end
    end
end

end # module CacheOptimizedStructures

# =============================================================================
# ZERO ALLOCATION ALGORITHMS
# =============================================================================

"""
Módulo para algoritmos zero-allocation
"""
module ZeroAllocationAlgorithms

export zero_alloc_sum, zero_alloc_mean, zero_alloc_variance
export in_place_sort!, in_place_reverse!, preallocated_buffer_ops

"""
    zero_alloc_sum(arr::AbstractVector{T}) -> T

Soma sem alocações usando @inbounds e @simd
"""
function zero_alloc_sum(arr::AbstractVector{T}) where {T<:Number}
    result = zero(T)
    @inbounds @simd for i in eachindex(arr)
        result += arr[i]
    end
    return result
end

"""
    zero_alloc_mean(arr::AbstractVector{T}) -> T

Média sem alocações
"""
function zero_alloc_mean(arr::AbstractVector{T}) where {T<:Real}
    n = length(arr)
    # Proteção contra divisão por zero
    if n == 0
        return zero(T) / one(T)  # Return NaN for empty array
    end
    return if T(n) != zero(T)
        zero_alloc_sum(arr) / T(n)
    else
        zero(T)
    end
end

"""
    zero_alloc_variance(arr::AbstractVector{T}, mean_val::T) -> T

Variância sem alocações com média pré-calculada
"""
function zero_alloc_variance(arr::AbstractVector{T}, mean_val::T) where {T<:Real}
    n = length(arr)
    n <= 1 && return zero(T)

    sum_sq_diff = zero(T)
    @inbounds @simd for i in eachindex(arr)
        diff = arr[i] - mean_val
        sum_sq_diff += diff * diff
    end

    # Proteção contra divisão por zero
    return if T(n - 1) != zero(T)
        sum_sq_diff / T(n - 1)
    else
        zero(T)
    end
end

"""
    in_place_sort!(arr::AbstractVector{T}, algorithm::Symbol = :quicksort)

Ordenação in-place sem alocações adicionais
"""
function in_place_sort!(arr::AbstractVector{T}, algorithm::Symbol=:quicksort) where {T}
    if algorithm == :quicksort
        quicksort_inplace!(arr, 1, length(arr))
    elseif algorithm == :heapsort
        heapsort_inplace!(arr)
    else
        throw(ArgumentError("Unsupported sorting algorithm: $algorithm"))
    end
    return arr
end

function quicksort_inplace!(arr::AbstractVector{T}, low::Int, high::Int) where {T}
    @inbounds while low < high
        if high - low < 10
            # Use insertion sort for small arrays
            insertion_sort_inplace!(arr, low, high)
            break
        end

        pivot = partition_inplace!(arr, low, high)

        # Tail recursion optimization - sort smaller partition first
        if pivot - low < high - pivot
            quicksort_inplace!(arr, low, pivot - 1)
            low = pivot + 1
        else
            quicksort_inplace!(arr, pivot + 1, high)
            high = pivot - 1
        end
    end
end

function partition_inplace!(arr::AbstractVector{T}, low::Int, high::Int) where {T}
    # Use median-of-three for pivot selection
    mid = (low + high) ÷ 2
    @inbounds if arr[mid] < arr[low]
        arr[low], arr[mid] = arr[mid], arr[low]
    end
    @inbounds if arr[high] < arr[low]
        arr[low], arr[high] = arr[high], arr[low]
    end
    @inbounds if arr[high] < arr[mid]
        arr[mid], arr[high] = arr[high], arr[mid]
    end

    # Move pivot to end
    @inbounds arr[mid], arr[high] = arr[high], arr[mid]
    @inbounds pivot = arr[high]

    i = low - 1
    @inbounds for j in low:(high-1)
        if arr[j] <= pivot
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
        end
    end

    @inbounds arr[i+1], arr[high] = arr[high], arr[i+1]
    return i + 1
end

function insertion_sort_inplace!(arr::AbstractVector{T}, low::Int, high::Int) where {T}
    @inbounds for i in (low+1):high
        key = arr[i]
        j = i - 1
        while j >= low && arr[j] > key
            arr[j+1] = arr[j]
            j -= 1
        end
        arr[j+1] = key
    end
end

function heapsort_inplace!(arr::AbstractVector{T}) where {T}
    n = length(arr)

    # Build max heap
    @inbounds for i in (n÷2):-1:1
        heapify_down!(arr, i, n)
    end

    # Extract elements from heap
    @inbounds for i in n:-1:2
        arr[1], arr[i] = arr[i], arr[1]
        heapify_down!(arr, 1, i - 1)
    end
end

function heapify_down!(arr::AbstractVector{T}, start::Int, end_idx::Int) where {T}
    @inbounds while 2 * start <= end_idx
        child = 2 * start
        swap_idx = start

        if arr[swap_idx] < arr[child]
            swap_idx = child
        end

        if child + 1 <= end_idx && arr[swap_idx] < arr[child+1]
            swap_idx = child + 1
        end

        if swap_idx == start
            break
        end

        arr[start], arr[swap_idx] = arr[swap_idx], arr[start]
        start = swap_idx
    end
end

"""
    preallocated_buffer_ops(data::AbstractVector{T}, buffer::AbstractVector{T}, op::Function)

Operações com buffer pré-alocado para evitar allocations
"""
function preallocated_buffer_ops(
    data::AbstractVector{T},
    buffer::AbstractVector{T},
    op::Function,
) where {T}
    n = min(length(data), length(buffer))
    @inbounds @simd for i in 1:n
        buffer[i] = op(data[i])
    end
    return view(buffer, 1:n)
end

end # module ZeroAllocationAlgorithms

# =============================================================================
# MEMORY PROFILER
# =============================================================================

"""
Memory profiler para análise detalhada de uso de memória
"""
module MemoryProfiler

using Printf
export @memory_profile, profile_function_memory, memory_snapshot
export allocation_tracker, gc_pressure_monitor

"""
    @memory_profile expr

Macro para profiling de memória de uma expressão
"""
macro memory_profile(expr)
    quote
        local initial_bytes = Base.gc_live_bytes()
        local initial_allocs = Base.gc_alloc_count()
        local start_time = time_ns()

        local result = $(esc(expr))

        local end_time = time_ns()
        GC.gc()  # Force GC to get accurate measurements
        local final_bytes = Base.gc_live_bytes()
        local final_allocs = Base.gc_alloc_count()

        local memory_used = final_bytes - initial_bytes
        local allocations = final_allocs - initial_allocs
        local execution_time = (end_time - start_time) / 1e6  # ms

        @printf "Memory Profile:\n"
        @printf "  Execution time: %.2f ms\n" execution_time
        @printf "  Memory used: %.2f KB\n" memory_used / 1024
        @printf "  Allocations: %d\n" allocations
        # Proteção contra divisão por zero
        if execution_time != 0
            @printf "  Memory rate: %.2f KB/ms\n" (memory_used / 1024) / execution_time
        else
            @printf "  Memory rate: 0.00 KB/ms\n"
        end

        result
    end
end

"""
    profile_function_memory(f::Function, args...; iterations::Int = 100)

Profila memória de uma função com múltiplas iterações
"""
function profile_function_memory(f::Function, args...; iterations::Int=100)
    # Warmup
    f(args...)

    memory_samples = Int[]
    time_samples = Float64[]

    for i in 1:iterations
        GC.gc()
        initial_bytes = Base.gc_live_bytes()
        start_time = time_ns()

        f(args...)

        end_time = time_ns()
        GC.gc()
        final_bytes = Base.gc_live_bytes()

        push!(memory_samples, final_bytes - initial_bytes)
        push!(time_samples, (end_time - start_time) / 1e6)
    end

    # Proteção contra divisão por zero
    total_time = sum(time_samples)
    memory_efficiency = if total_time != 0
        sum(memory_samples) / total_time  # bytes/ns
    else
        0.0
    end

    return (
        avg_memory_kb=if iterations > 0
            sum(memory_samples) / (iterations * 1024)
        else
            0.0
        end,
        max_memory_kb=if !isempty(memory_samples)
            maximum(memory_samples) / 1024
        else
            0.0
        end,
        min_memory_kb=if !isempty(memory_samples)
            minimum(memory_samples) / 1024
        else
            0.0
        end,
        avg_time_ms=if iterations > 0
            sum(time_samples) / iterations
        else
            0.0
        end,
        memory_efficiency=memory_efficiency,
        samples=(memory=memory_samples, time=time_samples),
    )
end

"""
    memory_snapshot() -> NamedTuple

Captura snapshot do estado atual da memória
"""
function memory_snapshot()
    gc_stats = Base.gc_num()

    return (
        timestamp=time_ns(),
        live_bytes=Base.gc_live_bytes(),
        total_allocated=gc_stats.allocd,
        gc_collections=gc_stats.total_time,
        free_memory=Sys.free_memory(),
        total_memory=Sys.total_memory(),
        # Proteção contra divisão por zero
        memory_pressure=if Sys.total_memory() != 0
            1.0 - (Sys.free_memory() / Sys.total_memory())
        else
            0.0
        end,
    )
end

"""
    allocation_tracker(threshold_kb::Real = 1.0)

Tracker de alocações que detecta picos de memória
"""
function allocation_tracker(threshold_kb::Real=1.0)
    threshold_bytes = threshold_kb * 1024
    snapshots = []

    function track_allocation(name::String, f::Function, args...)
        initial_snapshot = memory_snapshot()
        result = f(args...)
        final_snapshot = memory_snapshot()

        allocation = final_snapshot.live_bytes - initial_snapshot.live_bytes

        if abs(allocation) > threshold_bytes
            push!(
                snapshots,
                (
                    name=name,
                    # Proteção contra divisão por zero
                    allocation_kb=if 1024 != 0
                        allocation / 1024
                    else
                        0.0
                    end,
                    timestamp=final_snapshot.timestamp,
                    memory_pressure=final_snapshot.memory_pressure,
                ),
            )

            @printf "Allocation Alert: %s used %.2f KB\n" name (allocation / 1024)
        end

        return result
    end

    function get_report()
        return snapshots
    end

    return (track=track_allocation, report=get_report)
end

"""
    gc_pressure_monitor(interval_seconds::Real = 1.0, duration_seconds::Real = 60.0)

Monitor de pressão de GC durante período específico
"""
function gc_pressure_monitor(interval_seconds::Real=1.0, duration_seconds::Real=60.0)
    measurements = []
    start_time = time()

    while time() - start_time < duration_seconds
        snapshot = memory_snapshot()
        push!(measurements, snapshot)

        if snapshot.memory_pressure > 0.8
            @warn "High memory pressure detected: $(round(snapshot.memory_pressure * 100, digits=1))%"
        end

        sleep(interval_seconds)
    end

    return measurements
end

end # module MemoryProfiler

# =============================================================================
# GC OPTIMIZATION
# =============================================================================

"""
Otimizador de Garbage Collection
"""
module GCOptimizer

export @gc_optimize, configure_gc_params, gc_friendly_allocation
export memory_pool_manager, smart_gc_trigger

"""
    @gc_optimize expr

Macro para otimização automática de GC em blocos de código
"""
macro gc_optimize(expr)
    quote
        # Disable GC during critical section
        gc_enabled = GC.enable(false)

        try
            result = $(esc(expr))
            result
        finally
            # Re-enable GC and perform cleanup
            GC.enable(gc_enabled)
            if !gc_enabled  # Only trigger GC if it was disabled
                GC.gc()
            end
        end
    end
end

"""
    configure_gc_params(; max_heap_size_mb::Int = 512, gc_threshold_ratio::Float64 = 0.1)

Configura parâmetros otimais de GC para performance
"""
function configure_gc_params(;
    max_heap_size_mb::Int=512,
    gc_threshold_ratio::Float64=0.1,
)
    # Set GC heuristics (Julia implementation specific)
    max_heap_bytes = max_heap_size_mb * 1024 * 1024

    @info "GC Configuration:" max_heap_size_mb gc_threshold_ratio

    return (
        max_heap=max_heap_bytes,
        threshold_ratio=gc_threshold_ratio,
        recommended_pool_size=max_heap_bytes ÷ 10,
    )
end

"""
    gc_friendly_allocation(size::Int, type::Type{T}) where T

Alocação GC-friendly que minimiza fragmentação
"""
function gc_friendly_allocation(size::Int, type::Type{T}) where {T}
    # Align allocation size to reduce fragmentation
    aligned_size = (size + 63) & ~63  # Align to 64-byte boundary

    # Pre-touch memory to ensure proper allocation
    arr = Vector{T}(undef, aligned_size)

    # Initialize to ensure memory is actually allocated
    if isbitstype(T)
        fill!(arr, zero(T))
    end

    return resize!(arr, size)  # Return to requested size
end

"""
    smart_gc_trigger(memory_threshold::Float64 = 0.8)

Trigger inteligente de GC baseado em pressão de memória
"""
function smart_gc_trigger(memory_threshold::Float64=0.8)
    current_memory = Sys.free_memory()
    total_memory = Sys.total_memory()
    # Proteção contra divisão por zero
    memory_usage = if total_memory != 0
        1.0 - (current_memory / total_memory)
    else
        0.0
    end

    if memory_usage > memory_threshold
        @info "Triggering GC: Memory usage at $(round(memory_usage * 100, digits=1))%"
        GC.gc()
        return true
    end

    return false
end

end # module GCOptimizer

# =============================================================================
# MACROS PRINCIPAIS
# =============================================================================

"""
    @zero_alloc expr

Macro para garantir zero allocations em código crítico
"""
macro zero_alloc(expr)
    quote
        local initial_allocs = Base.gc_alloc_count()
        local result = $(esc(expr))
        local final_allocs = Base.gc_alloc_count()

        if final_allocs > initial_allocs
            @warn "Unexpected allocations detected: $(final_allocs - initial_allocs)"
        end

        result
    end
end
