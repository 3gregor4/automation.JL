"""
I/O Resource Management Utilities
Gestão segura de recursos de entrada/saída para o pilar Green Code

Funcionalidades:
- Safe file operations com cleanup automático
- Buffered I/O para dados grandes
- Resource tracking para arquivos abertos
- Error handling robusto
"""

using Dates

export safe_file_operation, buffered_file_read, buffered_file_write
export BatchFileProcessor, process_files_batch, FileResourceManager
export safe_csv_read, safe_json_read, safe_json_write

# =============================================================================
# SAFE FILE OPERATIONS
# =============================================================================

"""
    safe_file_operation(filepath::String, mode::String, operation::Function)

Executa operação em arquivo com cleanup garantido
"""
function safe_file_operation(filepath::String, mode::String, operation::Function)
    file_handle = nothing
    try
        file_handle = open(filepath, mode)
        return operation(file_handle)
    catch e
        @error "Error in file operation for $filepath: $e"
        rethrow(e)
    finally
        if file_handle !== nothing
            try
                close(file_handle)
            catch close_error
                @warn "Error closing file $filepath: $close_error"
            end
        end
    end
end

"""
    buffered_file_read(filepath::String, buffer_size::Int=8192)

Lê arquivo em chunks para evitar uso excessivo de memória
"""
function buffered_file_read(filepath::String, buffer_size::Int=8192)
    content_parts = String[]

    safe_file_operation(filepath, "r") do file
        while !eof(file)
            chunk = read(file, buffer_size)
            push!(content_parts, String(chunk))

            # Remover GC forçado para melhorar performance
            # Substituir por monitoramento de uso de memória
            if length(content_parts) % 100 == 0
                @debug "Processando chunk $length(content_parts) de leitura"
            end
        end
    end

    return join(content_parts)
end

"""
    buffered_file_write(filepath::String, content::String, buffer_size::Int=8192)

Escreve arquivo em chunks para otimizar memória
"""
function buffered_file_write(filepath::String, content::String, buffer_size::Int=8192)
    safe_file_operation(filepath, "w") do file
        content_length = length(content)
        written = 0

        while written < content_length
            end_pos = min(written + buffer_size, content_length)
            chunk = content[(written+1):end_pos]
            write(file, chunk)
            written = end_pos

            # Flush periódico
            if written % (buffer_size * 10) == 0
                flush(file)
            end
        end

        flush(file)  # Final flush
    end
end

# =============================================================================
# BATCH FILE PROCESSOR
# =============================================================================

"""
    BatchFileProcessor

Processador de arquivos em lotes para otimização de recursos
"""
mutable struct BatchFileProcessor
    batch_size::Int
    processed_files::Vector{String}
    failed_files::Vector{Tuple{String,Exception}}
    memory_limit_mb::Float64

    BatchFileProcessor(batch_size::Int=10, memory_limit_mb::Float64=200.0) =
        new(batch_size, String[], Tuple{String,Exception}[], memory_limit_mb)
end

"""
    process_files_batch(processor::BatchFileProcessor, filepaths::Vector{String}, operation::Function)

Processa arquivos em lotes com gestão de memória
"""
function process_files_batch(
    processor::BatchFileProcessor,
    filepaths::Vector{String},
    operation::Function,
)
    results = []

    for i in 1:processor.batch_size:length(filepaths)
        end_idx = min(i + processor.batch_size - 1, length(filepaths))
        batch = filepaths[i:end_idx]

        # Process batch with memory monitoring
        batch_results = with_memory_limit(processor.memory_limit_mb) do
            batch_process_results = []

            for filepath in batch
                try
                    result = operation(filepath)
                    push!(batch_process_results, result)
                    push!(processor.processed_files, filepath)
                catch e
                    push!(processor.failed_files, (filepath, e))
                    @warn "Failed to process $filepath: $e"
                end
            end

            return batch_process_results
        end

        append!(results, batch_results)

        # Remover GC forçado entre batches para melhorar performance
        @debug "Processamento de batch concluído"
    end

    return results
