"""
Test Clean Code Pillar - Pilar 2: Clean Code (25%)
Testes específicos para validação do pilar de código limpo CSGA

Objetivos:
- Validar Code Organization Score (30 pontos)
- Validar Documentation Quality Score (25 pontos)
- Validar Code Style Score (25 pontos)
- Validar Maintainability Score (20 pontos)
- Elevar métrica code_maintainability para 90.0+
"""

using Test
using Statistics

@testset "✨ Clean Code Pillar Validation" begin
    println("\n🧹 Testando Clean Code Pillar...")

    # ==========================================================================
    # TESTE 1: CODE ORGANIZATION SCORE (30 pontos)
    # ==========================================================================
    @testset "📁 Code Organization Score" begin
        @testset "Project Structure Validation" begin
            # Usar a função unificada para resolver o caminho do projeto
            project_path = Automation.resolve_project_path(pwd())
            println("   📁 Caminho do projeto: $project_path")

            # Estrutura básica esperada
            expected_dirs = ["src", "test", "docs"]
            for dir in expected_dirs
                @test isdir(joinpath(project_path, dir)) == true
            end

            expected_files = ["Project.toml", "README.md", "Makefile"]
            for file in expected_files
                @test isfile(joinpath(project_path, file)) == true
            end

            println("   ✅ Estrutura de projeto validada")
        end

        @testset "Source Code Organization" begin
            # Usar a função unificada para resolver o caminho do projeto
            project_path = Automation.resolve_project_path(pwd())
            println("   📁 Caminho do projeto: $project_path")

            src_dir = joinpath(project_path, "src")
            if isdir(src_dir)
                src_files = readdir(src_dir)
                julia_files = filter(f -> endswith(f, ".jl"), src_files)

                @test !isempty(julia_files) == true
                @test "Automation.jl" in julia_files

                # Verificar modularidade do código
                module_count = length(julia_files)
                @test module_count >= 3

                println("   ✅ Organização do código fonte: $module_count módulos")
            end
        end

        @testset "Documentation Structure" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            docs_dir = joinpath(project_path, "docs")
            if isdir(docs_dir)
                docs_files = readdir(docs_dir)
                @test !isempty(docs_files) == true

                # Procurar por make.jl para geração automática
                has_makejl = any(f -> f == "make.jl", docs_files)
                if has_makejl
                    println("   ✅ Sistema de documentação automática encontrado")
                end
            end
        end

        @testset "Code Organization Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_code_organization(project_path)
            @test score >= 70.0
            @test score <= 100.0

            println("   ✅ Code Organization Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 2: DOCUMENTATION QUALITY SCORE (25 pontos)
    # ==========================================================================
    @testset "📚 Documentation Quality Score" begin
        @testset "README.md Quality" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            readme_file = joinpath(project_path, "README.md")
            @test isfile(readme_file) == true

            if isfile(readme_file)
                readme_content = read(readme_file, String)
                readme_lines = split(readme_content, '\n')

                @test length(readme_lines) >= 10
                @test occursin("# ", readme_content) == true
                @test occursin("## ", readme_content) == true

                # Verificar seções importantes
                important_sections = ["install", "usage", "example"]
                for section in important_sections
                    has_section =
                        any(line -> occursin(section, lowercase(line)), readme_lines)
                    if has_section
                        println("   ✅ Seção '$section' encontrada em README.md")
                    end
                end
            end
        end

        @testset "Code Documentation (Docstrings)" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            julia_files = []
            for (root, dirs, files) in walkdir(joinpath(project_path, "src"))
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            total_functions = 0
            documented_functions = 0

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)
                        lines = split(content, '\n')

                        # Procurar por definições de função
                        for (i, line) in enumerate(lines)
                            if occursin(r"^function\s+\w+", line) ||
                               occursin(r"^\w+\([^)]*\)\s*=", line)
                                total_functions += 1

                                # Verificar se há docstring antes da função
                                if i > 1 && contains(lines[i-1], "\"\"\"")
                                    documented_functions += 1
                                elseif i > 2 && contains(lines[i-2], "\"\"\"")
                                    documented_functions += 1
                                end
                            end
                        end
                    catch e
                        @warn "Erro analisando $file_path: $e"
                    end
                end
            end

            if total_functions > 0
                documentation_ratio = documented_functions / total_functions
                @test documentation_ratio >= 0.6

                println("   ℹ️  Funções encontradas: $total_functions")
                println(
                    "   ℹ️  Funções documentadas: $documented_functions ($(round(documentation_ratio*100, digits=1))%)",
                )
            end
        end

        @testset "AGENTS.md Documentation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            agents_file = joinpath(project_path, "AGENTS.md")
            if isfile(agents_file)
                agents_content = read(agents_file, String)
                agents_lines = split(agents_content, '\n')

                @test length(agents_lines) >= 50
                @test occursin("# ", agents_content) == true

                # Verificar pilares CSGA
                csga_pillars = ["Security", "Clean", "Green", "Automation"]
                pillar_coverage = 0

                for pillar in csga_pillars
                    if occursin(pillar, agents_content)
                        pillar_coverage += 1
                    end
                end

                @test pillar_coverage >= 3

                println("   ✅ AGENTS.md abrangente: $(pillar_coverage)/4 pilares cobertos")
            end
        end

        @testset "Documentation Quality Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_documentation_quality(project_path)
            @test score >= 60.0
            @test score <= 100.0

            println("   ✅ Documentation Quality Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 3: CODE STYLE SCORE (25 pontos)
    # ==========================================================================
    @testset "🎨 Code Style Score" begin
        @testset "Julia Style Guidelines" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            julia_files = []
            for (root, dirs, files) in walkdir(joinpath(project_path, "src"))
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            style_violations = 0
            total_lines = 0

            # Padrões de estilo que violam as guidelines
            style_patterns = [
                # Funções sem espaço após nome (ex: functionname() em vez de function_name())
                r"\bfunction[a-z][a-zA-Z0-9_]*\(",
                # Variáveis com nomes muito curtos (exceto i, j, k)
                r"\b[a-df-hn-z]\s*=",
                # Espaços antes de parênteses (ex: function_name () em vez de function_name())
                r"\w\s+\(",
                # Espaços antes de colchetes (ex: array [1] em vez de array[1])
                r"\w\s+\[",
            ]

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)
                        lines = split(content, '\n')
                        total_lines += length(lines)

                        for (line_num, line) in enumerate(lines)
                            for pattern in style_patterns
                                if occursin(pattern, line)
                                    style_violations += 1
                                    # Limitar warnings para não sobrecarregar
                                    if style_violations <= 10
                                        @warn "Style violation em $file_path:$line_num: $line"
                                    end
                                end
                            end
                        end
                    catch e
                        @warn "Erro analisando $file_path: $e"
                    end
                end
            end

            violation_rate = total_lines > 0 ? style_violations / total_lines : 0.0
            @test violation_rate <= 0.05

            println("   ℹ️  Linhas analisadas: $total_lines")
            println("   ℹ️  Violações de estilo: $style_violations")
        end

        @testset "Code Style Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_code_style(project_path)
            @test score >= 65.0
            @test score <= 100.0

            println("   ✅ Code Style Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 4: MAINTAINABILITY SCORE (20 pontos)
    # ==========================================================================
    @testset "🔧 Maintainability Score" begin
        @testset "Code Complexity Analysis" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            julia_files = []
            for (root, dirs, files) in walkdir(joinpath(project_path, "src"))
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            total_functions = 0
            complex_functions = 0
            total_lines_of_code = 0

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)
                        lines = split(content, '\n')
                        total_lines_of_code += length(filter(!isempty, lines))

                        # Procurar por definições de função
                        function_starts = []
                        for (i, line) in enumerate(lines)
                            if occursin(r"^function\s+\w+"i, line) ||
                               occursin(r"^\w+\([^)]*\)\s*="i, line)
                                push!(function_starts, i)
                                total_functions += 1
                            end
                        end

                        # Analisar complexidade de cada função
                        for start_line in function_starts
                            end_line = start_line
                            # Procurar pelo fim da função (end)
                            for i in (start_line+1):min(start_line + 100, length(lines))
                                if occursin(r"^\s*end\s*$"i, lines[i])
                                    end_line = i
                                    break
                                end
                            end

                            # Contar linhas na função
                            function_lines = end_line - start_line
                            if function_lines > 50
                                complex_functions += 1
                                if complex_functions <= 5
                                    @warn "Função complexa em $file_path:$start_line ($function_lines linhas)"
                                end
                            end
                        end
                    catch e
                        @warn "Erro analisando $file_path: $e"
                    end
                end
            end

            complexity_ratio = total_functions > 0 ? complex_functions / total_functions : 0.0
            @test complexity_ratio <= 0.2

            println("   ℹ️  Funções analisadas: $total_functions")
            println("   ℹ️  Funções complexas: $complex_functions ($(round(complexity_ratio*100, digits=1))%)")
            println("   ℹ️  Total de linhas de código: $total_lines_of_code")
        end

        @testset "Maintainability Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_maintainability(project_path)
            @test score >= 70.0
            @test score <= 100.0

            println("   ✅ Maintainability Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # VALIDAÇÃO INTEGRADA DO PILAR CLEAN CODE
    # ==========================================================================
    @testset "🎯 Clean Code Pillar Integration Test" begin
        # Avaliação completa do pilar
        # Usar o diretório do projeto principal (um nível acima do diretório test)
        current_dir = pwd()
        project_path = current_dir
        # Se estivermos no diretório test, subir um nível
        if basename(current_dir) == "test"
            project_path = dirname(current_dir)
        end

        clean_code_pillar = Automation.CSGAScoring.evaluate_clean_code_pillar(project_path)

        @test clean_code_pillar.name == "Clean Code"
        @test clean_code_pillar.weight == 0.25
        @test clean_code_pillar.score >= 70.0
        @test clean_code_pillar.score <= 100.0

        # Verificação das métricas componentes
        @test haskey(clean_code_pillar.metrics, "code_organization")
        @test haskey(clean_code_pillar.metrics, "documentation_quality")
        @test haskey(clean_code_pillar.metrics, "code_style")
        @test haskey(clean_code_pillar.metrics, "maintainability")

        println("\n📊 RESUMO CLEAN CODE PILLAR:")
        println("   Score Geral: $(round(clean_code_pillar.score, digits=1))/100")
        println("   Peso no CSGA: $(clean_code_pillar.weight * 100)%")

        if !isempty(clean_code_pillar.recommendations)
            println("\n💡 Recomendações:")
            for rec in clean_code_pillar.recommendations
                println("   • $rec")
            end
        end

        if !isempty(clean_code_pillar.critical_issues)
            println("\n⚠️  Questões Críticas:")
            for issue in clean_code_pillar.critical_issues
                println("   • $issue")
            end
        end
    end

    println("✅ Clean Code Pillar validation completed!")
end
