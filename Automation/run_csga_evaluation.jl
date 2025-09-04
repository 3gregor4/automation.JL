#!/usr/bin/env julia

"""
Script de demonstração do Sistema CSGA
Executa avaliação completa do projeto Automation
"""

# Adicionar o diretório src ao load path
push!(LOAD_PATH, joinpath(@__DIR__, "src"))

# Corrigir importação do módulo
using Automation

function main()
    println("🚀 INICIANDO AVALIAÇÃO CSGA DO PROJETO AUTOMATION")
    println("="^60)

    # Caminho do projeto atual
    project_path = @__DIR__

    # Verificar se o diretório do projeto existe
    if !isdir(project_path)
        println("❌ Diretório do projeto não encontrado: $project_path")
        return 1
    end

    try
        # Executar avaliação completa
        println("📊 Executando avaliação dos 4 pilares...")
        csga_score = evaluate_project(project_path)

        # Exibir relatório detalhado
        print_detailed_report(csga_score)

        # Gerar relatório em JSON
        json_report = generate_report(csga_score, :json)
        json_file = joinpath(project_path, "csga_report.json")
        open(json_file, "w") do f
            write(f, json_report)
        end
        println("\n📄 Relatório JSON salvo em: $json_file")

        # Gerar relatório em Markdown
        md_report = generate_report(csga_score, :markup)
        md_file = joinpath(project_path, "CSGA_REPORT.md")
        open(md_file, "w") do f
            write(f, md_report)
        end
        println("📄 Relatório Markdown salvo em: $md_file")

        # Resumo executivo
        println("\n🎯 RESUMO EXECUTIVO:")
        println("Score Geral: $(round(csga_score.overall_score, digits=1))/100")
        println("Nível: $(csga_score.maturity_level)")
        println("Status: $(csga_score.compliance_status)")

        # Recomendações prioritárias
        all_recommendations = vcat(
            csga_score.security_pillar.recommendations,
            csga_score.clean_code_pillar.recommendations,
            csga_score.green_code_pillar.recommendations,
            csga_score.automation_pillar.recommendations,
        )

        if !isempty(all_recommendations)
            println("\n💡 PRÓXIMOS PASSOS:")
            for (i, rec) in enumerate(unique(all_recommendations)[1:min(3, end)])
                println("  $(i). $rec")
            end
        end

        println("\n✅ Avaliação CSGA concluída com sucesso!")

    catch e
        println("❌ Erro durante a avaliação:")
        println(e)
        return 1
    end

    return 0
end

# Executar se este arquivo for chamado diretamente
if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
