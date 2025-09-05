"""
Quality Analyzer - Análise Estática Avançada de Código
Sistema de análise de qualidade para Quality Automation

Funcionalidades:
- Análise de complexidade de código
- Detecção de code smells
- Métricas de manutenibilidade
- Alertas de qualidade automáticos
- Integração com sistema CSGA
"""

using Statistics
using Dates

export QualityAnalyzer, analyze_code_quality, detect_code_smells
export calculate_complexity_metrics, generate_quality_alerts
export analyze_file, analyze_project, quality_trend_analysis

# =============================================================================
# ESTRUTURAS DE DADOS
# =============================================================================

"""
Resultado de análise de qualidade de um arquivo
"""
struct FileQualityResult
    file_path::String
    lines_of_code::Int
    complexity_score::Float64
    maintainability_index::Float64
    code_smells::Vector{String}
    quality_issues::Vector{String}
    recommendations::Vector{String}
    metrics::Dict{String, Any}
end

"""
Resultado de análise de qualidade do projeto completo
"""
struct ProjectQualityResult
    project_path::String
    timestamp::DateTime
    overall_quality_score::Float64
    file_results::Vector{FileQualityResult}
    project_metrics::Dict{String, Any}
    critical_issues::Vector{String}
    recommendations::Vector{String}
    quality_trends::Dict{String, Vector{Float64}}
end

# =============================================================================
# ANALISADOR DE QUALIDADE
# =============================================================================

"""
    analyze_file(file_path::String) -> FileQualityResult

Analisa qualidade de código de um arquivo específico
"""
function analyze_file(file_path::String)
    if !isfile(file_path) || !endswith(file_path, ".jl")
        throw(ArgumentError("Arquivo inválido: $file_path"))
    end

    content = Automation.safe_file_read(file_path)
    lines = split(content, '\n')

    # Métricas básicas
    lines_of_code = count_lines_of_code(lines)
    complexity_score = calculate_cyclomatic_complexity(content)
    maintainability_index = calculate_maintainability_index(content, lines_of_code, complexity_score)

    # Detecção de problemas
    code_smells = detect_code_smells(content, lines)
    quality_issues = detect_quality_issues(content, lines)
    recommendations = generate_recommendations(code_smells, quality_issues, complexity_score)

    # Métricas detalhadas
    metrics = calculate_detailed_metrics(content, lines)

    return FileQualityResult(
        file_path,
        lines_of_code,
        complexity_score,
        maintainability_index,
        code_smells,
        quality_issues,
        recommendations,
        metrics
    )
end

"""
    count_lines_of_code(lines::Vector{String}) -> Int

Conta linhas de código efetivas (excluindo comentários e linhas vazias)
"""
function count_lines_of_code(lines::Vector{String})
    loc = 0
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

        # Linha de código válida
        loc += 1
    end

    return loc
end

"""
    calculate_cyclomatic_complexity(content::String) -> Float64

Calcula complexidade ciclomática aproximada do código
"""
function calculate_cyclomatic_complexity(content::String)
    complexity = 1  # Base complexity

    # Padrões que aumentam complexidade
    complexity_patterns = [
        r"\bif\b" => 1,           # if statements
        r"\belseif\b" => 1,       # elseif branches
        r"\belse\b" => 1,         # else branches
        r"\bfor\b" => 1,          # for loops
        r"\bwhile\b" => 1,        # while loops
        r"\btry\b" => 1,          # try blocks
        r"\bcatch\b" => 1,        # catch blocks
        r"\bfinally\b" => 1,      # finally blocks
        r"&&" => 1,               # logical and
        r"\|\|" => 1,             # logical or
        r"\?" => 1,               # ternary operator
        r"\bfunction\b" => 1,     # function definitions
        r"\bmacro\b" => 1,        # macro definitions
    ]

    for (pattern, weight) in complexity_patterns
        matches = length(collect(eachmatch(pattern, content)))
        complexity += matches * weight
    end

    # Normalizar pela quantidade de funções/métodos
    function_count = max(1, length(collect(eachmatch(r"\bfunction\b", content))))

    return complexity / function_count
