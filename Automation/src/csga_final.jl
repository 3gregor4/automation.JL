# =============================================================================
# PILAR 4: ADVANCED AUTOMATION (Peso: 25%) E FUNÇÕES PRINCIPAIS
# =============================================================================

# =============================================================================
# PILAR 4: ADVANCED AUTOMATION (Peso: 25%)
# =============================================================================

function evaluate_automation_pillar(project_path::String)::PillarScore
    metrics = Dict{String,Float64}()
    recommendations = String[]
    critical_issues = String[]

    # 1. CI/CD Infrastructure Score (30 pontos)
    cicd_score = evaluate_cicd_infrastructure(project_path)
    metrics["cicd_infrastructure"] = cicd_score

    if cicd_score < 60
        push!(critical_issues, "Infraestrutura de CI/CD ausente")
        push!(recommendations, "Implementar Makefile com targets essenciais")
    end

    # 2. Testing Automation Score (30 pontos)
    testing_score = evaluate_testing_automation(project_path)
    metrics["testing_automation"] = testing_score

    if testing_score < 70
        push!(critical_issues, "Testes automatizados insuficientes")
        push!(recommendations, "Estruturar testes conforme padrão modular")
    end

    # 3. Quality Automation Score (25 pontos)
    quality_score = evaluate_quality_automation(project_path)
    metrics["quality_automation"] = quality_score

    if quality_score < 50
        push!(recommendations, "Implementar formatação e lint automático")
    end

    # 4. AGENTS.md Integration Score (15 pontos)
    agents_score = evaluate_agents_integration(project_path)
    metrics["agents_integration"] = agents_score

    if agents_score < 40
        push!(recommendations, "Criar AGENTS.md para integração com ferramentas IA")
    end

    final_score = (
        cicd_score * 0.30 +
        testing_score * 0.30 +
        quality_score * 0.25 +
        agents_score * 0.15
    )

    return PillarScore(
        "Advanced Automation",
        final_score,
        0.25,  # 25% do peso total conforme memória
        metrics,
        recommendations,
        critical_issues,
    )
end

function evaluate_cicd_infrastructure(project_path::String)::Float64
    score = 0.0

    # Makefile com targets essenciais conforme memória (50 pontos)
    makefile_path = joinpath(project_path, "Makefile")
    if isfile(makefile_path)
        try
            makefile_content = Automation.safe_file_read(makefile_path)
            essential_targets = ["test", "dev", "pluto", "clean", "format"]  # Conforme memória

            for target in essential_targets
                if occursin(Regex("^$(target):", "m"), makefile_content)
                    score += 10.0  # 50/5 pontos por target
                end
            end
        catch e
            score += 5.0
        end
    end

    # Project.toml e Manifest.toml (25 pontos)
    project_file = joinpath(project_path, "Project.toml")
    manifest_file = joinpath(project_path, "Manifest.toml")

    if isfile(project_file) && isfile(manifest_file)
        score += 25.0
    elseif isfile(project_file)
        score += 15.0
    end

    # Git repository inicializado (25 pontos)
    git_dir = joinpath(project_path, ".git")
    if isdir(git_dir)
        score += 25.0
    end

    return min(100.0, score)
end

function evaluate_testing_automation(project_path::String)::Float64
    score = 0.0

    # Diretório test/ existe conforme estrutura da memória (25 pontos)
    test_dir = joinpath(project_path, "test")
    if isdir(test_dir)
        score += 25.0

        # runtests.jl existe (25 pontos)
        runtests_file = joinpath(test_dir, "runtests.jl")
        if isfile(runtests_file)
            score += 25.0
        end

        # Múltiplos arquivos de teste (estrutura modular) (25 pontos)
        try
            test_files = filter(f -> endswith(f, ".jl"), readdir(test_dir))
            if length(test_files) > 1  # Mais de um arquivo = estrutura modular
                score += 25.0
            elseif length(test_files) == 1
                score += 15.0
            end
        catch e
            # Ignorar erro
        end
    end

    # Makefile com target test conforme memória (25 pontos)
    makefile_path = joinpath(project_path, "Makefile")
    if isfile(makefile_path)
        try
            makefile_content = Automation.safe_file_read(makefile_path)
            if occursin(r"^test:"m, makefile_content)
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    return min(100.0, score)
end

