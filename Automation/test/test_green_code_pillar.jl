"""
Teste do Pilar Green Code - Pilar 3: Código Verde (20%)
Testes específicos para validação do pilar de código verde CSGA

Objetivos:
- Validar Performance Infrastructure Score (40 pontos)
- Validar Code Efficiency Score (35 pontos)
- Validar Resource Management Score (25 pontos)
- Garantir eficiência e sustentabilidade do código
"""

using Test
using BenchmarkTools
using Statistics

@testset "🌱 Validação do Pilar Código Verde" begin
    println("\n🌱 Avaliando Pilar Código Verde...")

    # ==========================================================================
    # TESTE 1: PERFORMANCE INFRASTRUCTURE SCORE (40 pontos)
    # ==========================================================================
    @testset "🚀 Performance Infrastructure Score" begin
        @testset "BenchmarkTools Integration" begin
            # Verificar se BenchmarkTools está disponível
            @test isdefined(Main, :BenchmarkTools) == true

            # Teste básico de benchmark
            simple_function = () -> sum(1:1000)
            result = @benchmark $simple_function()

            @test !isempty(result.times) == true
            @test median(result.times) > 0

            println("   ✅ BenchmarkTools funcional")
        end

        @testset "Performance Efficiency Score Calculation" begin
            # Usar a função unificada para resolver o caminho do projeto
            project_path = Automation.resolve_project_path(pwd())
            println("   📁 Caminho do projeto: $project_path")
            
            score = Automation.CSGAScoring.evaluate_performance_infrastructure(project_path)
            @test score >= 70.0
            @test score <= 100.0

            println("   ✅ Performance Infrastructure Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 2: CODE EFFICIENCY SCORE (35 pontos)
    # ==========================================================================
    @testset "⚡ Code Efficiency Score" begin
        @testset "Algorithm Efficiency" begin
            # Teste de algoritmo eficiente vs ineficiente
            efficient_algo = (n) -> sum(1:n)
            inefficient_algo = (n) -> begin
                result = 0
                for i in 1:n
                    for j in 1:min(10, n)  # Limitar para evitar explosão
                        result += i
                    end
                end
                return result
            end

            efficient_result = @benchmark $efficient_algo(1000)
            inefficient_result = @benchmark $inefficient_algo(100)  # Menor n para evitar timeout

            efficient_time = median(efficient_result.times)
            inefficient_time = median(inefficient_result.times)

            @test efficient_time > 0
            @test inefficient_time > 0

            println("   ⏱️  Algoritmo eficiente: $(round(efficient_time/1e6, digits=2))ms")
            println(
                "   ⏱️  Algoritmo menos eficiente: $(round(inefficient_time/1e6, digits=2))ms",
            )
        end

        @testset "Code Efficiency Score Calculation" begin
            # Usar a função unificada para resolver o caminho do projeto
            project_path = Automation.resolve_project_path(pwd())
            println("   📁 Caminho do projeto: $project_path")

            score = Automation.CSGAScoring.evaluate_code_efficiency(project_path)
            @test score >= 60.0
            @test score <= 100.0

            println("   ✅ Code Efficiency Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 3: RESOURCE MANAGEMENT SCORE (25 pontos)
    # ==========================================================================
    @testset "🔧 Resource Management Score" begin
        @testset "Memory Management" begin
            # Teste básico de gestão de memória
            initial_memory = Base.gc_live_bytes()

            # Operações que devem ser limpas
            for i in 1:100
                temp_array = rand(1000)
                temp_result = sum(temp_array)
            end

            GC.gc()  # Forçar garbage collection
            final_memory = Base.gc_live_bytes()

            memory_growth = final_memory - initial_memory
            @test memory_growth <= 50_000_000

            println("   💾 Crescimento de memória: $(round(memory_growth/1e6, digits=2))MB")
        end

        @testset "Resource Optimization" begin
            # Teste de otimização de recursos
            test_function = (n) -> begin
                data = Vector{Float64}(undef, n)
                for i in 1:n
                    data[i] = i * 1.0
                end
                return sum(data)
            end

            result = @benchmark $test_function(10000)
            allocations = result.allocs

            @test allocations <= 20

            println("   🔧 Alocações: $allocations")
        end

        @testset "Resource Management Score Calculation" begin
            # Usar a função unificada para resolver o caminho do projeto
            project_path = Automation.resolve_project_path(pwd())
            println("   📁 Caminho do projeto: $project_path")

            score = Automation.CSGAScoring.evaluate_resource_management(project_path)
            @test score >= 65.0
            @test score <= 100.0

            println("   ✅ Resource Management Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # VALIDAÇÃO INTEGRADA DO PILAR GREEN CODE
    # ==========================================================================
    @testset "🎯 Green Code Pillar Integration Test" begin

        # Avaliação completa do pilar
        # Usar a função unificada para resolver o caminho do projeto
        project_path = Automation.resolve_project_path(pwd())
        println("   📁 Caminho do projeto: $project_path")

        green_code_pillar = Automation.CSGAScoring.evaluate_green_code_pillar(project_path)

        @test green_code_pillar.name == "Green Code"
        @test green_code_pillar.weight == 0.20
        @test green_code_pillar.score >= 60.0
        @test green_code_pillar.score <= 100.0

        # Verificação das métricas componentes
        @test haskey(green_code_pillar.metrics, "performance_infrastructure")
        @test haskey(green_code_pillar.metrics, "code_efficiency")
        @test haskey(green_code_pillar.metrics, "resource_management")

        println("\n📊 RESUMO GREEN CODE PILLAR:")
        println("   Score Geral: $(round(green_code_pillar.score, digits=1))/100")
        println("   Peso no CSGA: $(green_code_pillar.weight * 100)%")

        if !isempty(green_code_pillar.recommendations)
            println("\n💡 Recomendações:")
            for rec in green_code_pillar.recommendations
                println("   • $rec")
            end
        end

        if !isempty(green_code_pillar.critical_issues)
            println("\n⚠️  Questões Críticas:")
            for issue in green_code_pillar.critical_issues
                println("   • $issue")
            end
        end
    end

    println("✅ Green Code Pillar validation completed!")
end