end

"""
    calculate_maintainability_index(content::String, loc::Int, complexity::Float64) -> Float64

Calcula índice de manutenibilidade do código
"""
function calculate_maintainability_index(content::String, loc::Int, complexity::Float64)
    # Halstead Volume (aproximado)
    operators = length(collect(eachmatch(r"[+\-*/=<>!&|]", content)))
    operands = length(collect(eachmatch(r"\b[a-zA-Z_]\w*\b", content)))
    halstead_volume = (operators + operands) * log2(max(1, operators + operands))

    # Fórmula de manutenibilidade adaptada para Julia
    # MI = 171 - 5.2 * ln(V) - 0.23 * G - 16.2 * ln(LOC)
    # Onde: V = Halstead Volume, G = Complexidade Ciclomática, LOC = Lines of Code

    mi = 171 - 5.2 * log(max(1, halstead_volume)) - 0.23 * complexity - 16.2 * log(max(1, loc))

    # Normalizar para 0-100
    return max(0.0, min(100.0, mi))
end

"""
    detect_code_smells(content::String, lines::Vector{String}) -> Vector{String}

Detecta code smells no código
"""
function detect_code_smells(content::String, lines::Vector{String})
    smells = String[]

    # 1. Função muito longa
    function_lengths = analyze_function_lengths(content)
    for (func_name, length) in function_lengths
        if length > 50
            push!(smells, "Função muito longa: $func_name ($length linhas)")
        end
    end

    # 2. Muitos parâmetros em função
    param_counts = analyze_function_parameters(content)
    for (func_name, param_count) in param_counts
        if param_count > 5
            push!(smells, "Muitos parâmetros: $func_name ($param_count parâmetros)")
        end
    end

    # 3. Aninhamento profundo
    max_nesting = calculate_max_nesting(lines)
    if max_nesting > 4
        push!(smells, "Aninhamento muito profundo: $max_nesting níveis")
    end

    # 4. Código duplicado
    duplicates = detect_code_duplication(lines)
    if !isempty(duplicates)
        push!(smells, "Possível código duplicado: $(length(duplicates)) blocos similares")
    end

    # 5. Nomes inadequados
    naming_issues = analyze_naming_conventions(content)
    for issue in naming_issues
        push!(smells, "Convenção de nomes: $issue")
    end

    # 6. Comentários excessivos ou insuficientes
    comment_ratio = calculate_comment_ratio(lines)
    if comment_ratio > 0.3
        push!(smells, "Comentários excessivos: $(round(comment_ratio*100, digits=1))%")
    elseif comment_ratio < 0.05
        push!(smells, "Comentários insuficientes: $(round(comment_ratio*100, digits=1))%")
    end

    return smells
end

"""
    detect_quality_issues(content::String, lines::Vector{String}) -> Vector{String}

Detecta questões específicas de qualidade
"""
function detect_quality_issues(content::String, lines::Vector{String})
    issues = String[]

    # 1. Linhas muito longas
    for (i, line) in enumerate(lines)
        if length(line) > 100
            push!(issues, "Linha $i muito longa: $(length(line)) caracteres")
        end
    end

    # 2. Trailing whitespace
    for (i, line) in enumerate(lines)
        if endswith(line, " ") || endswith(line, "\t")
            push!(issues, "Linha $i tem trailing whitespace")
        end
    end

    # 3. Uso de tabs ao invés de espaços
    for (i, line) in enumerate(lines)
        if occursin("\t", line)
            push!(issues, "Linha $i usa tabs ao invés de espaços")
        end
    end

    # 4. Imports não otimizados
    if occursin(r"using\s+\w+\.\w+", content)
        push!(issues, "Imports específicos detectados - considere usar 'using Package: function'")
    end

    # 5. Variáveis globais
    global_vars = collect(eachmatch(r"^\s*global\s+\w+", content))
    if !isempty(global_vars)
        push!(issues, "$(length(global_vars)) variáveis globais detectadas")
    end

    # 6. Funções sem docstring
    functions_without_docs = detect_undocumented_functions(content)
    if !isempty(functions_without_docs)
        push!(issues, "$(length(functions_without_docs)) funções sem documentação")
    end

    # 7. Type piracy potencial
    if occursin(r"Base\.\w+\(", content)
        push!(issues, "Possível type piracy - extensão de funções Base detectada")
    end

    return issues