function evaluate_quality_automation(project_path::String)::Float64
    score = 0.0

    # Makefile com target format conforme memória (25 pontos)
    makefile_path = joinpath(project_path, "Makefile")
    if isfile(makefile_path)
        try
            makefile_content = Automation.safe_file_read(makefile_path)
            if occursin(r"^format:", makefile_content)
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    # .vscode/ configuração conforme memória (25 pontos)
    vscode_dir = joinpath(project_path, ".vscode")
    if isdir(vscode_dir)
        score += 25.0
    end

    # Git hooks para pre-commit conforme memória (25 pontos)
    git_hooks_dir = joinpath(project_path, ".git", "hooks")
    if isdir(git_hooks_dir)
        try
            hooks = readdir(git_hooks_dir)
            if any(h -> occursin("pre-commit", h), hooks)
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    # Estrutura de diretórios completa conforme memória (25 pontos)
    recommended_dirs = ["docs", "examples", "benchmarks", "notebooks"]
    existing_dirs = count(dir -> isdir(joinpath(project_path, dir)), recommended_dirs)
    # Proteção contra divisão por zero
    dir_ratio = if length(recommended_dirs) > 0
        existing_dirs / length(recommended_dirs)
    else
        0.0
    end
    score += dir_ratio * 25.0

    return min(100.0, score)
end

function evaluate_agents_integration(project_path::String)::Float64
    score = 0.0

    # AGENTS.md existe conforme especificação híbrida (60 pontos)
    agents_file = joinpath(project_path, "AGENTS.md")
    if isfile(agents_file)
        try
            agents_content = Automation.safe_file_read(agents_file)

            # Verifica seções essenciais
            required_sections = ["Security", "Clean Code", "Green Code", "Automation"]
            section_score = 0

            for section in required_sections
                if occursin(section, agents_content)
                    section_score += 15  # 60/4 pontos por seção
                end
            end

            score += section_score
        catch e
            score += 10.0
        end
    end

    # Comandos executáveis no AGENTS.md (40 pontos)
    if isfile(agents_file)
        try
            agents_content = Automation.safe_file_read(agents_file)

            # Verifica presença de comandos make
            make_commands = ["make test", "make format", "make clean", "make dev"]
            command_score = 0

            for cmd in make_commands
                if occursin(cmd, agents_content)
                    command_score += 10  # 40/4 pontos por comando
                end
            end

            score += command_score
        catch e
            # Ignorar erro
        end
    end

    return min(100.0, score)
end

"""
    validate_weighted_score_calculation(pillars::Vector{PillarScore}) -> Bool

Valida se o cálculo da pontuação ponderada está correto
"""
function validate_weighted_score_calculation(pillars::Vector{PillarScore})::Bool
    # Verificar se todos os pesos somam 1.0 (com pequena margem de erro)
    total_weight = sum(pillar.weight for pillar in pillars)
    weight_valid = abs(total_weight - 1.0) < 0.001
    
    if !weight_valid
        @warn "Soma dos pesos dos pilares não é 1.0: $total_weight"
        return false
    end
    
    # Verificar se todos os scores estão na faixa válida (0-100)
    for pillar in pillars
        if pillar.score < 0.0 || pillar.score > 100.0
            @warn "Score inválido para pilar $(pillar.name): $(pillar.score)"
            return false
        end
        
        # Verificar se as métricas estão na faixa válida
        for (metric_name, metric_value) in pillar.metrics
            if metric_value < 0.0 || metric_value > 100.0
                @warn "Valor de métrica inválido para $(pillar.name).$metric_name: $metric_value"
                return false
            end
        end
    end
    
    @debug "Validação de cálculo ponderado passou com sucesso"
    return true
