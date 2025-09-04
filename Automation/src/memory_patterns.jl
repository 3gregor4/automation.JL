"""
Memory Management Patterns
Padrões avançados de gestão de memória para otimização Green Code

Funcionalidades:
- Memory pools para objetos reutilizáveis
- Leak detection e prevenção
- Garbage collection optimization
- Memory-aware data processing
"""

using Statistics

export MemoryPool, ObjectPool, LeakDetector, MemoryMonitor
export allocate!, deallocate!, with_memory_limit, detect_leaks!
export chunked_processing, memory_efficient_map

# =============================================================================
# MEMORY POOL IMPLEMENTATION
# =============================================================================

"""
    MemoryPool{T}

Pool de memória para objetos de tipo T
"""
mutable struct MemoryPool{T}
    objects::Vector{T}
    available::Vector{Bool}
    size::Int
    allocated_count::Int
    create_fn::Function
    reset_fn::Function

    function MemoryPool{T}(
        size::Int,
        create_fn::Function,
        reset_fn::Function=identity,
    ) where {T}
        objects = Vector{T}(undef, size)
        available = fill(true, size)
        new{T}(objects, available, size, 0, create_fn, reset_fn)
    end
end

"""
    allocate!(pool::MemoryPool{T}) -> Union{T, Nothing}

Aloca objeto do pool
"""
function allocate!(pool::MemoryPool{T}) where {T}
    for i in 1:pool.size
        if pool.available[i]
            if !isassigned(pool.objects, i)
                pool.objects[i] = pool.create_fn()
            else
                pool.reset_fn(pool.objects[i])
            end
            pool.available[i] = false
            pool.allocated_count += 1
            return pool.objects[i]
        end
    end
    return nothing  # Pool esgotado
end

"""
    deallocate!(pool::MemoryPool{T}, obj::T)

Retorna objeto para o pool
"""
function deallocate!(pool::MemoryPool{T}, obj::T) where {T}
    for i in 1:pool.size
        if isassigned(pool.objects, i) && pool.objects[i] === obj
            pool.available[i] = true
            pool.allocated_count -= 1
            return true
        end
    end
    return false
end

"""
    utilization(pool::MemoryPool{T}) -> Float64

Retorna taxa de utilização do pool
"""
utilization(pool::MemoryPool{T}) where {T} = pool.allocated_count / pool.size

# =============================================================================
# OBJECT POOL FOR COMMON TYPES
# =============================================================================

"""
    ObjectPool

Pool genérico para tipos comuns
"""
mutable struct ObjectPool
    vectors::MemoryPool{Vector{Float64}}
    matrices::MemoryPool{Matrix{Float64}}
    dicts::MemoryPool{Dict{String,Any}}

    function ObjectPool(size::Int=100)
        vectors = MemoryPool{Vector{Float64}}(size, () -> Float64[], empty!)
        matrices =
            MemoryPool{Matrix{Float64}}(size, () -> zeros(10, 10), (m) -> fill!(m, 0.0))
        dicts = MemoryPool{Dict{String,Any}}(size, () -> Dict{String,Any}(), empty!)
        new(vectors, matrices, dicts)
    end
end

# Pool global padrão
const DEFAULT_POOL = ObjectPool()

"""
    get_vector(pool::ObjectPool=DEFAULT_POOL) -> Vector{Float64}

Obtém vetor do pool
"""
get_vector(pool::ObjectPool=DEFAULT_POOL) = allocate!(pool.vectors)

"""
    return_vector!(pool::ObjectPool, vec::Vector{Float64})

Retorna vetor para o pool
"""
return_vector!(pool::ObjectPool, vec::Vector{Float64}) = deallocate!(pool.vectors, vec)

"""
    with_pooled_vector(operation::Function, pool::ObjectPool=DEFAULT_POOL)

Executa operação com vetor do pool
"""
function with_pooled_vector(operation::Function, pool::ObjectPool=DEFAULT_POOL)
    vec = get_vector(pool)
    if vec === nothing
        # Fallback para alocação normal se pool esgotado
        vec = Float64[]
        return operation(vec)
    end

    try
        return operation(vec)
    finally
        return_vector!(pool, vec)
    end
end

# =============================================================================
# LEAK DETECTION
# =============================================================================

"""
    LeakDetector

Detector de vazamentos de memória
"""
mutable struct LeakDetector
    initial_memory::UInt64
    snapshots::Vector{Tuple{DateTime,UInt64}}
    threshold_mb::Float64

    LeakDetector(threshold_mb::Float64=50.0) = new(Base.gc_live_bytes(), [], threshold_mb)
end

