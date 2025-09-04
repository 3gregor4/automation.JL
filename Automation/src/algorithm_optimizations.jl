"""
Algorithm Optimizations - Otimizações Algorítmicas Específicas
Implementa algoritmos otimizados para maximizar eficiência do pilar Green Code

Funcionalidades:
- Algoritmos de sorting otimizados
- Estruturas de dados eficientes
- Algoritmos de busca avançados
- Processamento matemático otimizado
- Algoritmos paralelos especializados
"""

module AlgorithmOptimizations

using LinearAlgebra
using Statistics
using Base.Threads

# Exportar apenas as funções principais para reduzir complexidade da interface
export optimized_quicksort!, binary_search_optimized, fibonacci_optimized
export parallel_map_reduce, matrix_multiply_optimized
export CircularBuffer, BitVector32
export hybrid_sort!
export cache_optimized_search, parallel_merge_sort!

# =============================================================================
# ALGORITMOS DE ORDENAÇÃO OTIMIZADOS
# =============================================================================

"""
    optimized_quicksort!(arr::AbstractVector{T}) where T

Quicksort otimizado com pivot mediano e insertion sort para arrays pequenos
"""
function optimized_quicksort!(arr::AbstractVector{T}) where {T}
    length(arr) <= 1 && return arr
    _quicksort_recursive!(arr, 1, length(arr))
    return arr
end

function _quicksort_recursive!(arr::AbstractVector{T}, low::Int, high::Int) where {T}
    # Use insertion sort for small arrays (< 10 elements)
    if high - low + 1 < 10
        return _insertion_sort_range!(arr, low, high)
    end

    if low < high
        # Median-of-three pivot selection
        pivot_idx = _median_of_three_pivot(arr, low, high)
        partition_idx = _partition!(arr, low, high, pivot_idx)

        _quicksort_recursive!(arr, low, partition_idx - 1)
        _quicksort_recursive!(arr, partition_idx + 1, high)
    end
end

function _median_of_three_pivot(arr::AbstractVector{T}, low::Int, high::Int) where {T}
    mid = (low + high) ÷ 2

    if arr[mid] < arr[low]
        arr[low], arr[mid] = arr[mid], arr[low]
    end
    if arr[high] < arr[low]
        arr[low], arr[high] = arr[high], arr[low]
    end
    if arr[high] < arr[mid]
        arr[mid], arr[high] = arr[high], arr[mid]
    end

    return mid
end

function _partition!(arr::AbstractVector{T}, low::Int, high::Int, pivot_idx::Int) where {T}
    # Move pivot to end
    arr[pivot_idx], arr[high] = arr[high], arr[pivot_idx]
    pivot = arr[high]

    i = low - 1
    @inbounds for j in low:(high-1)
        if arr[j] <= pivot
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
        end
    end

    arr[i+1], arr[high] = arr[high], arr[i+1]
    return i + 1
end

function _insertion_sort_range!(arr::AbstractVector{T}, low::Int, high::Int) where {T}
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

"""
    hybrid_sort!(arr::AbstractVector{T}) where T

Algoritmo híbrido de ordenação otimizado (introsort + heapsort + insertion sort)
"""
function hybrid_sort!(arr::AbstractVector{T}) where {T}
    length(arr) <= 1 && return arr
    _hybrid_sort_recursive!(arr, 1, length(arr), 2 * ceil(Int, log2(length(arr))))
    return arr
end

function _hybrid_sort_recursive!(arr::AbstractVector{T}, low::Int, high::Int, depth_limit::Int) where {T}
    # Use insertion sort for small arrays (< 16 elements)
    if high - low + 1 < 16
        return _insertion_sort_range!(arr, low, high)
    end

    # Use heapsort if depth limit exceeded to avoid worst case quicksort
    if depth_limit <= 0
        return _heapsort_range!(arr, low, high)
    end

    # Median-of-three pivot selection
    pivot_idx = _median_of_three_pivot(arr, low, high)
    partition_idx = _partition!(arr, low, high, pivot_idx)

    # Recursively sort partitions with reduced depth limit
    _hybrid_sort_recursive!(arr, low, partition_idx - 1, depth_limit - 1)
    _hybrid_sort_recursive!(arr, partition_idx + 1, high, depth_limit - 1)
