module Automation

# Incluir utilidades de resource management
include("resource_utils.jl")
include("memory_patterns.jl")
include("io_utils.jl")

# CORREÇÃO P0: Incluir quality analyzer otimizado
include("quality_analyzer_optimized.jl")

# Incluir sistema CSGA
include("csga_scoring.jl")
using .CSGAScoring

# Exportar funções principais
export evaluate_project, print_detailed_report, generate_report, debug_score_calculation
export CSGAScore, PillarScore

# ADIÇÃO P0: Exportar funções otimizadas de qualidade
export QualityAnalyzerOptimized, analyze_file_optimized, analyze_project_optimized
export calculate_complexity_metrics_optimized

# Exportar utilidades de resource management
export @with_cleanup, safe_operation, ResourceTracker, track_resource, cleanup_all!
export safe_file_read, safe_file_write, with_gc_cleanup, memory_safe_operation
export ResourcePool, acquire!, release!, with_pooled_resource

# Exportar memory management patterns
export MemoryPool, ObjectPool, LeakDetector, MemoryMonitor
export allocate!, deallocate!, with_memory_limit, detect_leaks!
export chunked_processing, memory_efficient_map, optimize_gc_for_operation

# Exportar I/O utilities
export safe_file_operation, buffered_file_read, buffered_file_write
export BatchFileProcessor, process_files_batch, FileResourceManager
export safe_csv_read, safe_json_read, safe_json_write
export resolve_project_path  # Nova função para resolver caminhos

"""
    validate_module_loading()

Valida se todos os módulos necessários foram carregados corretamente
"""
function validate_module_loading()
    required_modules = [
        "resource_utils.jl",
        "memory_patterns.jl", 
        "io_utils.jl",
        "quality_analyzer_optimized.jl",
        "csga_scoring.jl",
        "csga_extension.jl",
        "csga_final.jl"
    ]
    
    missing_modules = String[]
    
    # Verificar se os arquivos existem
    for module_file in required_modules
        file_path = joinpath(@__DIR__, module_file)
        if !isfile(file_path)
            push!(missing_modules, module_file)
        end
    end
    
    if !isempty(missing_modules)
        @warn "Módulos ausentes detectados: $(join(missing_modules, ", "))"
        return false
    end
    
    # Verificar se as funções principais estão disponíveis
    required_functions = [
        :evaluate_project,
        :resolve_project_path,
        :analyze_project_optimized
    ]
    
    missing_functions = Symbol[]
    for func in required_functions
        if !isdefined(Automation, func)
            push!(missing_functions, func)
        end
    end
    
    if !isempty(missing_functions)
        @warn "Funções ausentes detectadas: $(join(string.(missing_functions), ", "))"
        return false
    end
    
    @info "Todos os módulos carregados corretamente"
    return true
end

greet() = print("Hello World!")

end # module Automation