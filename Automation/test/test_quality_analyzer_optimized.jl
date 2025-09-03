"""
Testes unitários para Quality Analyzer Otimizado
Validação das otimizações de performance e Green Code
"""

using Test
using BenchmarkTools
include("../src/quality_analyzer_optimized.jl")

@testset "🚀 Quality Analyzer Optimized Tests" begin

    println("\n🧪 Testando Quality Analyzer Otimizado...")

    # ==========================================================================
    # TESTES DE FUNCIONALIDADE
    # ==========================================================================

    @testset "📋 Funcionalidade Básica" begin

        @testset "Análise de Arquivo" begin
            # Testar com arquivo existente
            test_file = "src/quality_analyzer_optimized.jl"

            if isfile(test_file)
                result = analyze_file_optimized(test_file)

                @test isa(result, FileQualityResultOptimized)
                @test result.lines_of_code > 0
                @test result.complexity_score >= 0
                @test result.maintainability_index >= 0 && result.maintainability_index <= 100
                @test haskey(result.metrics, "total_lines")

                println("   ✅ Arquivo analisado: $(result.lines_of_code) LOC, MI: $(round(result.maintainability_index, digits=1))")
            else
                @test_skip "Arquivo de teste não encontrado"
            end
        end

        @testset "Contadores Otimizados" begin
            test_content = """
            function test_func()
                if true
                    for i in 1:10
                        println(i)  # This line is longer than 100 characters to test the long line detection properly
                    end
                end
            end
            """

            # Criar arquivo temporário para teste
            temp_file = tempname() * ".jl"
            write(temp_file, test_content)

            try
                smells_count = count_code_smells_optimized(temp_file)
                issues_count = count_quality_issues_optimized(temp_file)

                @test smells_count >= 0
                @test issues_count >= 0

                println("   📊 Code Smells: $smells_count, Issues: $issues_count")

            finally
                rm(temp_file, force=true)
            end
        end

        @testset "Métricas de Complexidade" begin
            simple_content = "function simple() end"
            complex_content = """
            function complex()
                if x > 0
                    for i in 1:10
                        if i % 2 == 0
                            while j < i
                                j += 1
                            end
                        elseif i > 5
                            break
                        end
                    end
                end
            end
            """

            simple_complexity = calculate_complexity_optimized(simple_content)
            complex_complexity = calculate_complexity_optimized(complex_content)

            @test simple_complexity < complex_complexity
            @test simple_complexity > 0
            @test complex_complexity > 1

            println("   🔄 Complexidade: Simples=$(round(simple_complexity, digits=2)), Complexa=$(round(complex_complexity, digits=2))")
        end
    end

    # ==========================================================================
    # TESTES DE PERFORMANCE (GREEN CODE)
    # ==========================================================================

    @testset "🌱 Performance Benchmarks" begin

        @testset "Memory Efficiency" begin
            # Criar conteúdo de teste maior
            large_content = repeat("function test_$i() end\n", 100)
            temp_file = tempname() * ".jl"
            write(temp_file, large_content)

            try
                # Benchmark memory usage
                memory_before = Base.gc_live_bytes()

                result = @timed analyze_file_optimized(temp_file)

                memory_after = Base.gc_live_bytes()
                memory_used = (memory_after - memory_before) / 1e6  # MB

                @test result.time < 1.0  # Deve completar em menos de 1 segundo
                @test memory_used < 50   # Deve usar menos de 50MB

                println("   💾 Tempo: $(round(result.time * 1000, digits=1))ms, Memória: $(round(memory_used, digits=1))MB")

            finally
                rm(temp_file, force=true)
            end
        end

        @testset "CPU Optimization" begin
            # Testar com arquivo real do projeto
            project_files = find_julia_files_optimized("src")

            if !isempty(project_files)
                test_file = project_files[1]

                # Benchmark processing time
                benchmark_result = @benchmark analyze_file_optimized($test_file) samples = 5 evals = 1

                median_time = median(benchmark_result.times) / 1e6  # ms
                median_memory = median(benchmark_result.memory) / 1e6  # MB

                @test median_time < 500  # Menos de 500ms
                @test median_memory < 10 # Menos de 10MB

                println("   ⚡ CPU Benchmark: $(round(median_time, digits=1))ms, $(round(median_memory, digits=1))MB")
            end
        end

        @testset "Scalability Test" begin
            # Testar escalabilidade com múltiplos arquivos
            test_files = String[]
            try
                # Criar arquivos de teste temporários
                for i in 1:10
                    temp_file = tempname()
                    open(temp_file, "w") do f
                        write(f, "function test_function_$i()\n    return $i\nend\n")
                    end
                    push!(test_files, temp_file)
                end

                # Testar análise de múltiplos arquivos
                results = Dict{String,Any}()
                for file in test_files
                    if isfile(file)
                        result = Automation.QualityAnalyzerOptimized.analyze_file(file)
                        results[file] = result
                    end
                end

                @test length(results) == 10
                @test all(r -> isa(r, NamedTuple), values(results))

                # Testar eficiência de memória
                initial_memory = Base.gc_live_bytes()

                # Processar arquivos em lote
                batch_results = Automation.QualityAnalyzerOptimized.analyze_files(test_files)

                GC.gc()
                final_memory = Base.gc_live_bytes()
                memory_growth = final_memory - initial_memory

                @test isa(batch_results, Dict)
                @test length(batch_results) == 10
                @test memory_growth <= 10_000_000  # Menos de 10MB de crescimento

                # Testar uso de tipos otimizados
                sample_result = first(values(batch_results))
                @test haskey(sample_result, :complexity)
                @test haskey(sample_result, :quality_score)
                @test haskey(sample_result, :maintainability)
                @test haskey(sample_result, :efficiency)

                # Testar densidade de informação
                @test sample_result.complexity >= 0
                @test sample_result.quality_score >= 0.0 && sample_result.quality_score <= 100.0
                @test sample_result.maintainability >= 0.0 && sample_result.maintainability <= 100.0
                @test sample_result.efficiency >= 0.0 && sample_result.efficiency <= 100.0

                println("   ✅ Escalabilidade verificada com $(length(results)) arquivos")
                println("   💾 Crescimento de memória: $(round(memory_growth/1e6, digits=2))MB")

            finally
                # Limpar arquivos temporários
                for file in test_files
                    try
                        rm(file, force=true)
                    catch e
                        @warn "Não foi possível remover arquivo temporário $file: $e"
                    end
                end
            end
        end
    end

    # ==========================================================================
    # TESTES DE VALIDAÇÃO CSGA
    # ==========================================================================

    @testset "🎯 Validação CSGA" begin

        @testset "Green Code Metrics" begin
            # Verificar se as otimizações atendem aos critérios Green Code
            test_file = "../src/quality_analyzer_optimized.jl"

            if isfile(test_file)
                # Testar eficiência de memória
                memory_baseline = Base.gc_live_bytes()
                result = analyze_file_optimized(test_file)
                memory_peak = Base.gc_live_bytes()

                memory_efficiency = (memory_peak - memory_baseline) / filesize(test_file)

                @test memory_efficiency < 10.0  # Menos de 10x o tamanho do arquivo

                # Testar uso de tipos otimizados
                @test isa(result.lines_of_code, Int32)
                @test isa(result.complexity_score, Float32)
                @test isa(result.maintainability_index, Float32)

                # Testar densidade de informação
                info_density = result.lines_of_code / sizeof(result)
                @test info_density > 1.0  # Densidade mínima de informação

                println("   🌱 Eficiência de memória: $(round(memory_efficiency, digits=2))x")
                println("   📊 Densidade de informação: $(round(info_density, digits=2))")
            end
        end

        @testset "Quality Gates" begin
            # Verificar se o próprio código atende aos padrões de qualidade
            result = analyze_file_optimized("src/quality_analyzer_optimized.jl")

            @test result.maintainability_index >= 70.0  # Mínimo para código de produção
            @test result.complexity_score <= 10.0      # Complexidade aceitável
            @test result.code_smells_count <= 5        # Poucos code smells
            @test result.quality_issues_count <= 10    # Issues controlados

            quality_score = (result.maintainability_index +
                             (100 - min(100, result.complexity_score * 10)) +
                             (100 - min(100, result.code_smells_count * 10))) / 3

            @test quality_score >= 75.0  # Score mínimo para Green Code

            println("   ✅ Quality Score: $(round(quality_score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTES DE REGRESSÃO
    # ==========================================================================

    @testset "🔄 Regression Tests" begin

        @testset "Consistency Check" begin
            # Testar consistência entre múltiplas execuções
            test_file = "src/quality_analyzer_optimized.jl"

            results = [analyze_file_optimized(test_file) for _ in 1:3]

            # Verificar consistência dos resultados
            @test all(r -> r.lines_of_code == results[1].lines_of_code, results)
            @test all(r -> abs(r.complexity_score - results[1].complexity_score) < 0.1, results)
            @test all(r -> abs(r.maintainability_index - results[1].maintainability_index) < 0.1, results)

            println("   🔒 Resultados consistentes entre execuções")
        end

        @testset "Error Handling" begin
            # Testar tratamento de erros
            @test_throws ArgumentError analyze_file_optimized("nonexistent_file.jl")
            @test_throws ArgumentError analyze_file_optimized("README.md")

            println("   🛡️ Error handling funcionando corretamente")
        end
    end

    println("\n🎉 TODOS OS TESTES CONCLUÍDOS COM SUCESSO!")
    println("🏆 Quality Analyzer Otimizado validado para produção!")
end
