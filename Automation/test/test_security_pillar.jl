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
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            project_file = joinpath(project_path, "Project.toml")
            @test isfile(project_file) == true

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
                "JuliaFormatter",  # Adicionando JuliaFormatter à lista de pacotes oficiais
            ])

            @testset "Official Packages Only" begin
                if !isempty(deps)
                    for (pkg_name, _) in deps
                        @test pkg_name in official_packages
                    end

                    official_count = count(pkg -> pkg in official_packages, keys(deps))
                    official_ratio = official_count / length(deps)
                    @test official_ratio >= 0.95
                end
            end

            @testset "Compatibility Constraints" begin
                compat = get(project_data, "compat", Dict())
                if !isempty(deps)
                    compat_ratio = length(compat) / length(deps)
                    @test compat_ratio >= 0.8
                end
            end
        end

        @testset "Security Package Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_package_security(project_path)
            @test score >= 80.0
            @test score <= 100.0

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

            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            julia_files = []
            for (root, dirs, files) in walkdir(project_path)
                for file in files
                    if endswith(file, ".jl") && !contains(root, ".git")
                        push!(julia_files, joinpath(root, file))
                    end
                end
            end

            @test !isempty(julia_files)

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
            @test violation_rate <= 0.001

            println("   ℹ️  Linhas analisadas: $total_lines")
            println("   ℹ️  Violações encontradas: $violation_count")
        end

        @testset "Code Security Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_code_security(project_path)
            @test score >= 70.0
            @test score <= 100.0

            println("   ✅ Code Security Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 3: DEPENDENCY MANAGEMENT SCORE (25 pontos)
    # ==========================================================================
    @testset "📋 Dependency Management Score" begin
        @testset "Project Structure Validation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            @test isfile(joinpath(project_path, "Project.toml"))
            @test isfile(joinpath(project_path, "Manifest.toml"))

            project_data = TOML.parsefile(joinpath(project_path, "Project.toml"))

            # Metadados obrigatórios
            required_fields = ["name", "uuid", "authors", "version"]
            for field in required_fields
                @test haskey(project_data, field)
            end
        end

        @testset "Dependency Management Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_dependency_management(project_path)
            @test score >= 75.0
            @test score <= 100.0

            println("   ✅ Dependency Management Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # TESTE 4: SECURITY AUTOMATION SCORE (20 pontos)
    # ==========================================================================
    @testset "🤖 Security Automation Score" begin
        @testset "Makefile Security Targets" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            makefile_path = joinpath(project_path, "Makefile")
            if isfile(makefile_path)
                makefile_content = read(makefile_path, String)

                # Targets de segurança esperados
                security_targets = ["csga", "validate"]

                found_targets = 0
                lines = split(makefile_content, "\n")
                for target in security_targets
                    pattern = string("^", target, ":")
                    for line in lines
                        if occursin(Regex(pattern), line)
                            found_targets += 1
                            println("   ✅ Target '$target' encontrado")
                            break
                        end
                    end
                end

                target_coverage = found_targets / length(security_targets)
                @test target_coverage >= 0.5

                println("   📊 Coverage de targets de segurança: $(round(target_coverage*100, digits=1))%")
            end
        end

        @testset "Security Automation Score Calculation" begin
            # Usar o diretório do projeto principal (um nível acima do diretório test)
            current_dir = pwd()
            project_path = current_dir
            # Se estivermos no diretório test, subir um nível
            if basename(current_dir) == "test"
                project_path = dirname(current_dir)
            end

            score = Automation.CSGAScoring.evaluate_security_automation(project_path)
            @test score >= 80.0
            @test score <= 100.0

            println("   ✅ Security Automation Score: $(round(score, digits=1))/100")
        end
    end

    # ==========================================================================
    # VALIDAÇÃO INTEGRADA DO PILAR SECURITY
    # ==========================================================================
    @testset "🎯 Security Pillar Integration Test" begin
        # Avaliação completa do pilar
        # Usar o diretório do projeto principal (um nível acima do diretório test)
        current_dir = pwd()
        project_path = current_dir
        # Se estivermos no diretório test, subir um nível
        if basename(current_dir) == "test"
            project_path = dirname(current_dir)
        end

        security_pillar = Automation.CSGAScoring.evaluate_security_pillar(project_path)

        @test security_pillar.name == "Security First"
        @test security_pillar.weight == 0.30
        @test security_pillar.score >= 80.0
        @test security_pillar.score <= 100.0

        # Verificação das métricas componentes
        @test haskey(security_pillar.metrics, "package_security")
        @test haskey(security_pillar.metrics, "code_security")
        @test haskey(security_pillar.metrics, "dependency_management")
        @test haskey(security_pillar.metrics, "security_automation")

        println("\n📊 RESUMO SECURITY PILLAR:")
        println("   Score Geral: $(round(security_pillar.score, digits=1))/100")
        println("   Peso no CSGA: $(security_pillar.weight * 100)%")

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