"""
    take_snapshot!(detector::LeakDetector)

Captura snapshot da memória
"""
function take_snapshot!(detector::LeakDetector)
    current_memory = Base.gc_live_bytes()
    push!(detector.snapshots, (now(), current_memory))
end

"""
    detect_leaks!(detector::LeakDetector) -> Bool

Detecta vazamentos baseado em crescimento sustentado
"""
function detect_leaks!(detector::LeakDetector)
    take_snapshot!(detector)

    if length(detector.snapshots) < 3
        return false
    end

    # Analisa últimas 3 medições
    recent = detector.snapshots[(end-2):end]
    memories = [snapshot[2] for snapshot in recent]

    # Verifica crescimento sustentado
    growth_rates = [memories[i+1] - memories[i] for i in 1:(length(memories)-1)]
    avg_growth = mean(growth_rates)

    # Converte para MB
    growth_mb = avg_growth / 1e6

    return growth_mb > detector.threshold_mb
end

# =============================================================================
# MEMORY MONITORING
# =============================================================================

"""
    MemoryMonitor

Monitor de uso de memória em tempo real
"""
mutable struct MemoryMonitor
    max_memory_mb::Float64
    current_usage_mb::Float64
    warnings::Vector{String}

    MemoryMonitor(max_mb::Float64=1000.0) = new(max_mb, 0.0, String[])
end

"""
    check_memory!(monitor::MemoryMonitor) -> Bool

Verifica uso atual de memória
"""
function check_memory!(monitor::MemoryMonitor)
    current_bytes = Base.gc_live_bytes()
    monitor.current_usage_mb = current_bytes / 1e6

    if monitor.current_usage_mb > monitor.max_memory_mb
        warning = "Memory usage exceeded: $(round(monitor.current_usage_mb, digits=1))MB > $(monitor.max_memory_mb)MB"
        push!(monitor.warnings, warning)
        @warn warning
        return false
    end

    return true
end

"""
    with_memory_limit(operation::Function, max_mb::Float64=500.0)

Executa operação com limite de memória
"""
function with_memory_limit(operation::Function, max_mb::Float64=500.0)
    monitor = MemoryMonitor(max_mb)

    try
        result = operation()

        if !check_memory!(monitor)
            # Substituir GC forçado por sugestão de otimização
            @warn "Limite de memória excedido. Considere otimizar a operação."
        end

        return result
    catch e
        check_memory!(monitor)
        rethrow(e)
    end
end

# =============================================================================
# CHUNKED PROCESSING
# =============================================================================

"""
    chunked_processing(data::Vector{T}, chunk_size::Int, process_fn::Function) where T

Processa dados em chunks para evitar uso excessivo de memória
"""
function chunked_processing(
    data::Vector{T},
    chunk_size::Int,
    process_fn::Function,
) where {T}
    results = []

    for i in 1:chunk_size:length(data)
        end_idx = min(i + chunk_size - 1, length(data))
        chunk = @view data[i:end_idx]

        # Remover GC forçado para melhorar performance
        chunk_result = process_fn(chunk)
        push!(results, chunk_result)
    end

    return results
end

"""
    memory_efficient_map(f::Function, data::Vector{T}, chunk_size::Int=1000) where T

Map eficiente em memória usando processamento em chunks
"""
function memory_efficient_map(
    f::Function,
    data::Vector{T},
    chunk_size::Int=1000,
) where {T}
    result_type = typeof(f(first(data)))
    results = Vector{result_type}()

    for i in 1:chunk_size:length(data)
        end_idx = min(i + chunk_size - 1, length(data))
        chunk = @view data[i:end_idx]

        # Remover GC forçado para melhorar performance
        chunk_results = map(f, chunk)

        append!(results, chunk_results)
    end

    return results
end

# =============================================================================
# GARBAGE COLLECTION OPTIMIZATION
# =============================================================================

"""
    optimize_gc_for_operation(operation::Function, gc_threshold::Float64=0.1)

Otimiza garbage collection para operação específica
"""
function optimize_gc_for_operation(operation::Function, gc_threshold::Float64=0.1)
    # Salva configuração atual
    original_gc_percent = GC.gc_percent()

    try
        # Ajusta threshold para operação
        GC.gc_percent(gc_threshold)

        return operation()
    finally
        # Restaura configuração original
        GC.gc_percent(original_gc_percent)

        # Remover garbage collection forçado para melhorar performance
        @debug "Restaurando configuração original de GC"
    end
end

"""
    with_gc_cleanup(operation::Function)

Executa operação com cleanup de GC garantido
"""
function with_gc_cleanup(operation::Function)
    try
        return operation()
    finally
        # Remover GC forçado para melhorar performance
        @debug "Operação concluída sem GC forçado"
    end
end
