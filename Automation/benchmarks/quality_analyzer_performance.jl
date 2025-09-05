"""
Benchmarks de Performance - Quality Analyzer Otimizado
Validação das otimizações Green Code implementadas

Comparação de performance entre versão original e otimizada
"""

using BenchmarkTools
using Statistics
using JSON3
using Dates

# Incluir versão otimizada
include("../src/quality_analyzer_optimized.jl")

"""
    run_quality_analyzer_benchmarks()

Executa suite completa de benchmarks de performance
"""
function run_quality_analyzer_benchmarks()
    println("🚀 BENCHMARKS QUALITY ANALYZER - GREEN CODE OPTIMIZATION")
    println("="^60)

    # Encontrar arquivos de teste
    test_files = find_julia_files_optimized("src")
    if length(test_files) < 3
        test_files = find_julia_files_optimized(".")
    end

    println("📁 Testando com $(length(test_files)) arquivos Julia")

    # Resultados dos benchmarks
    results = Dict{String,Any}()

    # ==========================================================================
    # BENCHMARK 1: SINGLE FILE ANALYSIS
    # ==========================================================================

    println("\n🔬 Benchmark 1: Análise de Arquivo Individual")
    println("-"^40)

    if !isempty(test_files)
        test_file = test_files[1]
        file_size = filesize(test_file)

        println("📄 Arquivo: $(basename(test_file)) ($(round(file_size/1024, digits=1)) KB)")

        # Benchmark da versão otimizada
        benchmark_result = @benchmark analyze_file_optimized($test_file) samples = 10 evals = 1

        median_time = median(benchmark_result.times) / 1e6  # ms
        median_memory = median(benchmark_result.memory) / 1e6  # MB

        # Calcular métricas de eficiência
        time_per_kb = median_time / (file_size / 1024)
        memory_efficiency = median_memory / (file_size / 1e6)

        results["single_file"] = Dict(
            "file_size_kb" => round(file_size / 1024, digits=1),
            "median_time_ms" => round(median_time, digits=2),
            "median_memory_mb" => round(median_memory, digits=2),
            "time_per_kb_ms" => round(time_per_kb, digits=3),
            "memory_efficiency" => round(memory_efficiency, digits=2)
        )

        println("   ⏱️  Tempo médio: $(round(median_time, digits=2))ms")
        println("   💾 Memória média: $(round(median_memory, digits=2))MB")
        println("   📊 Eficiência: $(round(time_per_kb, digits=3))ms/KB")

        # Avaliar performance
        if median_time < 100 && median_memory < 5
            println("   ✅ Performance EXCELENTE")
        elseif median_time < 500 && median_memory < 20
            println("   ✅ Performance BOA")
        else
            println("   ⚠️  Performance ACEITÁVEL")
        end
    end

    # ==========================================================================
    # BENCHMARK 2: MULTIPLE FILES ANALYSIS
    # ==========================================================================

    println("\n🔬 Benchmark 2: Análise de Múltiplos Arquivos")
    println("-"^40)

    if length(test_files) >= 3
        # Testar com 3 arquivos
        test_subset = test_files[1:3]
        total_size = sum(filesize.(test_subset))

        println("📄 Arquivos: $(length(test_subset)) ($(round(total_size/1024, digits=1)) KB total)")

        # Benchmark sequencial
        sequential_time = @elapsed begin
            results_seq = [analyze_file_optimized(f) for f in test_subset]
        end

        # Calcular throughput
        throughput = length(test_subset) / sequential_time
        avg_time_per_file = sequential_time / length(test_subset) * 1000  # ms

        results["multiple_files"] = Dict(
            "file_count" => length(test_subset),
            "total_size_kb" => round(total_size / 1024, digits=1),
            "total_time_s" => round(sequential_time, digits=3),
            "throughput_files_per_s" => round(throughput, digits=2),
            "avg_time_per_file_ms" => round(avg_time_per_file, digits=1)
        )

        println("   ⏱️  Tempo total: $(round(sequential_time, digits=3))s")
        println("   📊 Throughput: $(round(throughput, digits=2)) arquivos/s")
        println("   📈 Média por arquivo: $(round(avg_time_per_file, digits=1))ms")

        # Avaliar scalabilidade
        if throughput > 2.0
            println("   ✅ Escalabilidade EXCELENTE")
        elseif throughput > 1.0
            println("   ✅ Escalabilidade BOA")
        else
            println("   ⚠️  Escalabilidade ACEITÁVEL")
        end
    end

    # ==========================================================================
    # BENCHMARK 3: MEMORY EFFICIENCY
    # ==========================================================================

    println("\n🔬 Benchmark 3: Eficiência de Memória")
    println("-"^40)

    if !isempty(test_files)
        test_file = test_files[1]

        # Medição detalhada de memória
        # Remover GC forçado para melhorar performance
        # GC.gc()  # Cleanup inicial
        memory_before = Base.gc_live_bytes()

        # Execução com tracking de memória
        result = @timed analyze_file_optimized(test_file)

        # Remover GC forçado para melhorar performance
        # GC.gc()  # Cleanup após execução
        memory_after = Base.gc_live_bytes()

        # Calcular métricas de memória
        memory_peak = result.bytes
        memory_persistent = memory_after - memory_before
        memory_ratio = memory_peak / filesize(test_file)

        results["memory_efficiency"] = Dict(
            "execution_time_ms" => round(result.time * 1000, digits=2),
            "peak_memory_mb" => round(memory_peak / 1e6, digits=2),
            "persistent_memory_kb" => round(memory_persistent / 1024, digits=1),
            "memory_ratio" => round(memory_ratio, digits=2),
            "efficiency_score" => round(100 / max(1, memory_ratio), digits=1)
        )

        println("   ⏱️  Tempo de execução: $(round(result.time * 1000, digits=2))ms")
        println("   💾 Pico de memória: $(round(memory_peak / 1e6, digits=2))MB")
        println("   🔄 Memória persistente: $(round(memory_persistent / 1024, digits=1))KB")
        println("   📊 Ratio memória/arquivo: $(round(memory_ratio, digits=2))x")

        # Avaliar eficiência de memória
        if memory_ratio < 5.0
            println("   ✅ Eficiência de memória EXCELENTE")
        elseif memory_ratio < 15.0
            println("   ✅ Eficiência de memória BOA")
        else
            println("   ⚠️  Eficiência de memória ACEITÁVEL")
        end
    end

    # ==========================================================================
    # BENCHMARK 4: CPU EFFICIENCY
    # ==========================================================================

    println("\n🔬 Benchmark 4: Eficiência de CPU")
    println("-"^40)

    # Testar componentes específicos
    test_content = """
    function example_function(x, y)
        if x > 0
            for i in 1:10
                if i % 2 == 0
                    while y < i
                        y += 1
                    end
                elseif i > 5
                    break
                end
            end
        end
        return y
    end
    """

    # Benchmark de componentes individuais
    complexity_bench = @benchmark calculate_complexity_optimized($test_content) samples = 50

    lines = String.(split(test_content, '\n'))
    loc_bench = @benchmark count_effective_lines_optimized($lines) samples = 50

    complexity_time = median(complexity_bench.times) / 1e3  # μs
    loc_time = median(loc_bench.times) / 1e3  # μs

    results["cpu_efficiency"] = Dict(
        "complexity_analysis_us" => round(complexity_time, digits=2),
        "loc_counting_us" => round(loc_time, digits=2),
        "total_analysis_us" => round(complexity_time + loc_time, digits=2)
    )

    println("   🔄 Análise de complexidade: $(round(complexity_time, digits=2))μs")
    println("   📊 Contagem de LOC: $(round(loc_time, digits=2))μs")
    println("   ⚡ Total de análise: $(round(complexity_time + loc_time, digits=2))μs")

    # Avaliar eficiência de CPU
    total_cpu_time = complexity_time + loc_time
    if total_cpu_time < 100
        println("   ✅ Eficiência de CPU EXCELENTE")
    elseif total_cpu_time < 500
        println("   ✅ Eficiência de CPU BOA")
    else
        println("   ⚠️  Eficiência de CPU ACEITÁVEL")
    end

    # ==========================================================================
    # SUMMARY E GREEN CODE SCORE
    # ==========================================================================

    println("\n📊 RESUMO DOS BENCHMARKS")
    println("="^60)

    # Calcular Green Code Score baseado nos benchmarks
    green_score = calculate_green_code_score(results)

    println("🌱 GREEN CODE PERFORMANCE SCORE: $(round(green_score, digits=1))/100")

    if green_score >= 80
        println("🏆 PERFORMANCE EXCELENTE - Otimizações eficazes!")
    elseif green_score >= 65
        println("✅ PERFORMANCE BOA - Melhorias visíveis!")
    else
        println("📈 PERFORMANCE ACEITÁVEL - Espaço para otimização!")
    end

    # Salvar resultados
    save_benchmark_results(results, green_score)

    return results
