"""
RunTests.jl - Coordenador de Testes Modulares CSGA
Estrutura modular para os 4 pilares fundamentais:
- Security First (30%)
- Clean Code (25%)
- Green Code (20%)
- Advanced Automation (25%)

Objetivo: Elevar testing_automation de 65.0 → 95.0 pontos
Target Score: 87.4/100 (Expert)
"""

using Test
using Automation
using Statistics
using DataFrames
using BenchmarkTools
using Dates
using JSON3
using TOML

# Função de validação CSGA incremental
function validate_csga_score(test_phase::String)
    println("\n🔍 Validação CSGA - $test_phase")
    try
        # Usar a função unificada para resolver o caminho do projeto
        project_path = Automation.resolve_project_path(pwd())
        println("   📁 Caminho do projeto: $project_path")

        # Verificar se o arquivo Project.toml existe
        project_file = joinpath(project_path, "Project.toml")
        println("   📄 Project.toml existe: $(isfile(project_file))")

        # Listar arquivos no diretório para verificar estrutura
        if isdir(project_path)
            files = readdir(project_path)
            println("   📂 Arquivos no diretório: $(join(files[1:min(5, end)], ", "))")
        end

        score = Automation.evaluate_project(project_path)
        println(
            "   Score Atual: $(round(score.overall_score, digits=1))/100 ($(score.maturity_level))",
        )
        println(
            "   Testing Automation: $(get(score.automation_pillar.metrics, "testing_automation", 0.0))/100",
        )
        return score
    catch e
        println("   ⚠️  Erro na validação: $e")
        # Mostrar stacktrace completo para depuração
        showerror(stdout, e, catch_backtrace())
        return nothing
    end
end

# Função de relatório de progresso
function generate_test_progress_report(scores::Vector)
    if length(scores) >= 2
        initial = scores[1].overall_score
        current = scores[end].overall_score
        improvement = round(current - initial, digits=1)

        println("\n📈 PROGRESSO DOS TESTES")
        println("="^40)
        println("Score Inicial: $(round(initial, digits=1))/100")
        println("Score Atual: $(round(current, digits=1))/100")
        println("Melhoria: +$(improvement) pontos")

        # Projeção para meta
        target = 87.4
        remaining = target - current
        println("Meta Expert: $target/100")
        println("Restante: $(round(remaining, digits=1)) pontos")
    end
end

# =============================================================================
# SUITE PRINCIPAL DE TESTES MODULARES
# =============================================================================

@testset "🎯 CSGA Testing Suite - Modular Architecture" begin

    # Vector para tracking de scores
    csga_scores = []

    # Score inicial
    println("\n🚀 Iniciando Suite de Testes CSGA...")
    initial_score = validate_csga_score("Baseline Inicial")
    if initial_score !== nothing
        push!(csga_scores, initial_score)
    end

    # ==========================================================================
    # PILAR 1: SECURITY FIRST (30% do peso total)
    # ==========================================================================
    @testset "🔒 Security First Pillar (30%)" begin
        include("test_security_pillar.jl")

        # Validação pós Security
        score = validate_csga_score("Pós-Security Tests")
        if score !== nothing
            push!(csga_scores, score)
        end
    end

    # ==========================================================================
    # PILAR 2: CLEAN CODE (25% do peso total)
    # ==========================================================================
    @testset "✨ Clean Code Pillar (25%)" begin
        include("test_clean_code_pillar.jl")

        # Validação pós Clean Code
        score = validate_csga_score("Pós-Clean Code Tests")
        if score !== nothing
            push!(csga_scores, score)
        end
    end

    # ==========================================================================
    # PILAR 3: GREEN CODE (20% do peso total)
    # ==========================================================================
    @testset "🌱 Green Code Pillar (20%)" begin
        include("test_green_code_pillar.jl")

        # Validação pós Green Code
        score = validate_csga_score("Pós-Green Code Tests")
        if score !== nothing
            push!(csga_scores, score)
        end
    end

    # ==========================================================================
    # PILAR 4: ADVANCED AUTOMATION (25% do peso total)
    # ==========================================================================
    @testset "🤖 Advanced Automation Pillar (25%)" begin
        include("test_automation_pillar.jl")

        # Validação pós Automation
        score = validate_csga_score("Pós-Automation Tests")
        if score !== nothing
            push!(csga_scores, score)
        end
    end

    # ==========================================================================
    # TESTES DE INTEGRAÇÃO FINAL
    # ==========================================================================
    @testset "🔗 Integration & Final Validation" begin
        include("test_integration.jl")

        # Score final
        final_score = validate_csga_score("Final Score")
        if final_score !== nothing
            push!(csga_scores, final_score)
        end
    end

    # ==========================================================================
    # RELATÓRIO FINAL DE PROGRESSO
    # ==========================================================================
    if length(csga_scores) > 0
        println("\n" * "="^60)
        println("🏆 RELATÓRIO FINAL - TESTES MODULARES CSGA")
        println("="^60)

        generate_test_progress_report(csga_scores)

        # Verificação da meta
        final_score_val = nothing
        if length(csga_scores) > 0
            final_score_val = csga_scores[end]
        end

        if final_score_val !== nothing && final_score_val.overall_score >= 87.4
            println("\n✅ META ATINGIDA! Nível Expert alcançado!")
            println("🎯 Testing Automation otimizado com sucesso!")
        else
            println("\n⚠️  Meta Expert ainda não atingida. Continuar otimização.")
        end

        println("\n📊 Score Final: $(round(csga_scores[end].overall_score, digits=1))/100")
        println("🔧 Implementação: Testes Modulares CSGA")
        println("📅 Timestamp: $(now())")
    end
end
