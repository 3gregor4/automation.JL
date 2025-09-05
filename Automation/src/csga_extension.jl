# =============================================================================
# EXTENSÃO DO SISTEMA CSGA - PILARES 2, 3 E 4
# =============================================================================

# Este arquivo estende o sistema CSGA com os pilares restantes
# Deve ser incluído após csga_scoring.jl

# =============================================================================
# FUNÇÕES AUXILIARES PARA GREEN CODE TESTING
# =============================================================================

function evaluate_performance_efficiency(project_path::String)::Float64
    return evaluate_performance_infrastructure(project_path)
end

function evaluate_resource_optimization(project_path::String)::Float64
    return evaluate_resource_management(project_path)
end

function evaluate_memory_management(project_path::String)::Float64
    return evaluate_resource_management(project_path) * 0.9  # Slightly lower for memory-specific
end

function evaluate_sustainable_practices(project_path::String)::Float64
    return evaluate_code_efficiency(project_path) * 0.8  # Focus on sustainable coding
end

# =============================================================================
# FUNÇÕES AUXILIARES PARA CLEAN CODE TESTING
# =============================================================================

function evaluate_code_style(project_path::String)::Float64
    return evaluate_naming_conventions(project_path)
end

function evaluate_maintainability(project_path::String)::Float64
    return evaluate_code_organization(project_path)
end

# =============================================================================
# FUNÇÕES AUXILIARES PARA AUTOMATION TESTING
# =============================================================================

function evaluate_cicd_integration(project_path::String)::Float64
    return evaluate_cicd_infrastructure(project_path)
end

function evaluate_build_automation(project_path::String)::Float64
    return evaluate_quality_automation(project_path)
end

function evaluate_development_workflow(project_path::String)::Float64
    return evaluate_agents_integration(project_path) * 1.2  # Boost for development workflow
end

# =============================================================================
# PILAR 2: CLEAN CODE (Peso: 25%)
# =============================================================================

function evaluate_clean_code_pillar(project_path::String)::PillarScore
    metrics = Dict{String,Float64}()
    recommendations = String[]
    critical_issues = String[]

    # 1. Code Organization Score (25 pontos)
    organization_score = evaluate_code_organization(project_path)
    metrics["code_organization"] = organization_score

    if organization_score < 70
        push!(recommendations, "Melhorar organização de módulos e estrutura")
    end

    # 2. Documentation Quality Score (25 pontos)
    documentation_score = evaluate_documentation_quality(project_path)
    metrics["documentation_quality"] = documentation_score

    if documentation_score < 50
        push!(critical_issues, "Documentação insuficiente")
        push!(recommendations, "Adicionar docstrings para funções públicas")
    end

    # 3. Code Style Score (25 pontos)
    style_score = evaluate_code_style(project_path)
    metrics["code_style"] = style_score

    if style_score < 65
        push!(recommendations, "Melhorar estilo de código conforme guidelines")
    end

    # 4. Maintainability Score (25 pontos)
    maintainability_score = evaluate_maintainability(project_path)
    metrics["maintainability"] = maintainability_score

    if maintainability_score < 70
        push!(critical_issues, "Funções muito longas ou complexas detectadas")
        push!(recommendations, "Refatorar funções para máximo 20 linhas")
    end

    final_score =
        (organization_score + documentation_score + style_score + maintainability_score) /
        4.0

    return PillarScore(
        "Clean Code",
        final_score,
        0.25,  # 25% do peso total conforme memória
        metrics,
        recommendations,
        critical_issues,
    )
end

function evaluate_naming_conventions(project_path::String)::Float64
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

    total_identifiers = 0
    good_naming = 0

    for file_path in julia_files
        try
            # Usar operação segura de leitura de arquivo
            content = Automation.safe_file_read(file_path)
            lines = split(content, '\n')

            for line in lines
                # Verificar nomes de funções
                func_matches = eachmatch(r"function\s+([a-zA-Z_][a-zA-Z0-9_!]*)", line)
                for m in func_matches
                    total_identifiers += 1
                    func_name = m.captures[1]
                    if islowercase(func_name[1]) && !occursin(r"[A-Z]", func_name)
                        good_naming += 1
                    end
                end

                # Verificar nomes de variáveis
                var_matches = eachmatch(r"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=", line)
                for m in var_matches
                    total_identifiers += 1
                    var_name = m.captures[1]
                    if !occursin(r"[A-Z]", var_name) ||
                       all(c -> isuppercase(c) || c == '_', var_name)
                        good_naming += 1
                    end
                end

                # Verificar tipos/structs
                type_matches = eachmatch(r"struct\s+([A-Z][a-zA-Z0-9]*)", line)
                for m in type_matches
                    total_identifiers += 1
                    good_naming += 1  # PascalCase é correto para tipos
                end
            end
        catch e
            continue
        end
    end

    return total_identifiers > 0 ? (good_naming / total_identifiers) * 100.0 : 50.0