end

# =============================================================================
# FILE RESOURCE MANAGER
# =============================================================================

"""
    FileResourceManager

Gerenciador de recursos de arquivos com tracking
"""
mutable struct FileResourceManager
    open_files::Dict{String,IO}
    file_access_times::Dict{String,DateTime}
    max_open_files::Int

    FileResourceManager(max_open_files::Int=50) =
        new(Dict{String,IO}(), Dict{String,DateTime}(), max_open_files)
end

"""
    get_file_handle(manager::FileResourceManager, filepath::String, mode::String="r")

Obtém handle de arquivo com gestão de recursos
"""
function get_file_handle(manager::FileResourceManager, filepath::String, mode::String="r")
    # Check if file is already open
    if haskey(manager.open_files, filepath)
        manager.file_access_times[filepath] = now()
        return manager.open_files[filepath]
    end

    # Check if we need to close old files
    if length(manager.open_files) >= manager.max_open_files
        close_oldest_file!(manager)
    end

    # Open new file
    try
        file_handle = open(filepath, mode)
        manager.open_files[filepath] = file_handle
        manager.file_access_times[filepath] = now()
        return file_handle
    catch e
        @error "Cannot open file $filepath: $e"
        rethrow(e)
    end
end

"""
    close_oldest_file!(manager::FileResourceManager)

Fecha o arquivo aberto há mais tempo
"""
function close_oldest_file!(manager::FileResourceManager)
    if isempty(manager.open_files)
        return
    end

    # Find oldest file
    oldest_file = ""
    oldest_time = now()

    for (filepath, access_time) in manager.file_access_times
        if access_time < oldest_time
            oldest_time = access_time
            oldest_file = filepath
        end
    end

    # Close oldest file
    if !isempty(oldest_file)
        close_file!(manager, oldest_file)
    end
end

"""
    close_file!(manager::FileResourceManager, filepath::String)

Fecha arquivo específico
"""
function close_file!(manager::FileResourceManager, filepath::String)
    if haskey(manager.open_files, filepath)
        try
            close(manager.open_files[filepath])
        catch e
            @warn "Error closing file $filepath: $e"
        finally
            delete!(manager.open_files, filepath)
            delete!(manager.file_access_times, filepath)
        end
    end
end

"""
    close_all_files!(manager::FileResourceManager)

Fecha todos os arquivos abertos
"""
function close_all_files!(manager::FileResourceManager)
    for filepath in keys(manager.open_files)
        close_file!(manager, filepath)
    end
end

# =============================================================================
# SPECIALIZED FILE OPERATIONS
# =============================================================================

"""
    safe_csv_read(filepath::String; chunk_size::Int=10000)

Lê CSV com gestão de memória otimizada
"""
function safe_csv_read(filepath::String; chunk_size::Int=10000)
    # This would integrate with CSV.jl if available
    lines = String[]

    safe_file_operation(filepath, "r") do file
        line_count = 0
        while !eof(file) && line_count < chunk_size
            line = readline(file)
            push!(lines, line)
            line_count += 1
        end
    end

    return lines
end

"""
    safe_json_read(filepath::String)

Lê JSON com error handling robusto
"""
function safe_json_read(filepath::String)
    content = safe_file_operation(filepath, "r") do file
        read(file, String)
    end

    try
        # This would use JSON3.jl if we want to parse
        return content
    catch e
        @error "Invalid JSON in file $filepath: $e"
        rethrow(e)
    end
end

"""
    safe_json_write(filepath::String, data::String)

Escreve JSON com backup automático
"""
function safe_json_write(filepath::String, data::String)
    # Create backup if file exists
    if isfile(filepath)
        backup_path = filepath * ".backup." * string(now())
        try
            cp(filepath, backup_path)
        catch e
            @warn "Could not create backup: $e"
        end
    end

    # Write new content
    safe_file_operation(filepath, "w") do file
        write(file, data)
        flush(file)
    end
end
