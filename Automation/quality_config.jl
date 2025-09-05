"""
Quality Configuration - Configurações Centralizadas de Qualidade
Sistema integrado para Quality Automation do pilar CSGA

Funcionalidades:
- Configurações centralizadas de qualidade
- Padrões e thresholds personalizáveis
- Integração com sistema CSGA
- Validação automatizada de qualidade
"""

export QualityConfig, get_quality_standards, validate_quality_metrics
export configure_quality_automation, generate_quality_dashboard

# =============================================================================
# CONFIGURAÇÃO DE QUALIDADE
# =============================================================================

"""
Estrutura de configuração de qualidade centralizada
"""
struct QualityConfig
    # Formatação e estilo
    format_options::Dict{Symbol, Any}
    max_line_length::Int
    indent_size::Int

    # Thresholds de qualidade
    min_csga_score::Float64
    min_quality_automation_score::Float64
    min_formatting_score::Float64

    # Arquivos e diretórios
    quality_files::Vector{String}
    exclude_patterns::Vector{String}
    include_directories::Vector{String}

    # Git hooks e automação
    enable_pre_commit_hooks::Bool
    enable_format_on_save::Bool
    enable_auto_linting::Bool

    # Relatórios e dashboards
    quality_report_path::String
    enable_quality_dashboard::Bool
    quality_metrics_history::Bool
end

"""
    get_default_quality_config() -> QualityConfig

Retorna configuração padrão de qualidade otimizada para Julia
"""
function get_default_quality_config()
    return QualityConfig(
        # Formatação JuliaFormatter otimizada
        Dict{Symbol, Any}(
            :indent => 4,
            :margin => 92,
            :always_for_in => true,
            :whitespace_typedefs => true,
            :whitespace_ops_in_indices => true,
            :remove_extra_newlines => true,
            :import_to_using => false,
            :pipe_to_function_call => false,
            :short_to_long_function_def => false,
            :always_use_return => false,
            :whitespace_in_kwargs => true,
            :annotate_untyped_fields_with_any => false,
            :format_docstrings => true,
            :align_struct_field => true,
            :align_assignment => true,
            :align_conditional => true,
            :normalize_line_endings => "unix",
        ),
        92,  # max_line_length
        4,   # indent_size

        # Thresholds CSGA
        85.0,  # min_csga_score (Expert level)
        75.0,  # min_quality_automation_score
        95.0,  # min_formatting_score

        # Arquivos essenciais
        [
            ".vscode/settings.json",
            "scripts/format_code.jl",
            "Makefile",
            ".git/hooks/pre-commit",
            "Project.toml",
            "Manifest.toml",
        ],

        # Padrões de exclusão
        [
            "*.jl.*.cov",
            "*.jl.cov",
            "docs/build/*",
            ".git/*",
            "tmp/*",
            ".julia/*",
            "Manifest.toml",
        ],

        # Diretórios a incluir
        ["src", "test", "scripts", "benchmarks", "examples", "docs"],

        # Automação
        true,  # enable_pre_commit_hooks
        true,  # enable_format_on_save
        true,  # enable_auto_linting

        # Relatórios
        "quality_report.md",
        true,  # enable_quality_dashboard
        true,   # quality_metrics_history
    )
end

"""
    get_quality_standards() -> Dict{String, Any}

Retorna padrões de qualidade do projeto
"""
function get_quality_standards()
    return Dict{String, Any}(
        "csga" => Dict(
            "overall_score_min" => 85.0,
            "expert_threshold" => 87.4,
            "security_pillar_min" => 70.0,
            "clean_code_pillar_min" => 65.0,
            "green_code_pillar_min" => 65.0,
            "automation_pillar_min" => 75.0,
        ),
        "quality_automation" => Dict(
            "score_min" => 75.0,
            "score_target" => 90.0,
            "formatting_score_min" => 95.0,
            "lint_issues_max" => 5,
            "style_violations_max" => 3,
        ),
        "code_standards" => Dict(
            "max_line_length" => 92,
            "max_function_length" => 50,
            "max_complexity" => 10,
            "min_test_coverage" => 85.0,
            "max_trailing_whitespace" => 0,
        ),
        "file_standards" => Dict(
            "require_docstrings" => true,
            "require_type_annotations" => false,
            "require_final_newline" => true,
            "prohibit_tabs" => true,
            "encoding" => "utf-8",
        ),
        "git_standards" => Dict(
            "require_pre_commit_hooks" => true,
            "max_commit_message_length" => 72,
            "require_issue_reference" => false,
            "prohibit_force_push" => true,
        ),
    )
