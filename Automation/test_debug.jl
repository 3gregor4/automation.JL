#!/usr/bin/env julia

using Automation

println("🔍 Teste de depuração - Avaliação CSGA")
println("="^50)

# Mostrar o diretório atual
current_dir = pwd()
println("📁 Diretório atual: $current_dir")

# Verificar se Project.toml existe
project_file = joinpath(current_dir, "Project.toml")
println("📄 Project.toml existe: $(isfile(project_file))")

# Listar arquivos no diretório
files = readdir(current_dir)
println("📂 Arquivos no diretório: $(join(files[1:min(10, end)], ", "))")

# Executar avaliação
println("\n📊 Executando avaliação...")
score = Automation.evaluate_project(current_dir)

println("\n📈 Resultados:")
println("   Score Geral: $(round(score.overall_score, digits=1))/100 ($(score.maturity_level))")
println("   Testing Automation: $(get(score.automation_pillar.metrics, "testing_automation", 0.0))/100")
