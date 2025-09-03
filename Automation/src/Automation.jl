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
export evaluate_project, print_detailed_report, generate_report
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

greet() = print("Hello World!")

end # module Automation