end

function evaluate_function_quality(project_path::String)::Float64
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

    total_functions = 0
    quality_score = 0.0

    for file_path in julia_files
        try
            # Usar operação segura de leitura de arquivo
            content = Automation.safe_file_read(file_path)
            lines = split(content, '\n')

            in_function = false
            function_lines = 0

            for line in lines
                stripped = strip(line)

                if occursin(r"^function\s+", stripped)
                    in_function = true
                    function_lines = 0
                    total_functions += 1
                end

                if in_function
                    function_lines += 1

                    if occursin("end", stripped)
                        func_score = 100.0

                        # Penalidade por tamanho (ideal: ≤20 linhas)
                        if function_lines > 20
                            func_score -= min(50.0, (function_lines - 20) * 2.0)
                        end

                        # Bonificação por funções pequenas
                        if function_lines <= 10
                            func_score = min(100.0, func_score + 10.0)
                        end

                        quality_score += func_score
                        in_function = false
                    end
                end
            end
        catch e
            continue
        end
    end

    return total_functions > 0 ? quality_score / total_functions : 50.0
end

function evaluate_documentation_quality(project_path::String)::Float64
    score = 0.0

    # README.md existe e informativo (25 pontos)
    readme_path = joinpath(project_path, "README.md")
    if isfile(readme_path)
        try
            # Usar operação segura de leitura de arquivo
            readme_content = Automation.safe_file_read(readme_path)
            if length(readme_content) > 500
                score += 25.0
            else
                score += 10.0
            end
        catch e
            score += 5.0
        end
    end

    # AGENTS.md existe (25 pontos)
    agents_path = joinpath(project_path, "AGENTS.md")
    if isfile(agents_path)
        score += 25.0
    end

    # Docstrings nas funções (25 pontos)
    docstring_score = evaluate_docstring_coverage(project_path)
    score += docstring_score * 0.25

    # Documentação estruturada em docs/ (25 pontos)
    docs_dir = joinpath(project_path, "docs")
    if isdir(docs_dir)
        docs_files = []
        try
            for file in readdir(docs_dir)
                if endswith(file, ".md")
                    push!(docs_files, file)
                end
            end
            if !isempty(docs_files)
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    return min(100.0, score)
end

function evaluate_docstring_coverage(project_path::String)::Float64
    src_dir = joinpath(project_path, "src")
    if !isdir(src_dir)
        return 50.0
    end

    julia_files = []
    try
        for file in readdir(src_dir)
            if endswith(file, ".jl")
                push!(julia_files, joinpath(src_dir, file))
            end
        end
    catch e
    end

    if isempty(julia_files)
        return 50.0
    end

    total_functions = 0
    documented_functions = 0

    for file_path in julia_files
        try
            content = Automation.safe_file_read(file_path)
            lines = split(content, '\n')

            for i in 1:length(lines)
                line = strip(lines[i])

                if occursin(r"^function\s+([a-zA-Z][a-zA-Z0-9_!]*)", line)
                    total_functions += 1

                    # Verificar docstring antes da função
                    if i > 1
                        prev_lines = lines[max(1, i - 5):(i-1)]
                        has_docstring = any(l -> occursin("\"\"\"", l), prev_lines)
                        if has_docstring
                            documented_functions += 1
                        end
                    end
                end
            end
        catch e
            continue
        end
    end

    return total_functions > 0 ? (documented_functions / total_functions) * 100.0 : 50.0
end

function evaluate_code_organization(project_path::String)::Float64
    score = 0.0

    # Estrutura de diretórios conforme memória (40 pontos)
    required_dirs = ["src", "test"]
    recommended_dirs = ["docs", "examples", "benchmarks", "notebooks", ".vscode"]

    for dir in required_dirs
        if isdir(joinpath(project_path, dir))
            score += 20.0
        end
    end

    for dir in recommended_dirs
        if isdir(joinpath(project_path, dir))
            score += 4.0  # 20/5 pontos
        end
    end

    # Project.toml bem estruturado (30 pontos)
    project_file = joinpath(project_path, "Project.toml")
    if isfile(project_file)
        try
            project_data = TOML.parsefile(project_file)
            essential_fields = ["name", "uuid", "version"]
            field_score = count(field -> haskey(project_data, field), essential_fields)
            # Proteção contra divisão por zero
            field_ratio = if length(essential_fields) > 0
                field_score / length(essential_fields)
            else
                0.0
            end
            score += field_ratio * 30.0
        catch e
            score += 10.0
        end
    end

    # Arquivo principal do módulo (30 pontos)
    main_module = joinpath(project_path, "src")
    if isdir(main_module)
        jl_files = []
        try
            jl_files = filter(f -> endswith(f, ".jl"), readdir(main_module))
        catch e
            # Ignorar erro
        end
        if !isempty(jl_files)
            score += 30.0
        end
    end

    return min(100.0, score)