end

"""
    validate_quality_metrics(project_path::String = ".") -> Dict{String, Any}

Valida métricas de qualidade contra padrões configurados
"""
function validate_quality_metrics(project_path::String = ".")
    config = get_default_quality_config()
    standards = get_quality_standards()

    println("🔍 Validação de Métricas de Qualidade")
    println("=" * 38)

    results = Dict{String, Any}(
        "passed" => true,
        "issues" => String[],
        "warnings" => String[],
        "metrics" => Dict{String, Any}(),
        "recommendations" => String[],
    )

    try
        # 1. Validar Score CSGA
        score = Automation.evaluate_project(project_path)
        overall_score = score.overall_score
        qa_score = get(score.automation_pillar.metrics, "quality_automation", 0.0)

        results["metrics"]["overall_score"] = overall_score
        results["metrics"]["quality_automation_score"] = qa_score

        if overall_score < standards["csga"]["overall_score_min"]
            results["passed"] = false
            push!(
                results["issues"],
                "Score CSGA abaixo do mínimo: $(round(overall_score, digits=1))/$(standards["csga"]["overall_score_min"])",
            )
        end

        if qa_score < standards["quality_automation"]["score_min"]
            results["passed"] = false
            push!(
                results["issues"],
                "Quality Automation abaixo do mínimo: $(round(qa_score, digits=1))/$(standards["quality_automation"]["score_min"])",
            )
        end

        # 2. Validar arquivos essenciais
        missing_files = String[]
        for file in config.quality_files
            file_path = joinpath(project_path, file)
            if !isfile(file_path) && !isdir(file_path)
                push!(missing_files, file)
            end
        end

        if !isempty(missing_files)
            results["passed"] = false
            push!(
                results["issues"],
                "Arquivos de qualidade ausentes: $(join(missing_files, ", "))",
            )
        end

        results["metrics"]["missing_files"] = length(missing_files)

        # 3. Validar formatação de código
        julia_files = find_julia_files(project_path)
        unformatted_count = 0

        for file in julia_files
            try
                is_formatted =
                    JuliaFormatter.format(file; config.format_options..., overwrite = false)
                if !is_formatted
                    unformatted_count += 1
                end
            catch e
                push!(results["warnings"], "Erro verificando formatação de $file: $e")
            end
        end

        formatting_score =
            length(julia_files) > 0 ?
            ((length(julia_files) - unformatted_count) / length(julia_files)) * 100 : 100.0

        results["metrics"]["formatting_score"] = formatting_score
        results["metrics"]["unformatted_files"] = unformatted_count

        if formatting_score < standards["quality_automation"]["formatting_score_min"]
            results["passed"] = false
            push!(
                results["issues"],
                "Score de formatação abaixo do mínimo: $(round(formatting_score, digits=1))%/$(standards["quality_automation"]["formatting_score_min"])%",
            )
        end

        # 4. Validar estrutura de diretórios
        missing_dirs = String[]
        for dir in config.include_directories
            dir_path = joinpath(project_path, dir)
            if !isdir(dir_path)
                push!(missing_dirs, dir)
            end
        end

        if !isempty(missing_dirs)
            push!(
                results["warnings"],
                "Diretórios recomendados ausentes: $(join(missing_dirs, ", "))",
            )
            push!(
                results["recommendations"],
                "Considere criar diretórios: $(join(missing_dirs, ", "))",
            )
        end

        # 5. Verificar git hooks
        pre_commit_hook = joinpath(project_path, ".git/hooks/pre-commit")
        if !isfile(pre_commit_hook)
            push!(results["warnings"], "Git hook pre-commit não encontrado")
            push!(results["recommendations"], "Configure git hooks para quality automation")
        else
            results["metrics"]["pre_commit_hook"] = true
        end

    catch e
        results["passed"] = false
        push!(results["issues"], "Erro durante validação: $e")
    end

    return results
