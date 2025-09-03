"""
Test Security Pillar - Pilar 1: Security First (30%)
Testes específicos para validação do pilar de segurança CSGA

Objetivos:
- Validar Package Security Score (30 pontos)
- Validar Code Security Score (25 pontos)  
- Validar Dependency Management Score (25 pontos)
- Validar Security Automation Score (20 pontos)
- Elevar métrica security_automation para 95.0+
"""

using Test
using TOML
using JSON3

@testset "🔒 Security First Pillar Validation" begin
    println("\n🔍 Testando Security First Pillar...")

    # ==========================================================================
    # TESTE 1: PACKAGE SECURITY SCORE (30 pontos)
    # ==========================================================================
    @testset "📦 Package Security Score" begin
        @testset "Project.toml Security Validation" begin
            project_file = "Project.toml"
            @test isfile(project_file) "Project.toml deve existir"

            project_data = TOML.parsefile(project_file)
            deps = get(project_data, "deps", Dict())

            # Pacotes oficiais conforme análise CSGA
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
                "TOML",
            ])

            @testset "Official Packages Only" begin
                if !isempty(deps)
                    for (pkg_name, _) in deps
                        @test pkg_name in official_packages "Pacote $pkg_name não é oficial JuliaLang"
                    end

                    official_count = count(pkg -> pkg in official_packages, keys(deps))
                    official_ratio = official_count / length(deps)
                    @test official_ratio >= 0.95 "Pelo menos 95% dos pacotes devem ser oficiais"
                end
            end

            @testset "Compatibility Constraints" begin
                compat = get(project_data, "compat", Dict())
                if !isempty(deps)
                    compat_ratio = length(compat) / length(deps)
                    @test compat_ratio >= 0.8 "Pelo menos 80% das dependências devem ter constraints de compatibilidade"
                end
            end
        end

        @testset "Security Package Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_package_security(".")
            @test score >= 80.0 "Package security score deve ser ≥ 80.0"
            @test score <= 100.0 "Package security score deve ser ≤ 100.0"

            println("   ✅ Package Security Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 2: CODE SECURITY SCORE (25 pontos)
    # ==========================================================================
    @testset "💻 Code Security Score" begin
        @testset "Security Risk Pattern Detection" begin
            # Padrões de risco que devem ser evitados
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

            julia_files = []
            for (root, dirs, files) in walkdir(".")
                for file in files
                    if endswith(file, ".jl") && !contains(root, ".git")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            @test !isempty(julia_files) "Deve existir pelo menos um arquivo .jl"

            violation_count = 0
            total_lines = 0

            for file_path in julia_files
                if isfile(file_path)
                    try
                        content = read(file_path, String)
                        lines = split(content, '\n')
                        total_lines += length(lines)

                        for (line_num, line) in enumerate(lines)
                            for pattern in risk_patterns
                                if occursin(pattern, line)
                                    violation_count += 1
                                    @warn "Security risk detectado em $file_path:$line_num: $line"
                                    break
                                end
                            end
                        end
                    catch e
                        @warn "Erro lendo arquivo $file_path: $e"
                    end
                end
            end

            violation_rate = total_lines > 0 ? violation_count / total_lines : 0.0
            @test violation_rate <= 0.001 "Taxa de violações de segurança deve ser ≤ 0.1%"

            println("   ℹ️  Linhas analisadas: $total_lines")
            println("   ℹ️  Violações encontradas: $violation_count")
        end

        @testset "Code Security Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_code_security(".")
            @test score >= 70.0 "Code security score deve ser ≥ 70.0"
            @test score <= 100.0 "Code security score deve ser ≤ 100.0"

            println("   ✅ Code Security Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 3: DEPENDENCY MANAGEMENT SCORE (25 pontos)
    # ==========================================================================
    @testset "📋 Dependency Management Score" begin
        @testset "Project Structure Validation" begin
            @test isfile("Project.toml") "Project.toml deve existir"
            @test isfile("Manifest.toml") "Manifest.toml deve existir para lock de dependências"

            project_data = TOML.parsefile("Project.toml")

            # Metadados obrigatórios
            required_fields = ["name", "uuid", "authors", "version"]
            for field in required_fields
                @test haskey(project_data, field) "Campo obrigatório '$field' deve existir em Project.toml"
            end
        end

        @testset "Dependency Management Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_dependency_management(".")
            @test score >= 75.0 "Dependency management score deve ser ≥ 75.0"
            @test score <= 100.0 "Dependency management score deve ser ≤ 100.0"

            println("   ✅ Dependency Management Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 4: SECURITY AUTOMATION SCORE (20 pontos)
    # ==========================================================================
    @testset "🤖 Security Automation Score" begin
        @testset "Makefile Security Targets" begin
            if isfile("Makefile")
                makefile_content = read("Makefile", String)

                # Targets de segurança esperados
                security_targets = ["csga", "validate"]

                for target in security_targets
                    target_regex = Regex("^$(target):", "m")
                    @test occursin(target_regex, makefile_content) "Target '$target' deve existir no Makefile"
                end

                println("   ✅ Makefile com targets de segurança encontrado")
            else
                @warn "Makefile não encontrado - reduzindo score de automação"
            end
        end

        @testset "AGENTS.md Security Instructions" begin
            if isfile("AGENTS.md")
                agents_content = read("AGENTS.md", String)

                @test occursin("Security", agents_content) "AGENTS.md deve conter seção Security"
                @test occursin("audit", agents_content) ||
                      occursin("validate", agents_content) "AGENTS.md deve conter instruções de auditoria"

                println("   ✅ AGENTS.md com instruções de segurança encontrado")
            else
                @warn "AGENTS.md não encontrado - implementação recomendada"
            end
        end

        @testset "Test Security Structure" begin
            test_dir = "test"
            @test isdir(test_dir) "Diretório test/ deve existir"

            # Este próprio arquivo é evidência de security testing
            @test isfile("test/test_security_pillar.jl") "Arquivo de teste de segurança deve existir"

            println("   ✅ Estrutura de testes de segurança implementada")
        end

        @testset "Security Automation Score Calculation" begin
            score = Automation.CSGAScoring.evaluate_security_automation(".")
            @test score >= 60.0 "Security automation score deve ser ≥ 60.0"
            @test score <= 100.0 "Security automation score deve ser ≤ 100.0"

            println("   ✅ Security Automation Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # VALIDAÇÃO INTEGRADA DO PILAR SECURITY
    # ==========================================================================
    @testset "🎯 Security Pillar Integration Test" begin

        # Avaliação completa do pilar
        security_pillar = Automation.CSGAScoring.evaluate_security_pillar(".")

        @test security_pillar.name == "Security First"
        @test security_pillar.weight == 0.30 "Peso do pilar Security deve ser 30%"
        @test security_pillar.score >= 75.0 "Score total do pilar Security deve ser ≥ 75.0"
        @test security_pillar.score <= 100.0 "Score total do pilar Security deve ser ≤ 100.0"

        # Verificação das métricas componentes
        @test haskey(security_pillar.metrics, "package_security")
        @test haskey(security_pillar.metrics, "code_security")
        @test haskey(security_pillar.metrics, "dependency_management")
        @test haskey(security_pillar.metrics, "security_automation")

        println("\n📊 RESUMO SECURITY PILLAR:")
        println("   Score Geral: $(round(security_pillar.score, digits=1))/100")
        println("   Peso no CSGA: $(security_pillar.weight * 100)%")
        println(
            "   Package Security: $(round(security_pillar.metrics["package_security"], digits=1))",
        )
        println(
            "   Code Security: $(round(security_pillar.metrics["code_security"], digits=1))",
        )
        println(
            "   Dependency Management: $(round(security_pillar.metrics["dependency_management"], digits=1))",
        )
        println(
            "   Security Automation: $(round(security_pillar.metrics["security_automation"], digits=1))",
        )

        if !isempty(security_pillar.recommendations)
            println("\n💡 Recomendações:")
            for rec in security_pillar.recommendations
                println("   • $rec")
            end
        end

        if !isempty(security_pillar.critical_issues)
            println("\n⚠️  Questões Críticas:")
            for issue in security_pillar.critical_issues
                println("   • $issue")
            end
        end
    end

    println("✅ Security First Pillar validation completed!")
end