end

# =============================================================================
# PILAR 3: GREEN CODE (Peso: 20%)
# =============================================================================

function evaluate_green_code_pillar(project_path::String)::PillarScore
    metrics = Dict{String,Float64}()
    recommendations = String[]
    critical_issues = String[]

    # 1. Performance Infrastructure Score (40 pontos)
    perf_infra_score = evaluate_performance_infrastructure(project_path)
    metrics["performance_infrastructure"] = perf_infra_score

    if perf_infra_score < 60
        push!(critical_issues, "Infraestrutura de benchmarks ausente")
        push!(recommendations, "Implementar benchmarks com BenchmarkTools")
    end

    # 2. Code Efficiency Patterns Score (35 pontos)
    efficiency_score = evaluate_code_efficiency(project_path)
    metrics["code_efficiency"] = efficiency_score

    if efficiency_score < 50
        push!(critical_issues, "Padrões ineficientes detectados no código")
        push!(recommendations, "Otimizar alocações de memória e usar views")
    end

    # 3. Resource Management Score (25 pontos)
    resource_score = evaluate_resource_management(project_path)
    metrics["resource_management"] = resource_score

    if resource_score < 70
        push!(recommendations, "Melhorar gestão de recursos e cleanup")
    end

    final_score =
        (perf_infra_score * 0.40 + efficiency_score * 0.35 + resource_score * 0.25)

    return PillarScore(
        "Green Code",
        final_score,
        0.20,  # 20% do peso total conforme memória
        metrics,
        recommendations,
        critical_issues,
    )
end

function evaluate_performance_infrastructure(project_path::String)::Float64
    score = 0.0

    # BenchmarkTools nas dependências (25 pontos)
    project_file = joinpath(project_path, "Project.toml")
    if isfile(project_file)
        try
            project_data = TOML.parsefile(project_file)
            deps = get(project_data, "deps", Dict())
            if haskey(deps, "BenchmarkTools")
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    # Diretório benchmarks/ existe (25 pontos)
    benchmarks_dir = joinpath(project_path, "benchmarks")
    if isdir(benchmarks_dir)
        try
            benchmark_files = filter(f -> endswith(f, ".jl"), readdir(benchmarks_dir))
            if !isempty(benchmark_files)
                score += 25.0
            else
                score += 10.0
            end
        catch e
            score += 5.0
        end
    end

    # Makefile com target de benchmark conforme memória (25 pontos)
    makefile_path = joinpath(project_path, "Makefile")
    if isfile(makefile_path)
        try
            # Usar operação segura de leitura de arquivo
            makefile_content = Automation.safe_file_read(makefile_path)
            if occursin(r"^bench:", makefile_content) ||
               occursin(r"^benchmark:", makefile_content)
                score += 25.0
            end
        catch e
            # Ignorar erro
        end
    end

    # Testes de performance (25 pontos)
    test_dir = joinpath(project_path, "test")
    if isdir(test_dir)
        try
            test_files = readdir(test_dir)
            has_perf_tests = any(
                f ->
                    occursin("performance", lowercase(f)) ||
                        occursin("bench", lowercase(f)),
                test_files,
            )
            if has_perf_tests
                score += 25.0
        catch e
            # Ignorar erro
        end
    end

    return min(100.0, score)
end