end

"""
    configure_quality_automation(project_path::String = ".") -> Bool

Configura automaticamente quality automation no projeto
"""
function configure_quality_automation(project_path::String = ".")
    println("⚙️ Configurando Quality Automation")
    println("=" * 32)

    config = get_default_quality_config()
    success = true

    try
        # 1. Verificar e criar diretórios necessários
        for dir in config.include_directories
            dir_path = joinpath(project_path, dir)
            if !isdir(dir_path)
                try
                    mkdir(dir_path)
                    println("✅ Criado diretório: $dir")
                catch e
                    println("❌ Erro criando diretório $dir: $e")
                    success = false
                end
            end
        end

        # 2. Verificar VSCode settings
        vscode_settings = joinpath(project_path, ".vscode/settings.json")
        if isfile(vscode_settings)
            println("✅ VSCode settings.json encontrado")
        else
            println("⚠️  VSCode settings.json não encontrado - configure manualmente")
        end

        # 3. Verificar Makefile targets
        makefile_path = joinpath(project_path, "Makefile")
        if isfile(makefile_path)
            makefile_content = Automation.safe_file_read(makefile_path)
            required_targets = ["format", "format-check", "quality-report", "style-check"]

            for target in required_targets
                if occursin(Regex("^$(target):", "m"), makefile_content)
                    println("✅ Makefile target: $target")
                else
                    println("❌ Makefile target ausente: $target")
                    success = false
                end
            end
        else
            println("❌ Makefile não encontrado")
            success = false
        end

        # 4. Verificar git hooks
        pre_commit_hook = joinpath(project_path, ".git/hooks/pre-commit")
        if isfile(pre_commit_hook)
            println("✅ Git hook pre-commit configurado")
        else
            println("❌ Git hook pre-commit não encontrado")
            success = false
        end

        # 5. Testar formatação
        println("\n🔧 Testando sistema de formatação...")
        format_result = run(`julia --project=$project_path scripts/format_code.jl check`)
        if format_result.exitcode == 0
            println("✅ Sistema de formatação funcional")
        else
            println("❌ Sistema de formatação com problemas")
            success = false
        end

    catch e
        println("❌ Erro durante configuração: $e")
        success = false
    end

    if success
        println("\n🎉 Quality Automation configurada com sucesso!")
    else
        println("\n⚠️  Quality Automation configurada com problemas")
        println("💡 Execute 'make quality-report' para diagnóstico detalhado")
    end

    return success
end