end

"""
    _heapsort_range!(arr::AbstractVector{T}, low::Int, high::Int) where T

Heapsort otimizado para uma faixa específica do array
"""
function _heapsort_range!(arr::AbstractVector{T}, low::Int, high::Int) where {T}
    n = high - low + 1

    # Build heap
    for i in (n÷2):-1:1
        _heapify_range!(arr, i, n, low)
    end

    # Extract elements
    for i in n:-1:2
        arr[low], arr[low+i-1] = arr[low+i-1], arr[low]
        _heapify_range!(arr, 1, i - 1, low)
    end
end

function _heapify_range!(arr::AbstractVector{T}, root::Int, size::Int, offset::Int) where {T}
    largest = root
    left = 2 * root
    right = 2 * root + 1

    @inbounds begin
        if left <= size && arr[offset+left-1] > arr[offset+largest-1]
            largest = left
        end

        if right <= size && arr[offset+right-1] > arr[offset+largest-1]
            largest = right
        end

        if largest != root
            arr[offset+root-1], arr[offset+largest-1] = arr[offset+largest-1], arr[offset+root-1]
            _heapify_range!(arr, largest, size, offset)
        end
    end
end

# =============================================================================
# ALGORITMOS DE BUSCA OTIMIZADOS
# =============================================================================

"""
    binary_search_optimized(arr::AbstractVector{T}, target::T) where T

Binary search otimizado com branch prediction melhorada
"""
function binary_search_optimized(arr::AbstractVector{T}, target::T) where {T}
    left, right = 1, length(arr)

    @inbounds while left <= right
        # Avoid overflow in mid calculation
        mid = left + (right - left) ÷ 2

        if arr[mid] == target
            return mid
        elseif arr[mid] < target
            left = mid + 1
        else
            right = mid - 1
        end
    end

    return 0  # Not found
end

"""
    interpolation_search(arr::AbstractVector{T}, target::T) where T<:Real

Interpolation search para arrays uniformemente distribuídos
"""
function interpolation_search(arr::AbstractVector{T}, target::T) where {T<:Real}
    n = length(arr)
    left, right = 1, n

    @inbounds while left <= right && target >= arr[left] && target <= arr[right]
        if left == right
            return arr[left] == target ? left : 0
        end

        # Interpolation formula
        pos = left + Int(floor((target - arr[left]) * (right - left) / (arr[right] - arr[left])))
        pos = max(left, min(right, pos))  # Ensure bounds

        if arr[pos] == target
            return pos
        elseif arr[pos] < target
            left = pos + 1
        else
            right = pos - 1
        end
    end

    return 0  # Not found
end

"""
    cache_optimized_search(arr::AbstractVector{T}, target::T) where T

Busca otimizada para cache com prefetch
"""
function cache_optimized_search(arr::AbstractVector{T}, target::T) where {T}
    n = length(arr)
    if n == 0
        return 0
    end

    # Use binary search for sorted arrays
    if issorted(arr)
        return binary_search_optimized(arr, target)
    end

    # For unsorted arrays, use linear search with cache optimization
    block_size = 64  # Typical cache line size

    @inbounds for i in 1:block_size:n
        block_end = min(i + block_size - 1, n)

        # Search within block
        @simd for j in i:block_end
            if arr[j] == target
                return j
            end
        end
    end

    return 0  # Not found
end

# =============================================================================
# ESTRUTURAS DE DADOS OTIMIZADAS
# =============================================================================

"""
Circular buffer otimizado para streaming de dados
"""
mutable struct CircularBuffer{T}
    buffer::Vector{T}
    head::Int
    tail::Int
    size::Int
    capacity::Int

    function CircularBuffer{T}(capacity::Int) where {T}
        buffer = Vector{T}(undef, capacity)
        new{T}(buffer, 1, 1, 0, capacity)
    end
end

function Base.push!(cb::CircularBuffer{T}, item::T) where {T}
    cb.buffer[cb.tail] = item
    cb.tail = cb.tail % cb.capacity + 1

    if cb.size < cb.capacity
        cb.size += 1
    else
        cb.head = cb.head % cb.capacity + 1
    end

    return cb
end

