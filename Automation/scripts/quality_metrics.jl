"""
Quality Metrics - Sistema de Métricas de Qualidade
Coleta, análise e relatórios de métricas de qualidade do projeto

Funcionalidades:
- Coleta de métricas de código
- Análise de tendências de qualidade
- Relatórios de debt técnico
- Integração com CSGA scoring
- Monitoramento contínuo de qualidade
"""

using Statistics
using Dates
using JSON3

export QualityMetrics, collect_quality_metrics, analyze_quality_trends
export generate_technical_debt_report, track_quality_evolution
export quality_dashboard_data, export_metrics_data

# =============================================================================
# ESTRUTURAS DE DADOS
# =============================================================================

"""
Snapshot de métricas de qualidade em um momento específico
"""
struct QualitySnapshot
    timestamp::DateTime
    project_path::String
    csga_score::Float64
    quality_automation_score::Float64
    code_metrics::Dict{String, Any}
    quality_issues::Dict{String, Int}
    technical_debt::Dict{String, Float64}
end

"""
Histórico de evolução da qualidade
"""
struct QualityEvolution
    project_path::String
    snapshots::Vector{QualitySnapshot}
    trends::Dict{String, Vector{Float64}}
    improvement_rate::Float64
    debt_trend::String  # "improving", "stable", "degrading"
end

# =============================================================================
# COLETA DE MÉTRICAS
# =============================================================================

"""
    collect_quality_metrics(project_path::String = ".") -> QualitySnapshot

Coleta snapshot completo das métricas de qualidade atuais
"""
function collect_quality_metrics(project_path::String = ".")
    println("📊 Coletando Métricas de Qualidade")
    println("=" ^ 33)

    timestamp = now()

    # 1. Métricas CSGA
    csga_score, qa_score = collect_csga_metrics(project_path)

    # 2. Métricas de código
    code_metrics = collect_code_metrics(project_path)

    # 3. Questões de qualidade
    quality_issues = collect_quality_issues(project_path)

    # 4. Debt técnico
    technical_debt = calculate_technical_debt(code_metrics, quality_issues)

    return QualitySnapshot(
        timestamp,
        project_path,
        csga_score,
        qa_score,
        code_metrics,
        quality_issues,
        technical_debt
    )
end

"""
Coleta métricas do sistema CSGA
"""
function collect_csga_metrics(project_path::String)
    try
        # Usar include para carregar o módulo se necessário
        if !isdefined(Main, :Automation)
            include(joinpath(project_path, "src", "Automation.jl"))
            using .Automation
        end

        score = Automation.evaluate_project(project_path)
        csga_score = score.overall_score
        qa_score = get(score.automation_pillar.metrics, "quality_automation", 0.0)

        println("   ✅ CSGA Score: $(round(csga_score, digits=1))/100")
        println("   ✅ Quality Automation: $(round(qa_score, digits=1))/100")

        return csga_score, qa_score

    catch e
        println("   ⚠️  Erro coletando métricas CSGA: $e")
        return 0.0, 0.0
    end
end