"""
    generate_quality_dashboard() -> String

Gera dashboard HTML de qualidade do projeto
"""
function generate_quality_dashboard(project_path::String = ".")
    println("📊 Gerando Quality Dashboard")
    println("=" * 27)

    validation_results = validate_quality_metrics(project_path)
    standards = get_quality_standards()

    # HTML Dashboard
    html_content = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quality Dashboard - CSGA</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 20px; margin-bottom: 30px; }
        .metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { background: #ecf0f1; padding: 20px; border-radius: 8px; text-align: center; border-left: 4px solid #3498db; }
        .metric-value { font-size: 2em; font-weight: bold; color: #2c3e50; }
        .metric-label { color: #7f8c8d; margin-top: 5px; }
        .status-good { border-left-color: #27ae60 !important; }
        .status-warning { border-left-color: #f39c12 !important; }
        .status-error { border-left-color: #e74c3c !important; }
        .issues { background: #fdf2f2; border: 1px solid #e74c3c; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
        .warnings { background: #fef9e7; border: 1px solid #f39c12; border-radius: 8px; padding: 20px; margin-bottom: 20px; }
        .recommendations { background: #edf7ff; border: 1px solid #3498db; border-radius: 8px; padding: 20px; }
        .list { list-style: none; padding: 0; }
        .list li { padding: 5px 0; border-bottom: 1px solid #ddd; }
        .timestamp { text-align: center; color: #7f8c8d; margin-top: 30px; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 Quality Dashboard</h1>
            <p>Sistema CSGA - Quality Automation</p>
        </div>

        <div class="metrics">
            <div class="metric-card $(validation_results["metrics"]["overall_score"] >= standards["csga"]["overall_score_min"] ? "status-good" : "status-error")">
                <div class="metric-value">$(round(validation_results["metrics"]["overall_score"], digits=1))</div>
                <div class="metric-label">Score CSGA Overall</div>
            </div>
            <div class="metric-card $(validation_results["metrics"]["quality_automation_score"] >= standards["quality_automation"]["score_min"] ? "status-good" : "status-error")">
                <div class="metric-value">$(round(validation_results["metrics"]["quality_automation_score"], digits=1))</div>
                <div class="metric-label">Quality Automation</div>
            </div>
            <div class="metric-card $(validation_results["metrics"]["formatting_score"] >= standards["quality_automation"]["formatting_score_min"] ? "status-good" : "status-warning")">
                <div class="metric-value">$(round(validation_results["metrics"]["formatting_score"], digits=1))%</div>
                <div class="metric-label">Formatação</div>
            </div>
            <div class="metric-card $(validation_results["metrics"]["missing_files"] == 0 ? "status-good" : "status-warning")">
                <div class="metric-value">$(validation_results["metrics"]["missing_files"])</div>
                <div class="metric-label">Arquivos Ausentes</div>
            </div>
        </div>
"""

    # Adicionar seções de issues, warnings e recommendations
    if !isempty(validation_results["issues"])
        html_content *= """
        <div class="issues">
            <h3>❌ Questões Críticas</h3>
            <ul class="list">
$(join(["<li>$(issue)</li>" for issue in validation_results["issues"]], "\n"))
            </ul>
        </div>
"""
    end

    if !isempty(validation_results["warnings"])
        html_content *= """
        <div class="warnings">
            <h3>⚠️ Avisos</h3>
            <ul class="list">
$(join(["<li>$(warning)</li>" for warning in validation_results["warnings"]], "\n"))
            </ul>
        </div>
"""
    end

    if !isempty(validation_results["recommendations"])
        html_content *= """
        <div class="recommendations">
            <h3>💡 Recomendações</h3>
            <ul class="list">
$(join(["<li>$(rec)</li>" for rec in validation_results["recommendations"]], "\n"))
            </ul>
        </div>
"""
    end

    html_content *= """
        <div class="timestamp">
            Gerado em: $(now()) | Sistema CSGA Quality Automation
        </div>
    </div>
</body>
</html>
"""

    # Salvar dashboard
    dashboard_file = joinpath(project_path, "quality_dashboard.html")
    try
        write(dashboard_file, html_content)
        println("📄 Dashboard salvo em: $dashboard_file")
        return dashboard_file
    catch e
        println("❌ Erro salvando dashboard: $e")
        return ""
    end
end

"""
Função auxiliar para encontrar arquivos Julia
"""
function find_julia_files(path::String)
    julia_files = String[]

    # Diretórios a incluir
    include_dirs = ["src", "test", "scripts", "benchmarks", "examples"]

    # Arquivos na raiz
    for file in readdir(path)
        if endswith(file, ".jl") && isfile(joinpath(path, file))
            push!(julia_files, joinpath(path, file))
        end
    end

    # Arquivos em subdiretórios relevantes
    for dir in include_dirs
        dir_path = joinpath(path, dir)
        if isdir(dir_path)
            for (root, dirs, files) in walkdir(dir_path)
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end
        end
    end

    return julia_files
end