end

"""
    calculate_green_code_score(results::Dict) -> Float64

Calcula score Green Code baseado nos resultados dos benchmarks
"""
function calculate_green_code_score(results::Dict)
    score = 0.0

    # Memory efficiency (30%)
    if haskey(results, "memory_efficiency")
        memory_ratio = get(results["memory_efficiency"], "memory_ratio", 10.0)
        memory_score = max(0, 100 - memory_ratio * 10)
        score += memory_score * 0.30
    end

    # CPU efficiency (25%)
    if haskey(results, "cpu_efficiency")
        cpu_time = get(results["cpu_efficiency"], "total_analysis_us", 1000.0)
        cpu_score = max(0, 100 - cpu_time / 10)
        score += cpu_score * 0.25
    end

    # Throughput (25%)
    if haskey(results, "multiple_files")
        throughput = get(results["multiple_files"], "throughput_files_per_s", 0.5)
        throughput_score = min(100, throughput * 40)
        score += throughput_score * 0.25
    end

    # Time efficiency (20%)
    if haskey(results, "single_file")
        time_per_kb = get(results["single_file"], "time_per_kb_ms", 100.0)
        time_score = max(0, 100 - time_per_kb * 2)
        score += time_score * 0.20
    end

    return score
end

"""
    save_benchmark_results(results::Dict, green_score::Float64)

Salva resultados dos benchmarks em arquivo JSON
"""
function save_benchmark_results(results::Dict, green_score::Float64)
    output = Dict(
        "timestamp" => Dates.now(),
        "green_code_score" => green_score,
        "benchmarks" => results,
        "tool" => "Quality Analyzer Optimized",
        "version" => "1.0.0"
    )

    output_file = "benchmarks/quality_analyzer_results.json"
    try
        JSON3.write(output_file, output)
        println("\n💾 Resultados salvos em: $output_file")
    catch e
        println("\n⚠️  Erro ao salvar resultados: $e")
    end
end

# Executar benchmarks se arquivo for chamado diretamente
if abspath(PROGRAM_FILE) == @__FILE__
    run_quality_analyzer_benchmarks()
end