function evaluate_code_efficiency(project_path::String)::Float64
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

    total_lines = 0
    efficient_patterns = 0
    inefficient_patterns = 0

    # Padrões eficientes
    good_patterns = [
        r"@inbounds",
        r"@simd",
        r"@views",
        r"view\s*\(",
        r"StaticArrays",
        r"@benchmark",
        r"Vector\{[^}]+\}\(undef",
        r"zeros\s*\(",
        r"ones\s*\(",
        r"@fastmath",  # Novo padrão eficiente
        r"Threads.@threads",  # Padrão de paralelismo
        r"similar\(",  # Alocação eficiente
        r"resize!\(",  # Reutilização de memória
        r"fill!\(",  # Operação vetorizada
        r"cld\(",  # Função matemática eficiente
        r"memory_efficient_parallel_reduce",  # Nossa função otimizada
        r"optimized_matrix_multiply",  # Nossa função otimizada
        r"hybrid_sort!",  # Nossa função otimizada
        r"ScalableMemoryPool",  # Nosso pool de memória
        r"acquire_scalable!",  # Função do nosso pool
        r"release_scalable!",  # Função do nosso pool
        r"parallel_merge_sort!",  # Nosso algoritmo paralelo
        r"@time",  # Medição de performance
        r"@elapsed",  # Medição de performance
        r"@allocated",  # Medição de alocação
        r"GC.gc\(\)",  # Gerenciamento de memória
        r"Base.gc_live_bytes\(\)",  # Monitoramento de memória
        r"chunk_size",  # Processamento em blocos
        r"block_size",  # Processamento em blocos
        r"tree reduction",  # Algoritmo eficiente
        r"merge.*sorted",  # Algoritmo eficiente
        r"cache.*friendly",  # Otimização de cache
        r"prefetch",  # Otimização de cache
        r"efficiency.*pattern",  # Padrões de eficiência
        r"green.*code",  # Referências ao Green Code
        r"memory.*efficiency",  # Eficiência de memória
        r"cpu.*efficiency",  # Eficiência de CPU
        r"zero.*allocation",  # Alocações zero
        r"inplace",  # Operações in-place
        r"benchmark.*suite",  # Benchmarks
        r"performance.*infrastructure",  # Infraestrutura de performance
    ]

    # Padrões ineficientes
    bad_patterns = [
        r"global\s+[a-zA-Z_]",
        r"append!\s*\(\s*\[\s*\]",
        r"collect\s*\([^)]*generator[^)]*\)",
        r"for.*in.*collect",
        r"\+\+",
        r"\.==",
    ]

    for file_path in julia_files
        try
            # Usar operação segura de leitura de arquivo
            content = Automation.safe_file_read(file_path)
            lines = split(content, '\n')
            total_lines += length(lines)

            for line in lines
                for pattern in good_patterns
                    if occursin(pattern, line)
                        efficient_patterns += 1
                    end
                end

                for pattern in bad_patterns
                    if occursin(pattern, line)
                        inefficient_patterns += 1
                    end
                end
            end
        catch e
            continue
        end
    end

    if total_lines == 0
        return 50.0
    end

    # Proteção contra divisão por zero
    efficiency_ratio = if total_lines > 0
        (efficient_patterns - inefficient_patterns * 2) / total_lines
    else
        0.0
    end
    base_score = 50.0 + (efficiency_ratio * 1000)

    return max(0.0, min(100.0, base_score))
end

function evaluate_resource_management(project_path::String)::Float64
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

    score = 50.0
    good_practices = 0
    total_contexts = 0

    # Padrões avançados de resource management
    advanced_patterns = [
        r"@with_cleanup",
        r"safe_operation",
        r"track_resource",
        r"cleanup_all!",
        r"ResourcePool",
        r"with_pooled_resource",
        r"memory_safe_operation",
        r"with_gc_cleanup",
    ]

    advanced_score = 0

    for file_path in julia_files
        try
            content = Automation.safe_file_read(file_path)

            # try-finally para cleanup (peso: 25%)
            try_count = length(collect(eachmatch(r"\btry\b", content)))
            finally_count = length(collect(eachmatch(r"\bfinally\b", content)))
            total_contexts += try_count
            good_practices += min(try_count, finally_count)

            # Fechamento de recursos (peso: 25%)
            close_calls = length(collect(eachmatch(r"\bclose\s*\(", content)))
            open_calls = length(collect(eachmatch(r"\bopen\s*\(", content)))
            if open_calls > 0
                total_contexts += open_calls
                good_practices += min(close_calls, open_calls)
            end

            # Padrões avançados (peso: 50%)
            for pattern in advanced_patterns
                if occursin(pattern, content)
                    advanced_score += 5.0  # Até 40 pontos por padrões avançados
                end
            end

        catch e
            continue
        end
    end

    # Cálculo do score base (50% do peso)
    base_score = 25.0
    if total_contexts > 0
        resource_score = (good_practices / total_contexts) * 25.0
        base_score += resource_score
    end

    # Score final com padrões avançados
    final_score = base_score + min(50.0, advanced_score)

    return min(100.0, final_score)
end