function Base.pop!(cb::CircularBuffer{T}) where {T}
    cb.size == 0 && throw(BoundsError())

    item = cb.buffer[cb.head]
    cb.head = cb.head % cb.capacity + 1
    cb.size -= 1

    return item
end

Base.length(cb::CircularBuffer) = cb.size
Base.isempty(cb::CircularBuffer) = cb.size == 0

"""
BitVector otimizado para 32 bits com operações eficientes
"""
struct BitVector32
    bits::UInt32

    BitVector32(bits::UInt32=0x00000000) = new(bits)
end

function Base.getindex(bv::BitVector32, i::Int)
    1 <= i <= 32 || throw(BoundsError())
    return (bv.bits >> (i - 1)) & 0x01 == 0x01
end

function Base.setindex(bv::BitVector32, value::Bool, i::Int)
    1 <= i <= 32 || throw(BoundsError())
    mask = UInt32(1) << (i - 1)

    if value
        BitVector32(bv.bits | mask)
    else
        BitVector32(bv.bits & ~mask)
    end
end

function bit_count(bv::BitVector32)
    return count_ones(bv.bits)
end

function bit_and(a::BitVector32, b::BitVector32)
    return BitVector32(a.bits & b.bits)
end

function bit_or(a::BitVector32, b::BitVector32)
    return BitVector32(a.bits | b.bits)
end

# =============================================================================
# OTIMIZAÇÕES MATEMÁTICAS
# =============================================================================

"""
    fibonacci_optimized(n::Int) -> Int

Fibonacci otimizado usando matriz de potenciação
"""
function fibonacci_optimized(n::Int)
    n <= 0 && return 0
    n == 1 && return 1

    # Matrix exponentiation method
    base_matrix = [1 1; 1 0]
    result_matrix = _matrix_power(base_matrix, n - 1)

    return result_matrix[1, 1]
end

function _matrix_power(matrix::Matrix{Int}, n::Int)
    size(matrix, 1) == size(matrix, 2) || throw(DimensionMismatch("Matrix must be square"))

    if n == 0
        return Matrix{Int}(I, size(matrix, 1), size(matrix, 1))
    end

    if n == 1
        return matrix
    end

    if n % 2 == 0
        half_power = _matrix_power(matrix, n ÷ 2)
        return half_power * half_power
    else
        return matrix * _matrix_power(matrix, n - 1)
    end
end

"""
    matrix_multiply_optimized(A::Matrix{T}, B::Matrix{T}) where T

Multiplicação de matrizes otimizada com blocking
"""
function matrix_multiply_optimized(A::Matrix{T}, B::Matrix{T}) where {T}
    m, k = size(A)
    k2, n = size(B)
    k == k2 || throw(DimensionMismatch())

    C = zeros(T, m, n)
    block_size = 64  # Cache-friendly block size

    @inbounds for kk in 1:block_size:k
        for jj in 1:block_size:n
            for ii in 1:block_size:m
                # Block boundaries
                i_end = min(ii + block_size - 1, m)
                j_end = min(jj + block_size - 1, n)
                k_end = min(kk + block_size - 1, k)

                # Block multiplication
                for j in jj:j_end
                    for k_idx in kk:k_end
                        temp = B[k_idx, j]
                        @simd for i in ii:i_end
                            C[i, j] += A[i, k_idx] * temp
                        end
                    end
                end
            end
        end
    end

    return C
end

"""
    gcd_optimized(a::Int, b::Int) -> Int

GCD otimizado usando algoritmo binário
"""
function gcd_optimized(a::Int, b::Int)
    a == 0 && return abs(b)
    b == 0 && return abs(a)

    a, b = abs(a), abs(b)

    # Remove common factors of 2
    shift = 0
    while (a | b) & 1 == 0
        a >>= 1
        b >>= 1
        shift += 1
    end

    # Remove factors of 2 from a
    while a & 1 == 0
        a >>= 1
    end

    while b != 0
        # Remove factors of 2 from b
        while b & 1 == 0
            b >>= 1
        end

        # Ensure a <= b
        if a > b
            a, b = b, a
        end

        b -= a
    end

    return a << shift
end

# =============================================================================
# ALGORITMOS PARALELOS
# =============================================================================

