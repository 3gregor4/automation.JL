"""
CSGA Scoring System - Julia Project Assessment
Sistema de pontuação científica para os 4 pilares fundamentais:

  - Security First (30%)
  - Clean Code (25%)
  - Green Code (20%)
  - Advanced Automation (25%)
"""
module CSGAScoring

using Statistics
using JSON3
using TOML
using Dates

export CSGAScore, evaluate_project, generate_report, print_detailed_report

# =============================================================================
# ESTRUTURAS DE DADOS
# =============================================================================

"""
    PillarScore

Representa a pontuação de um pilar individual
"""
struct PillarScore
    name::String
    score::Float64          # 0-100
    weight::Float64         # Peso do pilar (0-1)
    metrics::Dict{String,Float64}
    recommendations::Vector{String}
    critical_issues::Vector{String}
end

"""
    CSGAScore

Pontuação completa do projeto usando metodologia CSGA híbrida
"""
struct CSGAScore
    project_name::String
    timestamp::DateTime
    security_pillar::PillarScore      # Security First (30%)
    clean_code_pillar::PillarScore    # Clean Code (25%)
    green_code_pillar::PillarScore    # Green Code (20%)
    automation_pillar::PillarScore    # Advanced Automation (25%)
    overall_score::Float64            # Pontuação ponderada total
    maturity_level::String            # Iniciante, Intermediário, Avançado, Expert
    compliance_status::String         # Conforme, Não-conforme, Crítico
end

# =============================================================================
# PILAR 1: SECURITY FIRST (Peso: 30%)
# =============================================================================

function evaluate_security_pillar(project_path::String)::PillarScore
    metrics = Dict{String,Float64}()
    recommendations = String[]
    critical_issues = String[]

    # 1. Package Security Score (30 pontos)
    package_score = evaluate_package_security(project_path)
    metrics["package_security"] = package_score

    if package_score < 80
        push!(critical_issues, "Pacotes não-oficiais detectados")
        push!(recommendations, "Migrar para pacotes oficiais JuliaLang apenas")
    end

    # 2. Code Security Score (25 pontos)
    code_security_score = evaluate_code_security(project_path)
    metrics["code_security"] = code_security_score

    if code_security_score < 70
        push!(critical_issues, "Vulnerabilidades de código detectadas")
        push!(recommendations, "Implementar validação de entrada e sanitização")
    end

    # 3. Dependency Management Score (25 pontos)
    dependency_score = evaluate_dependency_management(project_path)
    metrics["dependency_management"] = dependency_score

    if dependency_score < 75
        push!(recommendations, "Implementar versionamento preciso no Project.toml")
    end

    # 4. Security Automation Score (20 pontos)
    security_automation_score = evaluate_security_automation(project_path)
    metrics["security_automation"] = security_automation_score

    if security_automation_score < 60
        push!(recommendations, "Configurar auditorias automáticas de segurança")
    end

    # Cálculo da pontuação final ponderada
    final_score = (
        package_score * 0.30 +
        code_security_score * 0.25 +
        dependency_score * 0.25 +
        security_automation_score * 0.20
    )

    return PillarScore(
        "Security First",
        final_score,
        0.30,  # 30% do peso total conforme memória
        metrics,
        recommendations,
        critical_issues,
    )
end

function evaluate_package_security(project_path::String)::Float64
    project_file = joinpath(project_path, "Project.toml")
    if !isfile(project_file)
        return 0.0
    end

    try
        project_data = TOML.parsefile(project_file)
        deps = get(project_data, "deps", Dict())

        # Pacotes oficiais conforme memória do projeto
        official_packages = Set([
            "Revise",
            "BenchmarkTools",
            "Test",
            "Documenter",
            "DataFrames",
            "CSV",
            "Plots",
            "JSON3",
            "HTTP",
            "PlutoUI",
            "IJulia",
            "PackageCompiler",
            "Debugger",
            "ProfileView",
            "Pluto",
            "SpecialFunctions",
            "StaticArrays",
            "Statistics",
            "StatsBase",
            "StringEncodings",
            "ThreadsX",
            "LinearAlgebra",
            "Random",
            "Dates",
            "Printf",
            "Logging",
            "Pkg",
            "Distributions",
            "FileIO",
            "JLD2",
        ])

        if isempty(deps)
            return 100.0  # Sem dependências = máxima segurança
        end

        official_count = count(pkg -> pkg in official_packages, keys(deps))
        official_ratio = official_count / length(deps)

        # Bonificação por compatibilidade versionada
        compat = get(project_data, "compat", Dict())
        compat_bonus = min(20.0, (length(compat) / length(deps)) * 20.0)

        base_score = official_ratio * 80.0
        return min(100.0, base_score + compat_bonus)
    catch e
        return 10.0  # Erro de parsing = score baixo
    end
