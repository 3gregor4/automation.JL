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
            # Estrutura básica esperada
            expected_dirs = ["src", "test", "docs"]
            for dir in expected_dirs
                @test isdir(dir) "Diretório '$dir' deve existir"
            end

            expected_files = ["Project.toml", "README.md", "Makefile"]
            for file in expected_files
                @test isfile(file) "Arquivo '$file' deve existir"
            end

            println("   ✅ Estrutura de projeto validada")
        end

        @testset "Source Code Organization" begin
            src_dir = "src"
            if isdir(src_dir)
                src_files = readdir(src_dir)
                julia_files = filter(f -> endswith(f, ".jl"), src_files)

                @test !isempty(julia_files) "Diretório src/ deve conter arquivos .jl"
                @test "Automation.jl" in julia_files "Arquivo principal Automation.jl deve existir"

                # Verificar modularidade do código
                module_count = length(julia_files)
                @test module_count >= 3 "Deve ter pelo menos 3 módulos para boa organização"

                println("   ✅ Organização do código fonte: $module_count módulos")
            end
        end

        @testset "Documentation Structure" begin
            docs_dir = "docs"
            if isdir(docs_dir)
                docs_files = readdir(docs_dir)
                @test !isempty(docs_files) "Diretório docs/ deve conter arquivos"

                # Procurar por make.jl para geração automática
                has_makejl = any(f -> f == "make.jl", docs_files)
                if has_makejl
                    println("   ✅ Sistema de documentação automática encontrado")
                end
            end
        end

        @testset "Code Organization Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_code_organization(".")
            @test score >= 70.0 "Code organization score deve ser ≥ 70.0"
            @test score <= 100.0 "Code organization score deve ser ≤ 100.0"

            println("   ✅ Code Organization Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 2: DOCUMENTATION QUALITY SCORE (25 pontos)
    # ==========================================================================
    @testset "📚 Documentation Quality Score" begin
        @testset "README.md Quality" begin
            readme_file = "README.md"
            @test isfile(readme_file) "README.md deve existir"

            if isfile(readme_file)
                readme_content = read(readme_file, String)
                readme_lines = split(readme_content, '\n')

                @test length(readme_lines) >= 10 "README.md deve ter pelo menos 10 linhas"
                @test occursin("# ", readme_content) "README.md deve ter título principal"
                @test occursin("## ", readme_content) "README.md deve ter seções"

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
            julia_files = []
            for (root, dirs, files) in walkdir("src")
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
                            if occursin(r"^function\\s+\\w+", line) ||
                               occursin(r"^\\w+\\([^)]*\\)\\s*=", line)
                                total_functions += 1

                                # Verificar se há docstring antes da função
                                if i > 1 && contains(lines[i - 1], "\"\"\"")
                                    documented_functions += 1
                                elseif i > 2 && contains(lines[i - 2], "\"\"\"")
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
                @test documentation_ratio >= 0.6 "Pelo menos 60% das funções devem ter documentação"

                println("   ℹ️  Funções encontradas: $total_functions")
                println(
                    "   ℹ️  Funções documentadas: $documented_functions ($(round(documentation_ratio*100, digits=1))%)",
                )
            end
        end

        @testset "AGENTS.md Documentation" begin
            agents_file = "AGENTS.md"
            if isfile(agents_file)
                agents_content = read(agents_file, String)
                agents_lines = split(agents_content, '\n')

                @test length(agents_lines) >= 50 "AGENTS.md deve ser substancial (≥50 linhas)"
                @test occursin("# ", agents_content) "AGENTS.md deve ter estrutura de seções"

                # Verificar pilares CSGA
                csga_pillars = ["Security", "Clean", "Green", "Automation"]
                pillar_coverage = 0

                for pillar in csga_pillars
                    if occursin(pillar, agents_content)
                        pillar_coverage += 1
                    end
                end

                @test pillar_coverage >= 3 "AGENTS.md deve cobrir pelo menos 3 dos 4 pilares CSGA"

                println("   ✅ AGENTS.md abrangente: $(pillar_coverage)/4 pilares cobertos")
            end
        end

        @testset "Documentation Quality Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_documentation_quality(".")
            @test score >= 60.0 "Documentation quality score deve ser ≥ 60.0"
            @test score <= 100.0 "Documentation quality score deve ser ≤ 100.0"

            println("   ✅ Documentation Quality Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 3: CODE STYLE SCORE (25 pontos)
    # ==========================================================================
    @testset "🎨 Code Style Score" begin
        @testset "Julia Style Guidelines" begin
            julia_files = []
            for (root, dirs, files) in walkdir("src")
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            style_violations = 0
            total_lines = 0

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)
                        lines = split(content, '\n')
                        total_lines += length(lines)

                        for line in lines
                            # Verificações básicas de estilo
                            if length(line) > 120
                                style_violations += 1  # Linha muito longa
                            end

                            if occursin(r"\\t", line)
                                style_violations += 1  # Uso de tabs ao invés de espaços
                            end

                            if occursin(r"\\s+$", line) && !isempty(strip(line))
                                style_violations += 1  # Espaços em branco no final
                            end
                        end
                    catch e
                        @warn "Erro analisando estilo em $file_path: $e"
                    end
                end
            end

            if total_lines > 0
                violation_rate = style_violations / total_lines
                @test violation_rate <= 0.05 "Taxa de violações de estilo deve ser ≤ 5%"

                println("   ℹ️  Linhas analisadas: $total_lines")
                println(
                    "   ℹ️  Violações de estilo: $style_violations ($(round(violation_rate*100, digits=2))%)",
                )
            end
        end

        @testset "Naming Conventions" begin
            # Verificar se nomes seguem convenções Julia
            julia_files = []
            for (root, dirs, files) in walkdir("src")
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            naming_violations = 0

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)

                        # Verificar nomes de função (snake_case recomendado)
                        function_matches = eachmatch(r"function\\s+(\\w+)", content)
                        for match in function_matches
                            func_name = match.captures[1]
                            if !occursin(r"^[a-z][a-z0-9_]*$", func_name) &&
                               func_name != "CSGAScore"
                                naming_violations += 1
                            end
                        end

                        # Verificar nomes de módulo (PascalCase recomendado)
                        module_matches = eachmatch(r"module\\s+(\\w+)", content)
                        for match in module_matches
                            module_name = match.captures[1]
                            if !occursin(r"^[A-Z][a-zA-Z0-9]*$", module_name)
                                naming_violations += 1
                            end
                        end
                    catch e
                        @warn "Erro verificando nomes em $file_path: $e"
                    end
                end
            end

            @test naming_violations <= 2 "Deve ter no máximo 2 violações de convenção de nomes"

            println("   ℹ️  Violações de nomenclatura: $naming_violations")
        end

        @testset "Code Style Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_code_style(".")
            @test score >= 70.0 "Code style score deve ser ≥ 70.0"
            @test score <= 100.0 "Code style score deve ser ≤ 100.0"

            println("   ✅ Code Style Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 4: MAINTAINABILITY SCORE (20 pontos)
    # ==========================================================================
    @testset "🔧 Maintainability Score" begin
        @testset "Code Complexity Analysis" begin
            julia_files = []
            for (root, dirs, files) in walkdir("src")
                for file in files
                    if endswith(file, ".jl")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            total_functions = 0
            complex_functions = 0

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)

                        # Análise básica de complexidade (contar condicionais e loops)
                        function_blocks =
                            split(content, r"^function\\s+", keepempty = false)

                        for block in function_blocks[2:end]  # Pular primeiro bloco antes de qualquer função
                            total_functions += 1

                            # Contar estruturas que aumentam complexidade
                            complexity_markers = [
                                length(collect(eachmatch(r"\\bif\\b", block))),
                                length(collect(eachmatch(r"\\bfor\\b", block))),
                                length(collect(eachmatch(r"\\bwhile\\b", block))),
                                length(collect(eachmatch(r"\\btry\\b", block))),
                                length(collect(eachmatch(r"\\&&\\b", block))),
                                length(collect(eachmatch(r"\\|\\|\\b", block))),
                            ]

                            complexity_score = sum(complexity_markers)
                            if complexity_score > 10
                                complex_functions += 1
                            end
                        end
                    catch e
                        @warn "Erro analisando complexidade em $file_path: $e"
                    end
                end
            end

            if total_functions > 0
                complexity_ratio = complex_functions / total_functions
                @test complexity_ratio <= 0.2 "No máximo 20% das funções devem ser complexas"

                println("   ℹ️  Funções analisadas: $total_functions")
                println(
                    "   ℹ️  Funções complexas: $complex_functions ($(round(complexity_ratio*100, digits=1))%)",
                )
            end
        end

        @testset "Module Dependencies" begin
            # Verificar dependências entre módulos
            src_files = readdir("src")
            julia_files = filter(f -> endswith(f, ".jl"), src_files)

            @test length(julia_files) >= 3 "Deve ter pelo menos 3 módulos para modularidade"
            @test length(julia_files) <= 15 "Não deve ter muitos módulos (máximo 15)"

            # Verificar se Automation.jl é o ponto de entrada
            main_file = "src/Automation.jl"
            @test isfile(main_file) "Arquivo principal deve existir"

            if isfile(main_file)
                content = read(main_file, String)
                include_count = length(collect(eachmatch(r"include\\(", content)))

                # Boa prática: arquivo principal deve incluir outros módulos
                @test include_count >= 1 "Arquivo principal deve incluir outros módulos"
                @test include_count <= 10 "Não deve incluir muitos arquivos diretamente"

                println(
                    "   ✅ Modularidade: $(length(julia_files)) módulos, $include_count includes",
                )
            end
        end

        @testset "Makefile Automation" begin
            makefile_path = "Makefile"
            if isfile(makefile_path)
                makefile_content = read(makefile_path, String)

                # Targets importantes para manutenibilidade
                maintenance_targets = ["test", "clean", "format", "docs"]
                found_targets = 0

                for target in maintenance_targets
                    if occursin(Regex("^$(target):", "m"), makefile_content)
                        found_targets += 1
                    end
                end

                @test found_targets >= 3 "Makefile deve ter pelo menos 3 targets de manutenção"

                println(
                    "   ✅ Targets de manutenção: $found_targets/$(length(maintenance_targets))",
                )
            end
        end

        @testset "Maintainability Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_maintainability(".")
            @test score >= 65.0 "Maintainability score deve ser ≥ 65.0"
            @test score <= 100.0 "Maintainability score deve ser ≤ 100.0"

            println("   ✅ Maintainability Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # VALIDAÇÃO INTEGRADA DO PILAR CLEAN CODE
    # ==========================================================================
    @testset "🎯 Clean Code Pillar Integration Test" begin

        # Avaliação completa do pilar
        clean_code_pillar = Automation.CSGAScoring.evaluate_clean_code_pillar(".")

        @test clean_code_pillar.name == "Clean Code"
        @test clean_code_pillar.weight == 0.25 "Peso do pilar Clean Code deve ser 25%"
        @test clean_code_pillar.score >= 70.0 "Score total do pilar Clean Code deve ser ≥ 70.0"
        @test clean_code_pillar.score <= 100.0 "Score total do pilar Clean Code deve ser ≤ 100.0"

        # Verificação das métricas componentes
        @test haskey(clean_code_pillar.metrics, "code_organization")
        @test haskey(clean_code_pillar.metrics, "documentation_quality")
        @test haskey(clean_code_pillar.metrics, "code_style")
        @test haskey(clean_code_pillar.metrics, "maintainability")

        println("\n📊 RESUMO CLEAN CODE PILLAR:")
        println("   Score Geral: $(round(clean_code_pillar.score, digits=1))/100")
        println("   Peso no CSGA: $(clean_code_pillar.weight * 100)%")
        println(
            "   Code Organization: $(round(clean_code_pillar.metrics["code_organization"], digits=1))",
        )
        println(
            "   Documentation Quality: $(round(clean_code_pillar.metrics["documentation_quality"], digits=1))",
        )
        println(
            "   Code Style: $(round(clean_code_pillar.metrics["code_style"], digits=1))",
        )
        println(
            "   Maintainability: $(round(clean_code_pillar.metrics["maintainability"], digits=1))",
        )

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
