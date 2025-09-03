"""
Performance Tests - Validação de Performance CSGA
Testes específicos de performance para o pilar Green Code

Objetivos:
- Validar performance das funções CSGA
- Benchmarks de avaliação dos pilares
- Testes de eficiência do sistema
"""

using Test
using BenchmarkTools
using Automation

@testset "🚀 Performance Tests" begin
    println("\n⚡ Executando Performance Tests...")

    @testset "CSGA Evaluation Performance" begin
        # Benchmark da avaliação CSGA completa
        result = @benchmark Automation.evaluate_project(".")

        median_time = median(result.times) / 1e9  # Converter para segundos
        @test median_time <= 10.0 "Avaliação CSGA deve completar em ≤ 10 segundos"

        println("   ⏱️  Tempo médio avaliação CSGA: $(round(median_time, digits=3))s")

        # Verificar memória alocada
        median_memory = median(result.memory)
        @test median_memory <= 200_000_000 "Avaliação CSGA deve usar ≤ 200MB"

        println("   💾 Memória média: $(round(median_memory/1e6, digits=1))MB")
    end

    @testset "Individual Pillar Performance" begin
        # Benchmark das funções de scoring individual
        pillars = [
            ("Security", () -> Automation.CSGAScoring.evaluate_security_pillar(".")),
            ("Clean Code", () -> Automation.CSGAScoring.evaluate_clean_code_pillar(".")),
            ("Green Code", () -> Automation.CSGAScoring.evaluate_green_code_pillar(".")),
            ("Automation", () -> Automation.CSGAScoring.evaluate_automation_pillar(".")),
        ]

        for (name, func) in pillars
            result = @benchmark $func()
            median_time = median(result.times) / 1e9

            @test median_time <= 5.0 "Avaliação do pilar $name deve completar em ≤ 5 segundos"

            println("   ⏱️  $name pillar: $(round(median_time, digits=3))s")
        end
    end

    println("✅ Performance Tests completed!")
end