end

"""
    generate_recommendations(smells::Vector{String}, issues::Vector{String}, complexity::Float64) -> Vector{String}

Gera recomendações baseadas nos problemas encontrados
"""
function generate_recommendations(smells::Vector{String}, issues::Vector{String}, complexity::Float64)
    recommendations = String[]

    # Recomendações baseadas em complexidade
    if complexity > 10
        push!(recommendations, "Reduzir complexidade ciclomática: refatorar funções grandes")
        push!(recommendations, "Considerar padrão Strategy para reduzir condicionais")
    end

    # Recomendações baseadas em smells
    if any(s -> occursin("Função muito longa", s), smells)
        push!(recommendations, "Quebrar funções longas em funções menores e mais focadas")
        push!(recommendations, "Aplicar princípio de responsabilidade única")
    end

    if any(s -> occursin("Muitos parâmetros", s), smells)
        push!(recommendations, "Usar structs ou named tuples para agrupar parâmetros relacionados")
        push!(recommendations, "Considerar padrão Parameter Object")
    end

    if any(s -> occursin("Aninhamento", s), smells)
        push!(recommendations, "Usar early returns para reduzir aninhamento")
        push!(recommendations, "Extrair condições complexas em funções auxiliares")
    end

    # Recomendações baseadas em issues
    if any(i -> occursin("muito longa", i), issues)
        push!(recommendations, "Configurar editor para quebrar linhas em 92 caracteres")
        push!(recommendations, "Usar formatação automática: make format")
    end

    if any(i -> occursin("whitespace", i), issues)
        push!(recommendations, "Configurar editor para remover trailing whitespace")
        push!(recommendations, "Habilitar formatação automática no save")
    end

    if any(i -> occursin("documentação", i), issues)
        push!(recommendations, "Adicionar docstrings para todas as funções públicas")
        push!(recommendations, "Seguir padrão de documentação Julia")
    end

    # Recomendações gerais de qualidade
    if length(smells) + length(issues) > 10
        push!(recommendations, "Considerar refatoração significativa do código")
        push!(recommendations, "Implementar testes unitários abrangentes")
    end

    return unique(recommendations)
end

"""
    calculate_detailed_metrics(content::String, lines::Vector{String}) -> Dict{String, Any}

Calcula métricas detalhadas do código
"""
function calculate_detailed_metrics(content::String, lines::Vector{String})
    metrics = Dict{String, Any}()

    # Métricas básicas
    metrics["total_lines"] = length(lines)
    metrics["lines_of_code"] = count_lines_of_code(lines)
    metrics["comment_lines"] = count_comment_lines(lines)
    metrics["blank_lines"] = count(isempty ∘ strip, lines)

    # Métricas de complexidade
    metrics["function_count"] = length(collect(eachmatch(r"function\s+\w+", content)))
    metrics["macro_count"] = length(collect(eachmatch(r"macro\s+\w+", content)))
    metrics["struct_count"] = length(collect(eachmatch(r"struct\s+\w+", content)))
    metrics["module_count"] = length(collect(eachmatch(r"module\s+\w+", content)))

    # Métricas de qualidade
    metrics["avg_line_length"] = mean(length.(lines))
    metrics["max_line_length"] = maximum(length.(lines))
    metrics["comment_ratio"] = calculate_comment_ratio(lines)
    metrics["complexity_density"] = metrics["function_count"] > 0 ?
        calculate_cyclomatic_complexity(content) / metrics["function_count"] : 0.0

    # Métricas de imports e dependencies
    metrics["using_statements"] = length(collect(eachmatch(r"^\s*using\s+", content)))
    metrics["import_statements"] = length(collect(eachmatch(r"^\s*import\s+", content)))

    return metrics
