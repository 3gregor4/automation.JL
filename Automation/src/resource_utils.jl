"""
Resource Management Utilities
Sistema de gestão de recursos para o pilar Green Code CSGA

Funcionalidades:
- Cleanup automático com try-finally patterns
- Resource wrappers para operações seguras
- Memory management utilities
- Auto-disposal patterns
"""

using Dates

export @with_cleanup, safe_operation, ResourceTracker, track_resource, cleanup_all!

# =============================================================================
# RESOURCE TRACKER GLOBAL
# =============================================================================

"""
    ResourceTracker

Rastreador global de recursos para prevenção de vazamentos
"""
mutable struct ResourceTracker
    active_resources::Dict{String, Any}
    cleanup_functions::Dict{String, Function}
    creation_times::Dict{String, DateTime}

    ResourceTracker() = new(Dict(), Dict(), Dict())
end

const GLOBAL_TRACKER = ResourceTracker()

"""
    track_resource(id::String, resource, cleanup_fn::Function)

Registra um recurso para cleanup automático
"""
function track_resource(id::String, resource, cleanup_fn::Function)
    GLOBAL_TRACKER.active_resources[id] = resource
    GLOBAL_TRACKER.cleanup_functions[id] = cleanup_fn
    GLOBAL_TRACKER.creation_times[id] = now()
    return resource
end

"""
    cleanup_resource!(id::String)

Remove e limpa um recurso específico
"""
function cleanup_resource!(id::String)
    if haskey(GLOBAL_TRACKER.active_resources, id)
        try
            cleanup_fn = GLOBAL_TRACKER.cleanup_functions[id]
            cleanup_fn()
        catch e
            @warn "Erro no cleanup do recurso $id: $e"
        finally
            delete!(GLOBAL_TRACKER.active_resources, id)
            delete!(GLOBAL_TRACKER.cleanup_functions, id)
            delete!(GLOBAL_TRACKER.creation_times, id)
        end
    end
end

"""
    cleanup_all!()

Limpa todos os recursos registrados
"""
function cleanup_all!()
    for id in keys(GLOBAL_TRACKER.active_resources)
        cleanup_resource!(id)
    end
end

# =============================================================================
# MACRO DE CLEANUP AUTOMÁTICO
# =============================================================================

"""
    @with_cleanup resource_expr cleanup_expr body

Macro para garantir cleanup automático de recursos

# Exemplo

```julia
@with_cleanup file=open("data.txt") close(file) begin
    # Operações com arquivo
    content = read(file, String)
end
# Arquivo é automaticamente fechado
```
"""
macro with_cleanup(resource_expr, cleanup_expr, body)
    quote
        local resource_val = nothing
        try
            resource_val = $(esc(resource_expr))
            $(esc(body))
        finally
            if resource_val !== nothing
                try
                    $(esc(cleanup_expr))
                catch cleanup_error
                    @warn "Erro no cleanup: $cleanup_error"
                end
            end
        end
    end
end

# =============================================================================
# SAFE OPERATION WRAPPERS
# =============================================================================

"""
    safe_operation(operation::Function, cleanup_fn::Function)

Executa operação com cleanup garantido
"""
function safe_operation(operation::Function, cleanup_fn::Function)
    resource = nothing
    try
        resource = operation()
        return resource
    finally
        if resource !== nothing && cleanup_fn !== nothing
            try
                cleanup_fn(resource)
            catch e
                @warn "Cleanup error: $e"
            end
        end
    end
end

"""
    safe_operation(operation::Function, resource, cleanup_fn::Function)

Executa operação com recurso existente e cleanup garantido
"""
function safe_operation(operation::Function, resource, cleanup_fn::Function)
    try
        return operation(resource)
    finally
        if cleanup_fn !== nothing
            try
                cleanup_fn(resource)
            catch e
                @warn "Cleanup error: $e"
            end
        end
    end
end

# =============================================================================
# FILE OPERATIONS HELPERS
# =============================================================================

"""
    safe_file_read(filepath::String)

Lê arquivo com cleanup automático
"""
function safe_file_read(filepath::String)
    @with_cleanup file=open(filepath, "r") close(file) begin
        return read(file, String)
    end
end

"""
    safe_file_write(filepath::String, content::String)

Escreve arquivo com cleanup automático
"""
function safe_file_write(filepath::String, content::String)
    @with_cleanup file=open(filepath, "w") close(file) begin
        write(file, content)
    end
end

# =============================================================================
# MEMORY MANAGEMENT HELPERS
# =============================================================================

"""
    memory_safe_operation(operation::Function, max_memory_mb::Int=500)

Executa operação monitorando uso de memória
"""
function memory_safe_operation(operation::Function, max_memory_mb::Int = 500)
    initial_memory = Base.gc_live_bytes()

    try
        result = operation()

        current_memory = Base.gc_live_bytes()
        memory_used_mb = (current_memory - initial_memory) / 1e6

        if memory_used_mb > max_memory_mb
            @warn "Alto uso de memória detectado: $(round(memory_used_mb, digits=1))MB"
            GC.gc()  # Força garbage collection
        end

        return result
    finally
        # Cleanup final
        GC.gc()
    end
end

# =============================================================================
# RESOURCE POOL PATTERN
# =============================================================================

"""
    ResourcePool{T}

Pool de recursos reutilizáveis
"""
mutable struct ResourcePool{T}
    available::Vector{T}
    in_use::Set{T}
    create_fn::Function
    reset_fn::Function

    function ResourcePool{T}(create_fn::Function, reset_fn::Function = identity) where {T}
        new{T}(T[], Set{T}(), create_fn, reset_fn)
    end
end

"""
    acquire!(pool::ResourcePool{T}) -> T

Adquire recurso do pool
"""
function acquire!(pool::ResourcePool{T}) where {T}
    if isempty(pool.available)
        resource = pool.create_fn()::T
    else
        resource = pop!(pool.available)
        pool.reset_fn(resource)
    end

    push!(pool.in_use, resource)
    return resource
end

"""
    release!(pool::ResourcePool{T}, resource::T)

Retorna recurso para o pool
"""
function release!(pool::ResourcePool{T}, resource::T) where {T}
    if resource in pool.in_use
        delete!(pool.in_use, resource)
        push!(pool.available, resource)
    end
end

"""
    with_pooled_resource(operation::Function, pool::ResourcePool{T}) -> Any

Executa operação com recurso do pool
"""
function with_pooled_resource(operation::Function, pool::ResourcePool{T}) where {T}
    resource = acquire!(pool)
    try
        return operation(resource)
    finally
        release!(pool, resource)
    end
end
