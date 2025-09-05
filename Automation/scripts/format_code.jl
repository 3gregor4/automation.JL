"""
Format Code - Automatização de Formatação Julia
Script de formatação batch para Quality Automation

Funcionalidades:
- Formatação automática de todos os arquivos .jl
- Verificação de estilo de código
- Relatório de compliance de qualidade
- Integração com Makefile e git hooks
"""

using Pkg
using JuliaFormatter

export format_project, check_formatting, generate_quality_report
export format_file, batch_format, validate_style

# =============================================================================
# FORMATAÇÃO AUTOMÁTICA
# =============================================================================

"""
    format_project(project_path::String = "."; check_only::Bool = false)

Formata todo o projeto Julia ou verifica formatação
"""
function format_project(project_path::String = "."; check_only::Bool = false)
    println("🔧 Julia Code Formatter - Quality Automation")
    println("="^50)

    # Configuração de formatação
    format_options = (
        indent = 4,
        margin = 92,
        always_for_in = true,
        whitespace_typedefs = true,
        whitespace_ops_in_indices = true,
        remove_extra_newlines = true,
        import_to_using = false,
        pipe_to_function_call = false,
        short_to_long_function_def = false,
        always_use_return = false,
        whitespace_in_kwargs = true,
        annotate_untyped_fields_with_any = false,
        format_docstrings = true,
        align_struct_field = true,
        align_assignment = true,
        align_conditional = true,
        normalize_line_endings = "unix",
    )

    # Encontrar todos os arquivos .jl
    julia_files = find_julia_files(project_path)

    if isempty(julia_files)
        println("❌ Nenhum arquivo .jl encontrado em $project_path")
        return false
    end

    println("📁 Encontrados $(length(julia_files)) arquivos Julia")

    # Processar arquivos
    processed_files = 0
    modified_files = 0
    errors = String[]

    for file in julia_files
        try
            if check_only
                # Verificar se está formatado
                is_formatted =
                    JuliaFormatter.format(file; format_options..., overwrite = false)
                if !is_formatted
                    println("❌ Não formatado: $file")
                    modified_files += 1
                else
                    println("✅ Formatado: $file")
                end
            else
                # Formatar arquivo
                was_modified =
                    JuliaFormatter.format(file; format_options..., overwrite = true)
                if was_modified
                    println("🔧 Formatado: $file")
                    modified_files += 1
                else
                    println("✅ Já formatado: $file")
                end
            end
            processed_files += 1

        catch e
            error_msg = "Erro processando $file: $e"
            push!(errors, error_msg)
            println("❌ $error_msg")
        end
    end

    # Relatório final
    println("\n📊 RELATÓRIO DE FORMATAÇÃO:")
    println("   Arquivos processados: $processed_files")
    println("   Arquivos $(check_only ? "não formatados" : "modificados"): $modified_files")
    println("   Erros: $(length(errors))")

    if !isempty(errors)
        println("\n❌ ERROS ENCONTRADOS:")
        for error in errors
            println("   • $error")
        end
    end

    # Status de sucesso
    success = length(errors) == 0 && (check_only ? modified_files == 0 : true)

    if success
        println("\n✅ $(check_only ? "VERIFICAÇÃO" : "FORMATAÇÃO") CONCLUÍDA COM SUCESSO!")
    else
        println("\n❌ $(check_only ? "VERIFICAÇÃO" : "FORMATAÇÃO") FALHOU!")
    end

    return success
end

"""
    find_julia_files(path::String) -> Vector{String}

Encontra recursivamente todos os arquivos .jl no diretório
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

"""
    check_formatting(project_path::String = ".") -> Bool

Verifica se todo o projeto está formatado corretamente
"""
function check_formatting(project_path::String = ".")
    return format_project(project_path; check_only = true)
end

"""
    format_file(file_path::String) -> Bool

Formata um arquivo específico
"""
function format_file(file_path::String)
    if !isfile(file_path)
        println("❌ Arquivo não encontrado: $file_path")
        return false
    end

    if !endswith(file_path, ".jl")
        println("❌ Não é um arquivo Julia: $file_path")
        return false
    end

    try
        was_modified = JuliaFormatter.format(file_path; overwrite = true)
        if was_modified
            println("🔧 Arquivo formatado: $file_path")
        else
            println("✅ Arquivo já estava formatado: $file_path")
        end
        return true
    catch e
        println("❌ Erro formatando $file_path: $e")
        return false
    end
end

"""
    batch_format(files::Vector{String}) -> Int

Formata múltiplos arquivos e retorna número de sucessos
"""
function batch_format(files::Vector{String})
    success_count = 0

    for file in files
        if format_file(file)
            success_count += 1
        end
    end

    println("📊 Formatação batch: $success_count/$(length(files)) sucessos")
    return success_count
end

"""
    validate_style(project_path::String = ".") -> Dict{String, Any}