end

"""
    evaluate_project(project_path::String) -> CSGAScore

Avalia um projeto Julia usando o framework CSGA híbrido
"""
function evaluate_project(project_path::String)::CSGAScore
    if !isdir(project_path)
        throw(ArgumentError("Caminho do projeto não existe: $project_path"))
    end

    @debug "Iniciando avaliação CSGA para o projeto: $project_path"
    
    # Determinar nome do projeto
    project_name = basename(project_path)
    project_file = joinpath(project_path, "Project.toml")

    if isfile(project_file)
        try
            project_data = TOML.parsefile(project_file)
            project_name = get(project_data, "name", project_name)
            @debug "Nome do projeto determinado: $project_name"
        catch e
            # Usar nome do diretório se Project.toml não pode ser lido
            @warn "Não foi possível ler Project.toml: $e"
        end
    end

    # Inicializar variáveis para os pilares
    local security_pillar, clean_code_pillar, green_code_pillar, automation_pillar
    
    # Avaliar cada pilar com mecanismos de fallback
    @debug "Avaliando pilar de segurança..."
    try
        security_pillar = evaluate_security_pillar(project_path)
        @debug "Pilar de segurança avaliado: $(round(security_pillar.score, digits=1))/100"
    catch e
        @warn "Erro avaliando pilar de segurança: $e"
        security_pillar = PillarScore(
            "Security First", 
            0.0, 
            0.30, 
            Dict{String,Float64}(), 
            ["Erro na avaliação do pilar de segurança"], 
            ["Exceção durante avaliação: $e"]
        )
    end

    @debug "Avaliando pilar de código limpo..."
    try
        clean_code_pillar = evaluate_clean_code_pillar(project_path)
        @debug "Pilar de código limpo avaliado: $(round(clean_code_pillar.score, digits=1))/100"
    catch e
        @warn "Erro avaliando pilar de código limpo: $e"
        clean_code_pillar = PillarScore(
            "Clean Code", 
            0.0, 
            0.25, 
            Dict{String,Float64}(), 
            ["Erro na avaliação do pilar de código limpo"], 
            ["Exceção durante avaliação: $e"]
        )
    end

    @debug "Avaliando pilar de código verde..."
    try
        green_code_pillar = evaluate_green_code_pillar(project_path)
        @debug "Pilar de código verde avaliado: $(round(green_code_pillar.score, digits=1))/100"
    catch e
        @warn "Erro avaliando pilar de código verde: $e"
        green_code_pillar = PillarScore(
            "Green Code", 
            0.0, 
            0.20, 
            Dict{String,Float64}(), 
            ["Erro na avaliação do pilar de código verde"], 
            ["Exceção durante avaliação: $e"]
        )
    end

    @debug "Avaliando pilar de automação..."
    try
        automation_pillar = evaluate_automation_pillar(project_path)
        @debug "Pilar de automação avaliado: $(round(automation_pillar.score, digits=1))/100"
        
        # Log específico para testing automation
        testing_automation = get(automation_pillar.metrics, "testing_automation", 0.0)
        @debug "Testing Automation Score: $(round(testing_automation, digits=1))/100"
    catch e
        @warn "Erro avaliando pilar de automação: $e"
        automation_pillar = PillarScore(
            "Advanced Automation", 
            0.0, 
            0.25, 
            Dict{String,Float64}(), 
            ["Erro na avaliação do pilar de automação"], 
            ["Exceção durante avaliação: $e"]
        )
    end

    # Validar cálculo ponderado antes de prosseguir
    pillars = [security_pillar, clean_code_pillar, green_code_pillar, automation_pillar]
    if !validate_weighted_score_calculation(pillars)
        @warn "Falha na validação do cálculo ponderado - continuando com avaliação"
    end

    # Calcular pontuação geral ponderada conforme memória
    overall_score = (
        security_pillar.score * security_pillar.weight +
        clean_code_pillar.score * clean_code_pillar.weight +
        green_code_pillar.score * green_code_pillar.weight +
        automation_pillar.score * automation_pillar.weight
    )
    
    @debug "Score geral calculado: $(round(overall_score, digits=1))/100"

    # Determinar nível de maturidade
    maturity_level = if overall_score >= 87.4
        "Expert"
    elseif overall_score >= 75
        "Avançado"
    elseif overall_score >= 60
        "Intermediário"
    else
        "Iniciante"
    end

    # Determinar status de compliance
    compliance_status = if overall_score >= 80
        "Conforme"
    elseif overall_score >= 60
        "Não-conforme"
    else
        "Crítico"
    end

    @debug "Nível de maturidade: $maturity_level, Status de compliance: $compliance_status"

    return CSGAScore(
        project_name,
        now(),
        security_pillar,
        clean_code_pillar,
        green_code_pillar,
        automation_pillar,
        overall_score,
        maturity_level,
        compliance_status,
    )
