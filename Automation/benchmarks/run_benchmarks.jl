#!/usr/bin/env julia

"""
Main Benchmarks Runner - Automation Project
Executa suite completa de benchmarks para avaliação CSGA
Otimizado para máximo impacto nas métricas de performance
"""

using BenchmarkTools
using Statistics
using Dates
using JSON3
using LinearAlgebra  # Para BLAS

# Configurar ambiente de benchmark
BLAS.set_num_threads(1)  # Consistência nos resultados
BenchmarkTools.DEFAULT_PARAMETERS.samples = 100
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 5

"""
    setup_benchmark_environment()

Configura ambiente otimizado para benchmarks consistentes
"""
function setup_benchmark_environment()
    # Forçar garbage collection antes de iniciar
    GC.gc()
    GC.gc()

    # Configurar parâmetros de benchmark
    println("🔧 Configurando ambiente de benchmark...")
    println("   • BLAS threads: $(BLAS.get_num_threads())")
    println("   • Julia threads: $(Threads.nthreads())")
    println("   • Samples: $(BenchmarkTools.DEFAULT_PARAMETERS.samples)")

    return true
end

"""
    BenchmarkSuite

Suite principal de benchmarks para sistema CSGA
"""
struct BenchmarkSuite
    name::String
    benchmarks::Dict{String,Any}
    results::Dict{String,Any}

    function BenchmarkSuite(name::String)
        new(name, Dict{String,Any}(), Dict{String,Any}())
    end
end

"""
    add_benchmark!(suite::BenchmarkSuite, name::String, func::Function, args...)

Adiciona benchmark à suite
"""
function add_benchmark!(suite::BenchmarkSuite, name::String, func::Function, args...)
    suite.benchmarks[name] = () -> func(args...)
    return suite
end

"""
    run_suite!(suite::BenchmarkSuite)

Executa todos os benchmarks da suite
"""
function run_suite!(suite::BenchmarkSuite)
    println("\n📊 Executando suite: $(suite.name)")

    for (name, benchmark_func) in suite.benchmarks
        print("   • $name... ")

        try
            # Warming up
            benchmark_func()

            # Benchmark real
            result = @benchmark $(benchmark_func)()
            suite.results[name] = result

            # Estatísticas básicas
            median_time = median(result.times) / 1e6  # Convert to ms
            memory = result.memory

            println("✅ $(round(median_time, digits=2))ms, $(memory) bytes")

        catch e
            println("❌ Erro: $e")
            suite.results[name] = nothing
        end
    end

    return suite
end

"""
    create_core_benchmarks()

Cria benchmarks das funções core do sistema
"""
function create_core_benchmarks()
    suite = BenchmarkSuite("Core Functions")

    # Benchmark básico - operações matemáticas
    add_benchmark!(suite, "math_operations", () -> begin
        x = rand(1000)
        sum(x .^ 2)
    end)

    # Benchmark de I/O - leitura de arquivo Project.toml
    add_benchmark!(suite, "file_io", () -> begin
        if isfile("Project.toml")
            read("Project.toml", String)
        else
            "mock content"
        end
    end)

    # Benchmark de string processing
    add_benchmark!(
        suite,
        "string_processing",
        () -> begin
            text = "Julia Performance Benchmarking "^100
            split(uppercase(text), " ")
        end,
    )

    return suite
end

"""
    run_all_benchmarks()

Executa todos os benchmarks principais
"""
function run_all_benchmarks()
    println("🚀 INICIANDO BENCHMARKS - AUTOMATION PROJECT")
    println("="^60)

    # Setup
    setup_benchmark_environment()

    # Execute suites
    suites = []

    # Core benchmarks
    core_suite = create_core_benchmarks()
    run_suite!(core_suite)
    push!(suites, core_suite)

    # CSGA System benchmarks
    println("\n🎯 Executando benchmarks do sistema CSGA...")
    try
        include("csga_performance.jl")
        run_csga_benchmarks()
        println("✅ CSGA benchmarks integrados")
    catch e
        println("⚠️  Erro nos benchmarks CSGA: $e")
    end

    # Additional benchmark modules
    additional_benchmarks = [
        ("core_functions.jl", "Core Functions"),
        ("memory_profiling.jl", "Memory Profiling"),
        ("efficiency_patterns.jl", "Efficiency Patterns"),
        ("regression_check.jl", "Regression Check"),
        ("green_code_optimizations.jl", "Green Code Optimizations"),  # New benchmark
        ("makefile_integration.jl", "Makefile Integration"),  # Additional benchmark
    ]

    for (file, desc) in additional_benchmarks
        println("\n🔧 Executando $desc...")
        try
            include(file)
            if file == "green_code_optimizations.jl"
                # Run the specific benchmark function
                benchmark_green_code_optimizations()
            end
            println("✅ $desc concluído")
        catch e
            println("⚠️  Erro em $desc: $e")
        end
    end

    # Generate final report
    println("\n📄 Gerando relatório final...")
    try
        include("reporting_minimal.jl")
        generate_benchmark_report()
    catch e
        println("⚠️  Erro no relatório: $e")
    end

    # Integração com make bench
    export_results(suites)
    generate_summary(suites)

    println("\n✅ Benchmarks concluídos com sucesso!")
    return suites
end

"""
    export_results(suites)

Exporta resultados para integração CSGA
"""
function export_results(suites)
    results = Dict()

    for suite in suites
        suite_results = Dict()

        for (name, result) in suite.results
            if result !== nothing
                suite_results[name] = Dict(
                    "median_time_ms" => median(result.times) / 1e6,
                    "memory_bytes" => result.memory,
                    "allocs" => result.allocs,
                )
            end
        end

        results[suite.name] = suite_results
    end

    # Salvar em JSON para análise posterior
    json_path = "benchmarks/results.json"
    try
        open(json_path, "w") do f
            JSON3.pretty(f, results)
        end
        println("\n📄 Resultados salvos em: $json_path")
    catch e
        println("\n⚠️  Erro ao salvar resultados: $e")
    end
end

"""
    generate_summary(suites)

Gera resumo executivo dos benchmarks
"""
function generate_summary(suites)
    println("\n" * "="^60)
    println("📊 RESUMO DOS BENCHMARKS")
    println("="^60)

    total_benchmarks = 0
    successful_benchmarks = 0

    for suite in suites
        suite_success = count(x -> x !== nothing, values(suite.results))
        suite_total = length(suite.results)

        total_benchmarks += suite_total
        successful_benchmarks += suite_success

        println("$(suite.name): $suite_success/$suite_total sucessos")
    end

    success_rate = round(successful_benchmarks / total_benchmarks * 100, digits=1)
    println("\nTaxa de sucesso geral: $success_rate%")
    println("Timestamp: $(now())")
end

# Executar se chamado diretamente
if abspath(PROGRAM_FILE) == @__FILE__
    run_all_benchmarks()
end
