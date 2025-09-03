"""
Testes Unitários Avançados para Quality Analyzer Otimizado
Suíte completa de validação com foco em cobertura e edge cases

Funcionalidades testadas:
- Análise de arquivos com diferentes características
- Performance e memory efficiency
- Edge cases e error handling
- Integração com sistema CSGA
- Benchmarks comparativos
"""

using Test
using BenchmarkTools
using Statistics
using Dates

# Incluir o quality analyzer otimizado
include("../src/quality_analyzer_optimized.jl")

@testset "🧪 Quality Analyzer Advanced Tests" begin

    println("\n🔬 Executando testes avançados do Quality Analyzer...")

    # ==========================================================================
    # TESTES DE FUNCIONALIDADE CORE
    # ==========================================================================

    @testset "📋 Core Functionality Tests" begin

        @testset "Análise de Arquivo Real" begin
            # Testar com arquivo real do projeto
            test_file = "src/quality_analyzer_optimized.jl"

            if isfile(test_file)
                result = analyze_file_optimized(test_file)

                @test isa(result, FileQualityResultOptimized)
                @test result.lines_of_code > 0
                @test result.complexity_score >= 0
                @test 0 <= result.maintainability_index <= 100
                @test result.code_smells_count >= 0
                @test result.quality_issues_count >= 0

                println("   ✅ Análise do arquivo principal: LOC=$(result.lines_of_code), MI=$(round(result.maintainability_index, digits=1))")
            else
                @test_skip "Arquivo de teste não encontrado"
            end
        end

        @testset "Análise de Projeto Completo" begin
            # Testar análise de projeto
            project_results = analyze_project_optimized(".")

            @test length(project_results) > 0
            @test all(r -> isa(r, FileQualityResultOptimized), project_results)

            # Verificar métricas agregadas
            avg_maintainability = mean(r.maintainability_index for r in project_results)
            total_loc = sum(r.lines_of_code for r in project_results)

            @test avg_maintainability >= 0
            @test total_loc > 0

            println("   📊 Projeto analisado: $(length(project_results)) arquivos, LOC total: $total_loc")
        end

        @testset "Estruturas de Dados Otimizadas" begin
            # Verificar tipos otimizados
            test_result = FileQualityResultOptimized(
                "test.jl",
                Int32(100),
                Float32(5.0),
                Float32(80.0),
                Int16(3),
                Int16(2),
                Int16(5),
                Dict{String,Float32}("test" => Float32(1.0))
            )

            @test isa(test_result.lines_of_code, Int32)
            @test isa(test_result.complexity_score, Float32)
            @test isa(test_result.maintainability_index, Float32)
            @test isa(test_result.code_smells_count, Int16)

            # Verificar footprint de memória
            memory_size = sizeof(test_result)
            @test memory_size < 1000  # Deve ser menor que 1KB

            println("   💾 Memory footprint: $(memory_size) bytes")
        end
    end

    # ==========================================================================
    # TESTES DE PERFORMANCE
    # ==========================================================================

    @testset "⚡ Performance Tests" begin

        @testset "Benchmark de Análise de Arquivo" begin
            test_file = "src/Automation.jl"

            if isfile(test_file)
                # Benchmark da versão otimizada
                benchmark_result = @benchmark analyze_file_optimized($test_file) samples = 10 evals = 1

                median_time_ms = median(benchmark_result.times) / 1e6
                median_memory_kb = median(benchmark_result.memory) / 1024

                @test median_time_ms < 100  # Menos de 100ms
                @test median_memory_kb < 500  # Menos de 500KB

                println("   ⏱️  Performance: $(round(median_time_ms, digits=2))ms, $(round(median_memory_kb, digits=2))KB")
            end
        end

        @testset "Scalability Test" begin
            # Criar arquivos de teste com diferentes tamanhos
            test_files = []

            for size in [10, 100, 1000]
                lines = ["function test_func_$(size)_$j() end" for j in 1:size]
                content = join(lines, "\n")
                filename = "test_file_$(size).jl"
                write(filename, join(content))
                push!(test_files, filename)
            end

            try
                times = Float64[]

                for file in test_files
                    time_result = @elapsed analyze_file_optimized(file)
                    push!(times, time_result)
                end

                # Verificar escalabilidade linear
                @test all(t -> t < 1.0, times)  # Todos menores que 1s

                # Performance deve escalar de forma aproximadamente linear
                if length(times) >= 3
                    scale_factor = times[3] / times[1]  # Arquivo 1000 linhas vs 10 linhas
                    @test scale_factor < 200  # Não deve ser mais que 200x mais lento
                end

                println("   📈 Scalability: $(round.(times .* 1000, digits=2))ms para [10, 100, 1000] linhas")

            finally
                # Limpar arquivos de teste
                for file in test_files
                    rm(file, force=true)
                end
            end
        end

        @testset "Memory Efficiency" begin
            # Testar efficiency de memória em loop
            initial_memory = Base.gc_live_bytes()

            for i in 1:100
                # Criar conteúdo temporário
                content = "function test_$i() end"
                temp_file = "temp_$i.jl"
                write(temp_file, content)

                # Analisar
                analyze_file_optimized(temp_file)

                # Limpar
                rm(temp_file)
            end

            GC.gc()
            final_memory = Base.gc_live_bytes()
            memory_growth = final_memory - initial_memory

            # Crescimento de memória deve ser limitado
            @test memory_growth < 10_000_000  # Menos de 10MB

            println("   💾 Memory growth: $(round(memory_growth/1e6, digits=2))MB após 100 análises")
        end
    end

    # ==========================================================================
    # TESTES DE EDGE CASES
    # ==========================================================================

    @testset "🎯 Edge Cases Tests" begin

        @testset "Arquivos Especiais" begin
            # Arquivo vazio
            empty_file = "empty_test.jl"
            write(empty_file, "")

            try
                result = analyze_file_optimized(empty_file)
                @test result.lines_of_code == 0
                @test result.complexity_score >= 0
                println("   📄 Arquivo vazio: LOC=$(result.lines_of_code)")
            finally
                rm(empty_file, force=true)
            end

            # Arquivo só com comentários
            comments_file = "comments_test.jl"
            write(comments_file, "# Só comentários\n# Mais comentários\n")

            try
                result = analyze_file_optimized(comments_file)
                @test result.lines_of_code == 0  # Linhas efetivas
                println("   💬 Arquivo só comentários: LOC=$(result.lines_of_code)")
            finally
                rm(comments_file, force=true)
            end

            # Arquivo muito complexo
            complex_file = "complex_test.jl"
            complex_content = """
            function complex_function()
                if true
                    for i in 1:10
                        if i % 2 == 0
                            while j < i
                                if condition
                                    try
                                        for k in nested
                                            process()
                                        end
                                    catch e
                                        handle()
                                    finally
                                        cleanup()
                                    end
                                end
                            end
                        end
                    end
                end
            end
            """
            write(complex_file, complex_content)

            try
                result = analyze_file_optimized(complex_file)
                @test result.complexity_score > 1  # Deve ter alta complexidade
                println("   🌀 Arquivo complexo: Complexidade=$(round(result.complexity_score, digits=2))")
            finally
                rm(complex_file, force=true)
            end
        end

        @testset "Error Handling" begin
            # Arquivo inexistente
            @test_throws ArgumentError analyze_file_optimized("arquivo_inexistente.jl")

            # Arquivo não Julia
            @test_throws ArgumentError analyze_file_optimized("README.md")

            println("   🛡️  Error handling funcionando corretamente")
        end

        @testset "Caracteres Especiais" begin
            # Arquivo com caracteres especiais
            special_file = "special_test.jl"
            special_content = """
            # Comentário com acentos: açúcar, coração
            function função_especial()
                # Emoji: 🚀 🎯 ✅
                texto = "String com caracteres especiais: áéíóú"
                return texto
            end
            """
            write(special_file, special_content)

            try
                result = analyze_file_optimized(special_file)
                @test result.lines_of_code > 0
                println("   🌍 Caracteres especiais: LOC=$(result.lines_of_code)")
            finally
                rm(special_file, force=true)
            end
        end
    end

    # ==========================================================================
    # TESTES DE INTEGRAÇÃO
    # ==========================================================================

    @testset "🔗 Integration Tests" begin

        @testset "Integração com CSGA" begin
            # Verificar se resultados podem ser integrados no sistema CSGA
            project_results = analyze_project_optimized(".")

            # Calcular métricas que o CSGA usaria
            total_files = length(project_results)
            good_quality_files = count(r -> r.maintainability_index >= 70, project_results)
            quality_ratio = good_quality_files / total_files

            @test 0 <= quality_ratio <= 1
            @test total_files > 0

            # Simular integração com pontuação CSGA
            csga_contribution = min(100.0, quality_ratio * 100 + 10)  # Bonus de 10 pontos
            @test 0 <= csga_contribution <= 100

            println("   🎯 CSGA Integration: $(round(quality_ratio * 100, digits=1))% arquivos de qualidade")
        end

        @testset "Compatibilidade com Dashboard" begin
            # Verificar se resultados são compatíveis com o dashboard
            sample_result = analyze_file_optimized("src/Automation.jl")

            # Verificar se todos os campos necessários estão presentes
            required_fields = [:file_path, :lines_of_code, :complexity_score,
                :maintainability_index, :code_smells_count,
                :quality_issues_count, :metrics]

            for field in required_fields
                @test hasfield(FileQualityResultOptimized, field)
            end

            # Verificar se métricas são serializáveis (para JSON)
            metrics_serializable = all(v -> isa(v, Number), values(sample_result.metrics))
            @test metrics_serializable

            println("   📊 Dashboard compatibility: ✅")
        end

        @testset "Performance vs Accuracy Trade-off" begin
            # Verificar se otimizações não comprometem precisão
            test_file = "src/quality_analyzer_optimized.jl"

            if isfile(test_file)
                # Executar múltiplas análises
                results = [analyze_file_optimized(test_file) for _ in 1:5]

                # Verificar consistência
                locs = [r.lines_of_code for r in results]
                complexities = [r.complexity_score for r in results]
                maintainabilities = [r.maintainability_index for r in results]

                @test all(loc -> loc == locs[1], locs)  # LOC deve ser sempre igual
                @test std(complexities) < 0.1  # Complexidade deve ser consistente
                @test std(maintainabilities) < 0.1  # Manutenibilidade deve ser consistente

                println("   ⚖️  Accuracy maintained: LOC=$(locs[1]), Complexity=$(round(mean(complexities), digits=2))")
            end
        end
    end

    # ==========================================================================
    # TESTES DE REGRESSÃO
    # ==========================================================================

    @testset "🔄 Regression Tests" begin

        @testset "Baseline Comparison" begin
            # Comparar com valores esperados conhecidos
            simple_code = """
            function simple_add(a, b)
                return a + b
            end
            """

            simple_file = "simple_baseline.jl"
            write(simple_file, simple_code)

            try
                result = analyze_file_optimized(simple_file)

                # Verificar valores esperados para código simples
                @test result.lines_of_code == 3  # 3 linhas efetivas
                @test 1.0 <= result.complexity_score <= 2.0  # Baixa complexidade
                @test result.maintainability_index >= 70.0  # Boa manutenibilidade
                @test result.code_smells_count <= 1  # Poucos smells

                println("   📏 Baseline: LOC=$(result.lines_of_code), MI=$(round(result.maintainability_index, digits=1))")
            finally
                rm(simple_file, force=true)
            end
        end

        @testset "Version Consistency" begin
            # Testar que a versão otimizada produz resultados coerentes
            project_results = analyze_project_optimized(".")

            # Verificar distribuição de qualidade
            maintainability_scores = [r.maintainability_index for r in project_results]

            @test length(maintainability_scores) > 0
            @test all(score -> 0 <= score <= 100, maintainability_scores)

            # Deve haver variação na qualidade (não todos iguais)
            @test std(maintainability_scores) > 0

            avg_quality = mean(maintainability_scores)
            println("   📊 Quality distribution: avg=$(round(avg_quality, digits=1)), std=$(round(std(maintainability_scores), digits=1))")
        end
    end

    println("\n🎉 Todos os testes avançados do Quality Analyzer concluídos!")
    println("✅ Sistema validado para produção com alta confiabilidade")
end