end

"""
    print_detailed_report(csga_score::CSGAScore)

Imprime relatório detalhado da avaliação CSGA
"""
function print_detailed_report(csga_score::CSGAScore)
    println("\n" * "="^80)
    println("RELATÓRIO CSGA - SISTEMA DE AVALIAÇÃO JULIA")
    println("="^80)

    println("\n📊 INFORMAÇÕES GERAIS:")
    println("Projeto: $(csga_score.project_name)")
    println("Data/Hora: $(csga_score.timestamp)")
    println("Score Geral: $(round(csga_score.overall_score, digits=1))/100")
    println("Nível de Maturidade: $(csga_score.maturity_level)")
    println("Status de Compliance: $(csga_score.compliance_status)")

    println("\n📋 AVALIAÇÃO POR PILAR:")

    # Security First
    println("\n🛡️  SECURITY FIRST (Peso: 30%)")
    println("Score: $(round(csga_score.security_pillar.score, digits=1))/100")
    println("Métricas:")
    for (metric, value) in csga_score.security_pillar.metrics
        println("  • $metric: $(round(value, digits=1))")
    end
    if !isempty(csga_score.security_pillar.critical_issues)
        println("⚠️  Problemas Críticos:")
        for issue in csga_score.security_pillar.critical_issues
            println("  • $issue")
        end
    end
    if !isempty(csga_score.security_pillar.recommendations)
        println("💡 Recomendações:")
        for rec in csga_score.security_pillar.recommendations
            println("  • $rec")
        end
    end

    # Clean Code
    println("\n🧹 CLEAN CODE (Peso: 25%)")
    println("Score: $(round(csga_score.clean_code_pillar.score, digits=1))/100")
    println("Métricas:")
    for (metric, value) in csga_score.clean_code_pillar.metrics
        println("  • $metric: $(round(value, digits=1))")
    end
    if !isempty(csga_score.clean_code_pillar.critical_issues)
        println("⚠️  Problemas Críticos:")
        for issue in csga_score.clean_code_pillar.critical_issues
            println("  • $issue")
        end
    end
    if !isempty(csga_score.clean_code_pillar.recommendations)
        println("💡 Recomendações:")
        for rec in csga_score.clean_code_pillar.recommendations
            println("  • $rec")
        end
    end

    # Green Code
    println("\n🌱 GREEN CODE (Peso: 20%)")
    println("Score: $(round(csga_score.green_code_pillar.score, digits=1))/100")
    println("Métricas:")
    for (metric, value) in csga_score.green_code_pillar.metrics
        println("  • $metric: $(round(value, digits=1))")
    end
    if !isempty(csga_score.green_code_pillar.critical_issues)
        println("⚠️  Problemas Críticos:")
        for issue in csga_score.green_code_pillar.critical_issues
            println("  • $issue")
        end
    end
    if !isempty(csga_score.green_code_pillar.recommendations)
        println("💡 Recomendações:")
        for rec in csga_score.green_code_pillar.recommendations
            println("  • $rec")
        end
    end

    # Advanced Automation
    println("\n⚙️  ADVANCED AUTOMATION (Peso: 25%)")
    println("Score: $(round(csga_score.automation_pillar.score, digits=1))/100")
    println("Métricas:")
    for (metric, value) in csga_score.automation_pillar.metrics
        println("  • $metric: $(round(value, digits=1))")
    end
    if !isempty(csga_score.automation_pillar.critical_issues)
        println("⚠️  Problemas Críticos:")
        for issue in csga_score.automation_pillar.critical_issues
            println("  • $issue")
        end
    end
    if !isempty(csga_score.automation_pillar.recommendations)
        println("💡 Recomendações:")
        for rec in csga_score.automation_pillar.recommendations
            println("  • $rec")
        end
    end

    println("\n" * "="^80)
    println("🎯 RESUMO EXECUTIVO:")
    println(
        "Este projeto está no nível '$(csga_score.maturity_level)' com status '$(csga_score.compliance_status)'",
    )

    if csga_score.overall_score >= 80
        println("✅ Projeto em excelente estado, seguindo os 4 pilares CSGA!")
    elseif csga_score.overall_score >= 60
        println("⚠️  Projeto precisa de melhorias para atingir compliance total")
    else
        println("❌ Projeto requer atenção urgente em múltiplos pilares")
    end

    println("="^80)