end

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

"""
Analisa comprimento das funções
"""
function analyze_function_lengths(content::String)
    function_lengths = Dict{String, Int}()

    # Padrão simplificado para detectar funções
    function_pattern = r"function\s+(\w+).*?\n(.*?)(?=\nfunction|\nend|$)"s

    for match in eachmatch(function_pattern, content)
        func_name = match.captures[1]
        func_body = match.captures[2]
        line_count = length(split(func_body, "\n"))
        function_lengths[func_name] = line_count
    end

    return function_lengths
end

"""
Analisa parâmetros das funções
"""
function analyze_function_parameters(content::String)
    param_counts = Dict{String, Int}()

    # Padrão para detectar funções e contar parâmetros
    function_pattern = r"function\s+(\w+)\s*\(([^)]*)\)"

    for match in eachmatch(function_pattern, content)
        func_name = match.captures[1]
        params = match.captures[2]

        if isempty(strip(params))
            param_count = 0
        else
            # Contar parâmetros separados por vírgula
            param_count = length(split(params, ','))
        end

        param_counts[func_name] = param_count
    end

    return param_counts
end

"""
Calcula nível máximo de aninhamento
"""
function calculate_max_nesting(lines::Vector{String})
    max_nesting = 0
    current_nesting = 0

    for line in lines
        trimmed = strip(line)

        # Palavras-chave que aumentam aninhamento
        if occursin(r"\b(if|for|while|try|function|macro|struct|module)\b", trimmed)
            current_nesting += 1
            max_nesting = max(max_nesting, current_nesting)
        end

        # Palavras-chave que diminuem aninhamento
        if occursin(r"\bend\b", trimmed)
            current_nesting = max(0, current_nesting - 1)
        end
    end

    return max_nesting
end

"""
Detecta possível duplicação de código
"""
function detect_code_duplication(lines::Vector{String})
    duplicates = []

    # Algoritmo simples: procurar blocos de 3+ linhas idênticas
    for i in 1:(length(lines) - 3)
        block = lines[i:i+2]

        # Pular blocos com linhas vazias ou comentários
        if any(line -> isempty(strip(line)) || startswith(strip(line), "#"), block)
            continue
        end

        # Procurar blocos similares
        for j in (i+3):length(lines)-2
            if j + 2 <= length(lines)
                other_block = lines[j:j+2]
                if block == other_block
                    push!(duplicates, (i, j))
                    break
                end
            end
        end
    end

    return duplicates
end

"""
Analisa convenções de nomenclatura
"""
function analyze_naming_conventions(content::String)
    issues = String[]

    # Verificar nomes de funções (snake_case)
    func_names = [m.captures[1] for m in eachmatch(r"function\s+(\w+)", content)]
    for name in func_names
        if !occursin(r"^[a-z][a-z0-9_]*$", name)
            push!(issues, "Nome de função não segue snake_case: $name")
        end
    end

    # Verificar nomes de structs (PascalCase)
    struct_names = [m.captures[1] for m in eachmatch(r"struct\s+(\w+)", content)]
    for name in struct_names
        if !occursin(r"^[A-Z][A-Za-z0-9]*$", name)
            push!(issues, "Nome de struct não segue PascalCase: $name")
        end
    end

    # Verificar constantes (UPPER_CASE)
    const_names = [m.captures[1] for m in eachmatch(r"const\s+(\w+)", content)]
    for name in const_names
        if !occursin(r"^[A-Z][A-Z0-9_]*$", name)
            push!(issues, "Nome de constante não segue UPPER_CASE: $name")
        end
    end

    return issues
end

