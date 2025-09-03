"""
Performance Tests - Validação de Performance CSGA
Testes para garantir que o sistema mantenha performance adequada
"""

using Test
using BenchmarkTools
using Statistics

@testset "🚀 Performance Validation Tests" begin
    println("\n⚡ Executando Performance Validation Tests...")

    # ==========================================================================
    # TESTE DE PERFORMANCE BÁSICA
    # ==========================================================================
    @testset "⏱️ Basic Performance Test" begin
        # Testar tempo de execução da função principal
        result = @benchmark Automation.evaluate_project(".") samples = 10

        median_time = median(result.times)
        mean_time = mean(result.times)

        # Verificar que a avaliação não demora mais que 30 segundos
        @test median_time < 30_000_000_000  # 30 segundos em nanossegundos
        @test mean_time < 45_000_000_000    # 45 segundos em nanossegundos

        println("   ⏱️  Tempo mediano: $(round(median_time/1e9, digits=2))s")
        println("   ⏱️  Tempo médio: $(round(mean_time/1e9, digits=2))s")
    end

    # ==========================================================================
    # TESTE DE ESCALABILIDADE
    # ==========================================================================
    @testset "📈 Scalability Test" begin
        # Criar arquivos de teste temporários para verificar escalabilidade
        test_files = String[]
        try
            # Criar 100 arquivos pequenos
            for i in 1:100
                temp_file = tempname()
                open(temp_file, "w") do f
                    write(f, "function test_function_$i()\n    return $i\nend\n")
                end
                push!(test_files, temp_file)
            end

            # Medir tempo para processar muitos arquivos
            result = @benchmark Automation.QualityAnalyzerOptimized.analyze_files($test_files) samples = 5

            median_time = median(result.times)
            memory_usage = Base.gc_live_bytes()

            # Verificar escalabilidade
            @test median_time < 10_000_000_000  # 10 segundos para 100 arquivos
            @test memory_usage < 100_000_000     # Menos de 100MB de memória

            println("   📈 Processados 100 arquivos em $(round(median_time/1e9, digits=2))s")
            println("   💾 Uso de memória: $(round(memory_usage/1e6, digits=2))MB")

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

    # ==========================================================================
    # TESTE DE EFICIÊNCIA DE MEMÓRIA
    # ==========================================================================
    @testset "💾 Memory Efficiency Test" begin
        # Testar uso de memória durante avaliações repetidas
        initial_memory = Base.gc_live_bytes()

        # Executar várias avaliações
        for i in 1:10
            Automation.evaluate_project(".")
        end

        GC.gc()  # Forçar coleta de lixo
        final_memory = Base.gc_live_bytes()

        memory_growth = final_memory - initial_memory

        # Verificar que não há crescimento excessivo de memória
        @test memory_growth < 50_000_000  # Menos de 50MB de crescimento

        println("   💾 Crescimento de memória: $(round(memory_growth/1e6, digits=2))MB")
    end

    println("✅ Performance Validation Tests completed!")
end