end

"""
    generate_report(csga_score::CSGAScore, format::Symbol = :json) -> String

Gera relatório em formato especificado (:json, :toml, :markup)
"""
function generate_report(csga_score::CSGAScore, format::Symbol=:json)::String
    if format == :json
        return JSON3.write(csga_score, allow_inf=true)
    elseif format == :markup
        return generate_markdown_report(csga_score)
    else
        throw(ArgumentError("Formato não suportado: $format"))
    end
end

function generate_markdown_report(csga_score::CSGAScore)::String
    md = """
# Relatório CSGA - $(csga_score.project_name)

**Data**: $(csga_score.timestamp)
**Score Geral**: $(round(csga_score.overall_score, digits=1))/100
**Nível**: $(csga_score.maturity_level)
**Status**: $(csga_score.compliance_status)

## Resumo por Pilar

| Pilar | Peso | Score | Status |
|-------|------|-------|--------|
| Security First | 30% | $(round(csga_score.security_pillar.score, digits=1)) | $(csga_score.security_pillar.score >= 80 ? "✅" : csga_score.security_pillar.score >= 60 ? "⚠️" : "❌") |
| Clean Code | 25% | $(round(csga_score.clean_code_pillar.score, digits=1)) | $(csga_score.clean_code_pillar.score >= 80 ? "✅" : csga_score.clean_code_pillar.score >= 60 ? "⚠️" : "❌") |
| Green Code | 20% | $(round(csga_score.green_code_pillar.score, digits=1)) | $(csga_score.green_code_pillar.score >= 80 ? "✅" : csga_score.green_code_pillar.score >= 60 ? "⚠️" : "❌") |
| Advanced Automation | 25% | $(round(csga_score.automation_pillar.score, digits=1)) | $(csga_score.automation_pillar.score >= 80 ? "✅" : csga_score.automation_pillar.score >= 60 ? "⚠️" : "❌") |

## Recomendações Prioritárias

"""

    all_recommendations = vcat(
        csga_score.security_pillar.recommendations,
        csga_score.clean_code_pillar.recommendations,
        csga_score.green_code_pillar.recommendations,
        csga_score.automation_pillar.recommendations,
    )

    for (i, rec) in enumerate(unique(all_recommendations)[1:min(5, end)])
        md *= "$(i). $rec\n"
    end

    return md
end