Valida estilo de código e gera métricas detalhadas
"""
function validate_style(project_path::String = ".")
    println("📐 Validação de Estilo Julia - Quality Automation")
    println("=" * 45)

    julia_files = find_julia_files(project_path)

    metrics = Dict{String, Any}(
        "total_files" => length(julia_files),
        "formatted_files" => 0,
        "unformatted_files" => 0,
        "line_count" => 0,
        "formatting_score" => 0.0,
        "issues" => String[],
    )

    for file in julia_files
        try
            # Contar linhas
            lines = readlines(file)
            metrics["line_count"] += length(lines)

            # Verificar formatação
            is_formatted = JuliaFormatter.format(file; overwrite = false)
            if is_formatted
                metrics["formatted_files"] += 1
            else
                metrics["unformatted_files"] += 1
                push!(metrics["issues"], "Arquivo não formatado: $file")
            end

            # Verificações adicionais de estilo
            content = Automation.safe_file_read(file)

            # Verificar linha muito longa (>100 chars)
            for (i, line) in enumerate(lines)
                if length(line) > 100
                    push!(
                        metrics["issues"],
                        "$file:$i - Linha muito longa ($(length(line)) chars)",
                    )
                end
            end

            # Verificar trailing whitespace
            if occursin(r"[ \t]+$"m, content)
                push!(metrics["issues"], "$file - Contém trailing whitespace")
            end

            # Verificar tabs vs spaces
            if occursin("\t", content)
                push!(metrics["issues"], "$file - Contém tabs (use espaços)")
            end

        catch e
            push!(metrics["issues"], "Erro analisando $file: $e")
        end
    end

    # Calcular score de formatação
    if metrics["total_files"] > 0
        metrics["formatting_score"] =
            (metrics["formatted_files"] / metrics["total_files"]) * 100
    end

    return metrics
end

"""
    generate_quality_report(project_path::String = ".") -> String

Gera relatório completo de qualidade de código
"""
function generate_quality_report(project_path::String = ".")
    println("📋 Relatório de Qualidade de Código")
    println("=" * 35)

    # Validar estilo
    style_metrics = validate_style(project_path)

    # Criar relatório
    report = """
# Relatório de Qualidade de Código Julia
## Gerado em: $(now())
## Projeto: $(basename(abspath(project_path)))

### 📊 Métricas de Formatação
- **Total de arquivos Julia**: $(style_metrics["total_files"])
- **Arquivos formatados**: $(style_metrics["formatted_files"])
- **Arquivos não formatados**: $(style_metrics["unformatted_files"])
- **Total de linhas**: $(style_metrics["line_count"])
- **Score de formatação**: $(round(style_metrics["formatting_score"], digits=1))/100

### 🔍 Questões Identificadas
"""

    if isempty(style_metrics["issues"])
        report *= "✅ **Nenhuma questão de qualidade identificada!**\n"
    else
        report *= "❌ **$(length(style_metrics["issues"])) questões encontradas:**\n\n"
        for issue in style_metrics["issues"]
            report *= "- $issue\n"
        end
    end

    report *= """

### 🎯 Recomendações
1. Execute `julia scripts/format_code.jl` para formatação automática
2. Configure formatação automática no editor (VSCode)
3. Use git hooks para verificação pré-commit
4. Mantenha linhas ≤ 92 caracteres conforme padrão Julia

### 📈 Status de Qualidade
"""

    if style_metrics["formatting_score"] >= 95
        report *= "🟢 **EXCELENTE** - Código bem formatado e organizado\n"
    elseif style_metrics["formatting_score"] >= 80
        report *= "🟡 **BOM** - Maioria do código formatado, pequenos ajustes necessários\n"
    else
        report *= "🔴 **REQUER ATENÇÃO** - Formatação inconsistente, execute formatação automática\n"
    end

    # Salvar relatório
    report_file = joinpath(project_path, "quality_report.md")
    try
        write(report_file, report)
        println("📄 Relatório salvo em: $report_file")
    catch e
        println("❌ Erro salvando relatório: $e")
    end

    # Exibir resumo
    println("\n📊 RESUMO DO RELATÓRIO:")
    println(
        "   Score de formatação: $(round(style_metrics["formatting_score"], digits=1))/100",
    )
    println("   Questões identificadas: $(length(style_metrics["issues"]))")
    println(
        "   Status: $(style_metrics["formatting_score"] >= 95 ? "EXCELENTE" :
                    style_metrics["formatting_score"] >= 80 ? "BOM" : "REQUER ATENÇÃO")",
    )

    return report
end

# =============================================================================
# FUNÇÃO PRINCIPAL - CLI
# =============================================================================

"""
Função principal para execução via linha de comando
"""
function main()
    if length(ARGS) == 0
        println("📋 Julia Format Code - Quality Automation")
        println("Uso:")
        println("  julia scripts/format_code.jl format     # Formatar projeto")
        println("  julia scripts/format_code.jl check      # Verificar formatação")
        println("  julia scripts/format_code.jl report     # Gerar relatório")
        println("  julia scripts/format_code.jl file <path> # Formatar arquivo específico")
        return
    end

    command = ARGS[1]

    if command == "format"
        success = format_project(".")
        exit(success ? 0 : 1)
    elseif command == "check"
        success = check_formatting(".")
        exit(success ? 0 : 1)
    elseif command == "report"
        generate_quality_report(".")
        exit(0)
    elseif command == "file" && length(ARGS) >= 2
        file_path = ARGS[2]
        success = format_file(file_path)
        exit(success ? 0 : 1)
    else
        println("❌ Comando desconhecido: $command")
        exit(1)
    end
end

# Executar se script for chamado diretamente
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