end

function evaluate_code_security(project_path::String)::Float64
    julia_files = []
    for (root, dirs, files) in walkdir(project_path)
        for file in files
            if endswith(file, ".jl") && !contains(root, ".git")
                push!(julia_files, joinpath(root, file))
            end
        end
    end

    if isempty(julia_files)
        return 50.0
    end

    # Usar memory-efficient processing para arquivos grandes
    security_violations = 0
    total_lines = 0

    # Padrões de risco de segurança
    risk_patterns = [
        r"password\s*=\s*[\"'][^\"']+[\"']"i,
        r"secret\s*=\s*[\"'][^\"']+[\"']"i,
        r"api_key\s*=\s*[\"'][^\"']+[\"']"i,
        r"token\s*=\s*[\"'][^\"']+[\"']"i,
        r"eval\s*\(",
        r"@eval",
        r"unsafe_",
        r"ccall\s*\(",
    ]

    # Process files with memory management
    for file_path in julia_files
        try
            # Use safe file read with automatic cleanup
            content = if isfile(file_path)
                try
                    open(file_path, "r") do file
                        read(file, String)
                    end
                catch e
                    @warn "Error reading $file_path: $e"
                    continue
                end
            else
                continue
            end

            lines = split(content, '\n')
            total_lines += length(lines)

            # Memory-efficient line processing
            for line in lines
                for pattern in risk_patterns
                    if occursin(pattern, line)
                        security_violations += 1
                        break
                    end
                end
            end

            # Remover garbage collection forçado para melhorar performance
            if length(content) > 100_000  # 100KB threshold
                @debug "Processando arquivo grande: $(length(content)) bytes"
            end

        catch e
            @warn "Error processing $file_path: $e"
            continue
        end
    end

    # Proteção robusta contra divisão por zero
    if total_lines <= 0
        return 50.0
    end

    violation_rate = security_violations / total_lines
    return max(0.0, 100.0 - (violation_rate * 1000))
end

function evaluate_dependency_management(project_path::String)::Float64
    project_file = joinpath(project_path, "Project.toml")
    manifest_file = joinpath(project_path, "Manifest.toml")

    score = 0.0

    # Project.toml existe e bem formado (25 pontos)
    if isfile(project_file)
        try
            project_data = TOML.parsefile(project_file)
            score += 25.0

            # Tem seção [compat] (25 pontos)
            if haskey(project_data, "compat")
                compat = project_data["compat"]
                deps = get(project_data, "deps", Dict())
                if !isempty(deps)
                    compat_ratio = length(compat) / length(deps)
                    score += min(25.0, compat_ratio * 25.0)
                else
                    score += 25.0  # Sem deps = sem problemas
                end
            end

            # Metadados completos (25 pontos)
            metadata_fields = ["name", "uuid", "authors", "version"]
            metadata_score =
                count(field -> haskey(project_data, field), metadata_fields) /
                length(metadata_fields)
            score += metadata_score * 25.0

        catch e
            score += 10.0
        end
    end

    # Manifest.toml existe (25 pontos)
    if isfile(manifest_file)
        score += 25.0
    end

    return min(100.0, score)
end

function evaluate_security_automation(project_path::String)::Float64
    score = 0.0

    # Makefile com targets de segurança (25 pontos)
    makefile_path = joinpath(project_path, "Makefile")
    if isfile(makefile_path)
        try
            makefile_content = read(makefile_path, String)
            security_targets = ["audit", "security", "scan"]

            for target in security_targets
                if occursin(Regex("^$(target):", "m"), makefile_content)
                    score += 8.33
                end
            end
        catch e
            # Ignorar erro de leitura
        end
    end

    # AGENTS.md com instruções de segurança (25 pontos)
    agents_file = joinpath(project_path, "AGENTS.md")
    if isfile(agents_file)
        try
            agents_content = read(agents_file, String)
            if occursin("Security", agents_content) && occursin("audit", agents_content)
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    # Testes de segurança automatizados (25 pontos)
    test_dir = joinpath(project_path, "test")
    if isdir(test_dir)
        test_files = readdir(test_dir)
        security_test_exists = any(f -> occursin("security", lowercase(f)), test_files)
        if security_test_exists
            score += 25.0
        end
    end

    # Git hooks para validação (25 pontos)
    git_hooks_dir = joinpath(project_path, ".git", "hooks")
    if isdir(git_hooks_dir)
        hooks = readdir(git_hooks_dir)
        if any(h -> occursin("pre-commit", h), hooks)
            score += 25.0
        end
    end

    return min(100.0, score)
end

# =============================================================================
# INCLUIR EXTENSÕES
# =============================================================================

# Incluir as extensões do sistema CSGA
include("csga_extension.jl")
include("csga_final.jl")

end # module