"""
Calcula ratio de comentários
"""
function calculate_comment_ratio(lines::Vector{String})
    comment_lines = count_comment_lines(lines)
    total_lines = length(lines)

    return total_lines > 0 ? comment_lines / total_lines : 0.0
end

"""
Conta linhas de comentário
"""
function count_comment_lines(lines::Vector{String})
    comment_count = 0
    in_multiline_comment = false

    for line in lines
        trimmed = strip(line)

        # Comentários multilinhas
        if occursin(r"#=", trimmed)
            in_multiline_comment = true
            comment_count += 1
            continue
        end

        if in_multiline_comment
            comment_count += 1
            if occursin(r"=#", trimmed)
                in_multiline_comment = false
            end
            continue
        end

        # Comentários de linha única
        if startswith(trimmed, "#")
            comment_count += 1
        end
    end

    return comment_count
end

"""
Detecta funções sem documentação
"""
function detect_undocumented_functions(content::String)
    undocumented = String[]

    # Padrão para funções e suas possíveis docstrings
    lines = split(content, "\n")

    for (i, line) in enumerate(lines)
        if occursin(r"^\s*function\s+(\w+)", line)
            func_match = match(r"function\s+(\w+)", line)
            if func_match !== nothing
                func_name = func_match.captures[1]

                # Verificar se há docstring antes da função
                has_docstring = false

                # Procurar docstring nas linhas anteriores
                for j in max(1, i-5):(i-1)
                    prev_line = strip(lines[j])
                    if occursin(r'^"""', prev_line) || occursin(r"^'''", prev_line)
                        has_docstring = true
                        break
                    end
                end

                if !has_docstring
                    push!(undocumented, func_name)
                end
            end
        end
    end

    return undocumented
end

"""
    analyze_project(project_path::String = ".") -> ProjectQualityResult

Analisa qualidade de todo o projeto
"""
function analyze_project(project_path::String = ".")
    println("📊 Análise de Qualidade do Projeto")
    println("=" ^ 33)

    # Encontrar arquivos Julia
    julia_files = find_julia_files(project_path)

    if isempty(julia_files)
        throw(ArgumentError("Nenhum arquivo Julia encontrado em $project_path"))
    end

    println("📁 Analisando $(length(julia_files)) arquivos Julia...")

    # Analisar cada arquivo
    file_results = FileQualityResult[]

    for file in julia_files
        try
            result = analyze_file(file)
            push!(file_results, result)

            # Log progress
            quality_level = result.maintainability_index >= 80 ? "🟢" :
                           result.maintainability_index >= 60 ? "🟡" : "🔴"
            println("   $quality_level $(basename(file)): $(round(result.maintainability_index, digits=1))/100")

        catch e
            println("   ❌ Erro analisando $(basename(file)): $e")
        end
    end

    # Calcular métricas do projeto
    project_metrics = calculate_project_metrics(file_results)
    overall_quality_score = calculate_overall_quality_score(file_results)
    critical_issues = identify_critical_issues(file_results)
    recommendations = generate_project_recommendations(file_results, project_metrics)

    return ProjectQualityResult(
        project_path,
        now(),
        overall_quality_score,
        file_results,
        project_metrics,
        critical_issues,
        recommendations,
        Dict{String, Vector{Float64}}()  # trends - implementar em versão futura
    )
end