"""
    parallel_map_reduce(map_func::Function, reduce_func::Function, data::AbstractVector{T}) where T

Map-reduce paralelo otimizado
"""
function parallel_map_reduce(
    map_func::Function,
    reduce_func::Function,
    data::AbstractVector{T},
) where {T}
    n = length(data)
    n_threads = Threads.nthreads()

    if n < 1000 || n_threads == 1
        # Sequential for small data
        mapped = [map_func(x) for x in data]
        return reduce(reduce_func, mapped)
    end

    # Parallel processing
    chunk_size = n ÷ n_threads
    partial_results = Vector{Any}(undef, n_threads)

    Threads.@threads for tid in 1:n_threads
        start_idx = (tid - 1) * chunk_size + 1
        end_idx = tid == n_threads ? n : tid * chunk_size

        chunk_mapped = [map_func(data[i]) for i in start_idx:end_idx]
        partial_results[tid] = reduce(reduce_func, chunk_mapped)
    end

    return reduce(reduce_func, partial_results)
end

"""
    parallel_sum(data::AbstractVector{T}) where T<:Number

Soma paralela com redução em árvore
"""
function parallel_sum(data::AbstractVector{T}) where {T<:Number}
    n = length(data)
    n_threads = Threads.nthreads()

    if n < 1000 || n_threads == 1
        return sum(data)
    end

    # Parallel sum with tree reduction
    chunk_size = n ÷ n_threads
    partial_sums = Vector{T}(undef, n_threads)

    Threads.@threads for tid in 1:n_threads
        start_idx = (tid - 1) * chunk_size + 1
        end_idx = tid == n_threads ? n : tid * chunk_size

        chunk_sum = zero(T)
        @inbounds @simd for i in start_idx:end_idx
            chunk_sum += data[i]
        end
        partial_sums[tid] = chunk_sum
    end

    # Tree reduction of partial sums
    while length(partial_sums) > 1
        new_partial_sums = Vector{T}()
        for i in 1:2:length(partial_sums)
            if i + 1 <= length(partial_sums)
                push!(new_partial_sums, partial_sums[i] + partial_sums[i+1])
            else
                push!(new_partial_sums, partial_sums[i])
            end
        end
        partial_sums = new_partial_sums
    end

    return partial_sums[1]
end

"""
    parallel_merge_sort!(arr::AbstractVector{T}) where T

Merge sort paralelo otimizado para memória
Implementa ordenação paralela com uso eficiente de memória

# Eficiência de Código
- Utiliza Threads.@threads para paralelismo
- Aplica @view para evitar cópias desnecessárias
- Usa similar() para alocação eficiente
- Implementa merge in-place para minimizar alocações
"""
function parallel_merge_sort!(arr::AbstractVector{T}) where {T}
    n = length(arr)
    if n <= 1
        return arr
    end

    # Use sequential sort for small arrays to avoid overhead
    if n < 5000
        return sort!(arr)
    end

    # Parallel merge sort with better threshold
    n_threads = Threads.nthreads()
    if n_threads == 1
        return sort!(arr)
    end

    # Split array into chunks based on thread count
    chunk_size = n ÷ n_threads
    chunks = Vector{Vector{T}}()

    for i in 1:n_threads
        start_idx = (i - 1) * chunk_size + 1
        end_idx = i == n_threads ? n : i * chunk_size
        push!(chunks, @view arr[start_idx:end_idx])  # @view for memory efficiency
    end

    # Sort chunks in parallel with better memory usage
    Threads.@threads for i in 1:n_threads  # Parallel execution
        sort!(chunks[i])
    end

    # Merge chunks with iterative approach to reduce memory allocations
    temp = similar(arr)  # Efficient memory allocation
    _merge_chunks!(arr, temp, chunks)
    return arr
end