"""
Coleta métricas detalhadas de código
"""
function collect_code_metrics(project_path::String)
    metrics = Dict{String, Any}()

    # Encontrar arquivos Julia
    julia_files = find_julia_files(project_path)

    if isempty(julia_files)
        return metrics
    end

    println("   📁 Analisando $(length(julia_files)) arquivos...")

    # Métricas agregadas
    total_lines = 0
    total_loc = 0
    total_functions = 0
    total_structs = 0
    total_modules = 0
    complexity_scores = Float64[]
    file_sizes = Int[]

    for file in julia_files
        try
            content = read(file, String)
            lines = split(content, '\n')

            # Métricas básicas
            total_lines += length(lines)
            loc = count_effective_lines(lines)
            total_loc += loc

            # Contadores de estruturas
            total_functions += length(collect(eachmatch(r"\bfunction\s+\w+", content)))
            total_structs += length(collect(eachmatch(r"\bstruct\s+\w+", content)))
            total_modules += length(collect(eachmatch(r"\bmodule\s+\w+", content)))

            # Complexidade
            complexity = calculate_file_complexity(content)
            push!(complexity_scores, complexity)

            # Tamanho do arquivo
            push!(file_sizes, loc)

        catch e
            println("     ⚠️  Erro analisando $(basename(file)): $e")
        end
    end

    # Calcular métricas finais
    metrics["total_files"] = length(julia_files)
    metrics["total_lines"] = total_lines
    metrics["total_loc"] = total_loc
    metrics["total_functions"] = total_functions
    metrics["total_structs"] = total_structs
    metrics["total_modules"] = total_modules

    # Métricas calculadas
    metrics["avg_file_size"] = length(file_sizes) > 0 ? mean(file_sizes) : 0
    metrics["max_file_size"] = length(file_sizes) > 0 ? maximum(file_sizes) : 0
    metrics["avg_complexity"] = length(complexity_scores) > 0 ? mean(complexity_scores) : 0
    metrics["max_complexity"] = length(complexity_scores) > 0 ? maximum(complexity_scores) : 0

    # Ratios
    metrics["loc_ratio"] = total_lines > 0 ? total_loc / total_lines : 0
    metrics["functions_per_file"] = length(julia_files) > 0 ? total_functions / length(julia_files) : 0
    metrics["complexity_density"] = total_loc > 0 ? sum(complexity_scores) / total_loc * 1000 : 0

    println("   📊 LOC: $total_loc, Funções: $total_functions, Complexidade Média: $(round(metrics["avg_complexity"], digits=1))")

    return metrics
end

"""
Coleta questões de qualidade
"""
function collect_quality_issues(project_path::String)
    issues = Dict{String, Int}(
        "long_lines" => 0,
        "trailing_whitespace" => 0,
        "missing_docstrings" => 0,
        "high_complexity_functions" => 0,
        "large_functions" => 0,
        "deep_nesting" => 0,
        "naming_violations" => 0,
        "code_smells" => 0
    )

    julia_files = find_julia_files(project_path)

    for file in julia_files
        try
            content = read(file, String)
            lines = split(content, '\n')

            # Analisar cada tipo de questão
            issues["long_lines"] += count_long_lines(lines)
            issues["trailing_whitespace"] += count_trailing_whitespace(lines)
            issues["missing_docstrings"] += count_missing_docstrings(content)
            issues["high_complexity_functions"] += count_high_complexity_functions(content)
            issues["large_functions"] += count_large_functions(content)
            issues["deep_nesting"] += count_deep_nesting(lines)
            issues["naming_violations"] += count_naming_violations(content)
            issues["code_smells"] += count_code_smells(content, lines)

        catch e
            println("     ⚠️  Erro analisando questões em $(basename(file)): $e")
        end
    end

    total_issues = sum(values(issues))
    println("   ⚠️  Total de questões encontradas: $total_issues")

    return issues
end

"""
Calcula debt técnico baseado nas métricas
"""
function calculate_technical_debt(code_metrics::Dict{String, Any}, quality_issues::Dict{String, Int})
    debt = Dict{String, Float64}()

    # Debt de complexidade (horas para simplificar)
    avg_complexity = get(code_metrics, "avg_complexity", 0.0)
    debt["complexity_debt"] = max(0, avg_complexity - 5.0) * 2.0  # 2h por ponto de complexidade excessiva

    # Debt de tamanho de arquivo (horas para refatorar)
    avg_file_size = get(code_metrics, "avg_file_size", 0.0)
    debt["size_debt"] = max(0, avg_file_size - 200) / 50 * 4.0  # 4h por 50 linhas excessivas

    # Debt de questões de qualidade (horas para resolver)
    total_issues = sum(values(quality_issues))
    debt["quality_debt"] = total_issues * 0.25  # 15min por questão

    # Debt de documentação (horas para documentar)
    missing_docs = get(quality_issues, "missing_docstrings", 0)
    debt["documentation_debt"] = missing_docs * 0.5  # 30min por função não documentada

    # Debt total em horas
    debt["total_debt_hours"] = sum(values(debt))

    # Debt em custo (assumindo $50/hora)
    debt["total_debt_cost"] = debt["total_debt_hours"] * 50

    return debt