"""
    calculate_project_metrics(file_results::Vector{FileQualityResult}) -> Dict{String, Any}

Calcula métricas agregadas do projeto
"""
function calculate_project_metrics(file_results::Vector{FileQualityResult})
    if isempty(file_results)
        return Dict{String, Any}()
    end

    metrics = Dict{String, Any}()

    # Métricas agregadas
    metrics["total_files"] = length(file_results)
    metrics["total_loc"] = sum(r -> r.lines_of_code, file_results)
    metrics["avg_complexity"] = mean(r -> r.complexity_score, file_results)
    metrics["avg_maintainability"] = mean(r -> r.maintainability_index, file_results)

    # Distribuição de qualidade
    high_quality_files = count(r -> r.maintainability_index >= 80, file_results)
    medium_quality_files = count(r -> 60 <= r.maintainability_index < 80, file_results)
    low_quality_files = count(r -> r.maintainability_index < 60, file_results)

    metrics["high_quality_files"] = high_quality_files
    metrics["medium_quality_files"] = medium_quality_files
    metrics["low_quality_files"] = low_quality_files

    # Problemas agregados
    total_smells = sum(r -> length(r.code_smells), file_results)
    total_issues = sum(r -> length(r.quality_issues), file_results)

    metrics["total_code_smells"] = total_smells
    metrics["total_quality_issues"] = total_issues
    # Proteção contra divisão por zero
    metrics["issues_per_file"] = if length(file_results) > 0
        (total_smells + total_issues) / length(file_results)
    else
        0.0
    end

    return metrics
end

"""
    calculate_overall_quality_score(file_results::Vector{FileQualityResult}) -> Float64

Calcula score geral de qualidade do projeto
"""
function calculate_overall_quality_score(file_results::Vector{FileQualityResult})
    if isempty(file_results)
        return 0.0
    end

    # Peso por linhas de código
    total_loc = sum(r -> r.lines_of_code, file_results)

    if total_loc == 0
        return mean(r -> r.maintainability_index, file_results)
    end

    # Proteção contra divisão por zero
    weighted_score = if total_loc > 0
        sum(r -> r.maintainability_index * (r.lines_of_code / total_loc), file_results)
    else
        mean(r -> r.maintainability_index, file_results)
    end

    return weighted_score
end

"""
    identify_critical_issues(file_results::Vector{FileQualityResult}) -> Vector{String}

Identifica questões críticas do projeto
"""
function identify_critical_issues(file_results::Vector{FileQualityResult})
    critical_issues = String[]

    # Arquivos com qualidade muito baixa
    low_quality_files = filter(r -> r.maintainability_index < 40, file_results)
    if !isempty(low_quality_files)
        push!(critical_issues, "$(length(low_quality_files)) arquivos com qualidade crítica (< 40/100)")
    end

    # Complexidade excessiva
    high_complexity_files = filter(r -> r.complexity_score > 15, file_results)
    if !isempty(high_complexity_files)
        push!(critical_issues, "$(length(high_complexity_files)) arquivos com complexidade excessiva")
    end

    # Muitos code smells
    smelly_files = filter(r -> length(r.code_smells) > 5, file_results)
    if !isempty(smelly_files)
        push!(critical_issues, "$(length(smelly_files)) arquivos com muitos code smells")
    end

    return critical_issues
end

"""
    generate_project_recommendations(file_results, metrics) -> Vector{String}

Gera recomendações para o projeto
"""
function generate_project_recommendations(file_results::Vector{FileQualityResult}, metrics::Dict{String, Any})
    recommendations = String[]

    # Recomendações baseadas na qualidade geral
    if metrics["avg_maintainability"] < 70
        push!(recommendations, "Refatoração geral necessária - qualidade abaixo do ideal")
        push!(recommendations, "Implementar revisões de código obrigatórias")
    end

    # Recomendações baseadas na complexidade
    if metrics["avg_complexity"] > 10
        push!(recommendations, "Reduzir complexidade geral do código")
        push!(recommendations, "Implementar análise de complexidade no CI/CD")
    end

    # Recomendações baseadas na distribuição
    if metrics["low_quality_files"] > metrics["total_files"] * 0.2
        push!(recommendations, "Priorizar refatoração dos arquivos de baixa qualidade")
        push!(recommendations, "Estabelecer padrões mínimos de qualidade")
    end

    # Recomendações específicas
    if metrics["issues_per_file"] > 3
        push!(recommendations, "Implementar linting automático no pre-commit")
        push!(recommendations, "Configurar formatação automática obrigatória")
    end

    return recommendations
end

"""
    find_julia_files(path::String) -> Vector{String}

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