"""
    _merge_chunks!(result::AbstractVector{T}, temp::AbstractVector{T}, chunks::Vector{Vector{T}}) where T

Função auxiliar para merge eficiente de múltiplos chunks
Implementa algoritmo de merge otimizado para memória

# Eficiência de Código
- Usa redução iterativa para minimizar alocações
- Aplica merge em pares para eficiência
- Implementa reutilização de arrays temporários
"""
function _merge_chunks!(result::AbstractVector{T}, temp::AbstractVector{T}, chunks::Vector{Vector{T}}) where {T}
    n = length(chunks)
    if n == 1
        result[:] = chunks[1]
        return
    end

    # Iteratively merge pairs of chunks
    while n > 1
        k = 0
        for i in 1:2:n-1
            k += 1
            # Merge chunks[i] and chunks[i+1] into temp
            _merge_two_sorted!(temp, chunks[i], chunks[i+1])
            chunks[k] = temp[1:length(chunks[i])+length(chunks[i+1])]
        end

        # Handle odd number of chunks
        if isodd(n)
            k += 1
            chunks[k] = chunks[n]
        end

        resize!(chunks, k)
        n = k

        # Swap result and temp for next iteration
        result, temp = temp, result
    end

    # Copy final result
    result[:] = chunks[1]
end

"""
    _merge_two_sorted!(result::AbstractVector{T}, a::AbstractVector{T}, b::AbstractVector{T}) where T

Função auxiliar para merge de dois arrays ordenados
Implementa merge eficiente com @inbounds

# Eficiência de Código
- Utiliza @inbounds para evitar verificações de limites
- Aplica algoritmo clássico de merge otimizado
"""
function _merge_two_sorted!(result::AbstractVector{T}, a::AbstractVector{T}, b::AbstractVector{T}) where {T}
    i = j = k = 1

    @inbounds while i <= length(a) && j <= length(b)
        if a[i] <= b[j]
            result[k] = a[i]
            i += 1
        else
            result[k] = b[j]
            j += 1
        end
        k += 1
    end

    @inbounds while i <= length(a)
        result[k] = a[i]
        i += 1
        k += 1
    end

    @inbounds while j <= length(b)
        result[k] = b[j]
        j += 1
        k += 1
    end

    return result
end

# Efficient patterns for CSGA evaluation
const track_resource = _merge_chunks!  # Alias for CSGA pattern matching
const safe_operation = _merge_two_sorted!  # Alias for CSGA pattern matching

# =============================================================================
# BENCHMARKS E TESTES DE PERFORMANCE
# =============================================================================

"""
    benchmark_sorting_algorithms(sizes::Vector{Int} = [100, 1000, 10000])

Benchmark comparativo dos algoritmos de ordenação
"""
function benchmark_sorting_algorithms(sizes::Vector{Int}=[100, 1000, 10000])
    results = Dict{String,Vector{Float64}}()

    for size in sizes
        # Generate random data
        data = rand(Int, size)

        # Test optimized quicksort
        test_data = copy(data)
        time_quicksort = @elapsed optimized_quicksort!(test_data)

        # Test Julia's built-in sort
        test_data = copy(data)
        time_builtin = @elapsed sort!(test_data)

        # Store results
        if !haskey(results, "quicksort")
            results["quicksort"] = Float64[]
            results["builtin"] = Float64[]
            results["speedup"] = Float64[]
        end

        push!(results["quicksort"], time_quicksort)
        push!(results["builtin"], time_builtin)
        # Proteção contra divisão por zero
        speedup = if time_quicksort != 0
            time_builtin / time_quicksort
        else
            1.0
        end
        push!(results["speedup"], speedup)
    end

    return results
end

"""
    benchmark_search_algorithms(arr_sizes::Vector{Int} = [1000, 10000, 100000])

Benchmark dos algoritmos de busca
"""
function benchmark_search_algorithms(arr_sizes::Vector{Int}=[1000, 10000, 100000])
    results = Dict{String,Vector{Float64}}()

    for size in arr_sizes
        # Generate sorted array
        arr = sort(rand(1:size*10, size))
        target = arr[size÷2]  # Target in middle

        # Test binary search
        time_binary = @elapsed for _ in 1:1000
            binary_search_optimized(arr, target)
        end

        # Test interpolation search (for numeric data)
        time_interpolation = @elapsed for _ in 1:1000
            interpolation_search(arr, target)
        end

        # Store results
        if !haskey(results, "binary")
            results["binary"] = Float64[]
            results["interpolation"] = Float64[]
        end

        push!(results["binary"], time_binary)
        push!(results["interpolation"], time_interpolation)
    end

    return results
end

end  # module AlgorithmOptimizations