end

# =============================================================================
# ANÁLISE DE TENDÊNCIAS
# =============================================================================

"""
    analyze_quality_trends(snapshots::Vector{QualitySnapshot}) -> Dict{String, Any}

Analisa tendências de qualidade ao longo do tempo
"""
function analyze_quality_trends(snapshots::Vector{QualitySnapshot})
    if length(snapshots) < 2
        return Dict{String, Any}("error" => "Insuficientes snapshots para análise de tendência")
    end

    trends = Dict{String, Any}()

    # Tendência do score CSGA
    csga_scores = [s.csga_score for s in snapshots]
    trends["csga_trend"] = calculate_trend(csga_scores)
    trends["csga_improvement_rate"] = calculate_improvement_rate(csga_scores)

    # Tendência do Quality Automation
    qa_scores = [s.quality_automation_score for s in snapshots]
    trends["qa_trend"] = calculate_trend(qa_scores)
    trends["qa_improvement_rate"] = calculate_improvement_rate(qa_scores)

    # Tendência do debt técnico
    debt_values = [s.technical_debt["total_debt_hours"] for s in snapshots]
    trends["debt_trend"] = calculate_trend(debt_values, reverse=true)  # Diminuição é boa
    trends["debt_change_rate"] = calculate_improvement_rate(debt_values, reverse=true)

    # Tendência de questões de qualidade
    total_issues = [sum(values(s.quality_issues)) for s in snapshots]
    trends["issues_trend"] = calculate_trend(total_issues, reverse=true)
    trends["issues_change_rate"] = calculate_improvement_rate(total_issues, reverse=true)

    # Análise geral
    trends["overall_trend"] = determine_overall_trend(trends)
    trends["time_span_days"] = (snapshots[end].timestamp - snapshots[1].timestamp).value / (1000 * 60 * 60 * 24)

    return trends
end

"""
Calcula tendência de uma série de valores
"""
function calculate_trend(values::Vector{Float64}; reverse::Bool = false)
    if length(values) < 2
        return "insufficient_data"
    end

    # Regressão linear simples
    n = length(values)
    x = collect(1:n)

    slope = (n * sum(x .* values) - sum(x) * sum(values)) / (n * sum(x .^ 2) - sum(x)^2)

    # Ajustar interpretação se reverse=true (ex: debt técnico)
    if reverse
        slope = -slope
    end

    if slope > 0.1
        return "improving"
    elseif slope < -0.1
        return "degrading"
    else
        return "stable"
    end
end

"""
Calcula taxa de melhoria
"""
function calculate_improvement_rate(values::Vector{Float64}; reverse::Bool = false)
    if length(values) < 2
        return 0.0
    end

    initial = values[1]
    final = values[end]

    if initial == 0
        return 0.0
    end

    rate = (final - initial) / initial * 100

    return reverse ? -rate : rate
end

"""
Determina tendência geral baseada em múltiplas métricas
"""
function determine_overall_trend(trends::Dict{String, Any})
    positive_trends = 0
    negative_trends = 0

    trend_keys = ["csga_trend", "qa_trend", "debt_trend", "issues_trend"]

    for key in trend_keys
        if haskey(trends, key)
            trend = trends[key]
            if trend == "improving"
                positive_trends += 1
            elseif trend == "degrading"
                negative_trends += 1
            end
        end
    end

    if positive_trends > negative_trends
        return "improving"
    elseif negative_trends > positive_trends
        return "degrading"
    else
        return "stable"
    end
end

# =============================================================================
# RELATÓRIOS DE DEBT TÉCNICO
# =============================================================================

"""
    generate_technical_debt_report(snapshot::QualitySnapshot) -> String

Gera relatório detalhado de debt técnico
"""
function generate_technical_debt_report(snapshot::QualitySnapshot)
    debt = snapshot.technical_debt

    report = """
# Relatório de Debt Técnico
## Projeto: $(basename(snapshot.project_path))
## Data: $(Dates.format(snapshot.timestamp, "dd/mm/yyyy HH:MM"))

### 💰 Resumo Executivo
- **Debt Total**: $(round(debt["total_debt_hours"], digits=1)) horas
- **Custo Estimado**: \$$(round(debt["total_debt_cost"], digits=0))
- **Score CSGA**: $(round(snapshot.csga_score, digits=1))/100
- **Quality Automation**: $(round(snapshot.quality_automation_score, digits=1))/100

### 📊 Breakdown do Debt Técnico

#### 🔧 Complexidade ($(round(debt["complexity_debt"], digits=1))h)
- Complexidade média excessiva
- **Ação**: Refatorar funções complexas
- **Prioridade**: Alta

#### 📏 Tamanho de Arquivos ($(round(debt["size_debt"], digits=1))h)
- Arquivos muito grandes
- **Ação**: Quebrar em módulos menores
- **Prioridade**: Média

#### ⚠️ Questões de Qualidade ($(round(debt["quality_debt"], digits=1))h)
- Violações de estilo e boas práticas
- **Ação**: Executar linting e formatação
- **Prioridade**: Baixa

#### 📖 Documentação ($(round(debt["documentation_debt"], digits=1))h)
- Funções sem documentação
- **Ação**: Adicionar docstrings
- **Prioridade**: Média

### 🎯 Plano de Ação Recomendado

1. **Imediato (0-1 semana)**
   - Executar formatação automática: `make format`
   - Resolver trailing whitespace e linhas longas
   - Estimativa: $(round(debt["quality_debt"] * 0.5, digits=1))h

2. **Curto Prazo (1-4 semanas)**
   - Documentar funções críticas
   - Refatorar 2-3 funções mais complexas
   - Estimativa: $(round(debt["complexity_debt"] * 0.3 + debt["documentation_debt"] * 0.5, digits=1))h

3. **Médio Prazo (1-3 meses)**
   - Reestruturar arquivos grandes
   - Completar documentação
   - Estimativa: $(round(debt["total_debt_hours"] * 0.6, digits=1))h

### 📈 ROI da Redução de Debt

- **Produtividade**: +15-25% após redução
- **Manutenibilidade**: +40% facilidade de mudanças
- **Onboarding**: -50% tempo para novos desenvolvedores
- **Bugs**: -30% incidência de defeitos

### 🔄 Monitoramento

Recomenda-se executar este relatório:
- **Semanalmente** durante refatoração ativa
- **Mensalmente** para monitoramento contínuo
- **Antes/depois** de releases importantes

---
*Relatório gerado automaticamente pelo sistema CSGA Quality Automation*
"""

    return report
end

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

"""
Conta linhas efetivas de código
"""
function count_effective_lines(lines::Vector{String})
    count = 0
    in_multiline_comment = false

    for line in lines
        trimmed = strip(line)

        # Pular linhas vazias
        isempty(trimmed) && continue

        # Detectar comentários multilinhas
        if occursin(r"#=", trimmed)
            in_multiline_comment = true
        end

        if in_multiline_comment
            if occursin(r"=#", trimmed)
                in_multiline_comment = false
            end
            continue
        end

        # Pular comentários de linha única
        startswith(trimmed, "#") && continue

        count += 1
    end

    return count
end

"""
Calcula complexidade de arquivo
"""
function calculate_file_complexity(content::String)
    complexity = 1  # Base

    # Padrões que aumentam complexidade
    patterns = [
        r"\\bif\\b" => 1,
        r"\\belseif\\b" => 1,
        r"\\bfor\\b" => 1,
        r"\\bwhile\\b" => 1,
        r"\\btry\\b" => 1,
        r"\\bcatch\\b" => 1,
        r"&&" => 1,
        r"\\|\\|" => 1
    ]

    for (pattern, weight) in patterns
        matches = length(collect(eachmatch(pattern, content)))
        complexity += matches * weight
    end

    # Normalizar pelo número de funções
    functions = length(collect(eachmatch(r"\bfunction\s+\w+", content)))

    return functions > 0 ? complexity / functions : complexity
end

# Funções de contagem de questões específicas
function count_long_lines(lines::Vector{String})
    return count(line -> length(line) > 100, lines)
end

function count_trailing_whitespace(lines::Vector{String})
    return count(line -> endswith(line, " ") || endswith(line, "\\t"), lines)
end

function count_missing_docstrings(content::String)
    functions = collect(eachmatch(r"function\\s+(\\w+)", content))
    documented = length(collect(eachmatch(r'""".*?function\\s+\\w+', content)))
    return max(0, length(functions) - documented)
end

function count_high_complexity_functions(content::String)
    # Aproximação simples
    return length(collect(eachmatch(r"function\\s+\\w+.*?(?=function|$)"s, content))) > 10 ? 1 : 0
end

function count_large_functions(content::String)
    # Heurística simples
    return length(collect(eachmatch(r"function\s+\w+", content))) > 5 ? 1 : 0
end

function count_deep_nesting(lines::Vector{String})
    max_nesting = 0
    current_nesting = 0

    for line in lines
        trimmed = strip(line)
        if occursin(r"\b(if|for|while|try)\b", trimmed)
            current_nesting += 1
            max_nesting = max(max_nesting, current_nesting)
        elseif occursin(r"\\bend\\b", trimmed)
            current_nesting = max(0, current_nesting - 1)
        end
    end

    return max_nesting > 4 ? 1 : 0
end

function count_naming_violations(content::String)
    violations = 0

    # Funções não snake_case
    func_names = [m.captures[1] for m in eachmatch(r"function\\s+(\\w+)", content)]
    violations += count(name -> !occursin(r"^[a-z][a-z0-9_]*$", name), func_names)

    return violations
end

function count_code_smells(content::String, lines::Vector{String})
    smells = 0

    # Heurísticas simples
    smells += length(collect(eachmatch(r"function\\s+\\w+", content))) > 20 ? 1 : 0  # Muitas funções
    smells += count(line -> length(line) > 120, lines) > 5 ? 1 : 0  # Muitas linhas longas
    smells += occursin(r"global\s+\w+", content) ? 1 : 0  # Variáveis globais

    return smells
end

"""
Função auxiliar para encontrar arquivos Julia
"""
function find_julia_files(path::String)
    julia_files = String[]

    include_dirs = ["src", "test", "scripts", "benchmarks", "examples"]

    # Arquivos na raiz
    for file in readdir(path)
        if endswith(file, ".jl") && isfile(joinpath(path, file))
            push!(julia_files, joinpath(path, file))
        end
    end

    # Arquivos em subdiretórios
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

"""
    save_quality_snapshot(snapshot::QualitySnapshot, filepath::String)

Salva snapshot em arquivo JSON
"""
function save_quality_snapshot(snapshot::QualitySnapshot, filepath::String)
    data = Dict(
        "timestamp" => string(snapshot.timestamp),
        "project_path" => snapshot.project_path,
        "csga_score" => snapshot.csga_score,
        "quality_automation_score" => snapshot.quality_automation_score,
        "code_metrics" => snapshot.code_metrics,
        "quality_issues" => snapshot.quality_issues,
        "technical_debt" => snapshot.technical_debt
    )

    open(filepath, "w") do f
        JSON3.pretty(f, data)
    end
end

"""
    load_quality_snapshots(dirpath::String) -> Vector{QualitySnapshot}

Carrega snapshots de um diretório
"""
function load_quality_snapshots(dirpath::String)
    snapshots = QualitySnapshot[]

    if !isdir(dirpath)
        return snapshots
    end

    for file in readdir(dirpath)
        if endswith(file, ".json")
            try
                filepath = joinpath(dirpath, file)
                data = JSON3.read(filepath)

                snapshot = QualitySnapshot(
                    DateTime(data["timestamp"]),
                    data["project_path"],
                    data["csga_score"],
                    data["quality_automation_score"],
                    data["code_metrics"],
                    data["quality_issues"],
                    data["technical_debt"]
                )

                push!(snapshots, snapshot)
            catch e
                println("Erro carregando $file: $e")
            end
        end
    end

    # Ordenar por timestamp
    sort!(snapshots, by = s -> s.timestamp)

    return snapshots
end
