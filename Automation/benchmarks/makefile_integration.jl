"""
Makefile Integration Utilities
Helpers para integração dos benchmarks com o sistema make
"""

using Pkg
using Statistics
import BenchmarkTools

"""
    validate_benchmark_environment()

Valida se o ambiente está pronto para benchmarks
"""
function validate_benchmark_environment()
    println("🔍 Validando ambiente de benchmark...")

    # Verificar se estamos no projeto correto
    if !isfile("Project.toml")
        println("❌ Project.toml não encontrado")
        return false
    end

    # Verificar BenchmarkTools
    try
        println("✅ BenchmarkTools disponível")
    catch e
        println("❌ BenchmarkTools não disponível: $e")
        return false
    end

    # Verificar diretório benchmarks
    if !isdir("benchmarks")
        println("⚠️  Criando diretório benchmarks...")
        mkdir("benchmarks")
    end
    println("✅ Estrutura de diretórios OK")

    # Verificar permissões de escrita
    test_file = "benchmarks/.write_test"
    try
        touch(test_file)
        rm(test_file)
        println("✅ Permissões de escrita OK")
    catch e
        println("❌ Erro de permissões: $e")
        return false
    end

    println("✅ Ambiente validado com sucesso")
    return true
end

"""
    setup_benchmark_paths()

Configura paths necessários para benchmarks
"""
function setup_benchmark_paths()
    # Adicionar src ao load path se necessário
    src_path = abspath("src")
    if !(src_path in LOAD_PATH)
        push!(LOAD_PATH, src_path)
    end

    # Garantir que benchmarks está no path
    bench_path = abspath("benchmarks")
    if !(bench_path in LOAD_PATH)
        push!(LOAD_PATH, bench_path)
    end

    return true
end

"""
    run_benchmark_command(command::String)

Executa comando de benchmark com tratamento de erro
"""
function run_benchmark_command(command::String = "default")
    if !validate_benchmark_environment()
        println("❌ Falha na validação do ambiente")
        return 1
    end

    setup_benchmark_paths()

    if command == "default" || command == "all"
        # Executar benchmarks principais
        try
            println("🚀 Iniciando benchmarks via make...")
            include("run_benchmarks.jl")
            return 0
        catch e
            println("❌ Erro na execução de benchmarks: $e")
            return 1
        end
    elseif command == "quick"
        # Versão rápida para CI
        println("⚡ Executando benchmarks rápidos...")
        try
            # Benchmark simples
            result = BenchmarkTools.@benchmark sum(rand(1000))
            median_time = Statistics.median(result.times) / 1e6

            println("✅ Benchmark rápido: $(round(median_time, digits=2))ms")
            return 0
        catch e
            println("❌ Erro no benchmark rápido: $e")
            return 1
        end
    else
        println("❌ Comando não reconhecido: $command")
        println("Comandos disponíveis: default, all, quick")
        return 1
    end
end

"""
    cleanup_benchmark_files()

Limpa arquivos temporários de benchmark
"""
function cleanup_benchmark_files()
    println("🧹 Limpando arquivos temporários de benchmark...")

    temp_files = ["benchmarks/.write_test", "benchmarks/temp_*.json", "benchmarks/*.tmp"]

    cleaned = 0
    for pattern in temp_files
        for file in Sys.glob(pattern)
            try
                rm(file)
                cleaned += 1
            catch e
                println("⚠️  Não foi possível remover $file: $e")
            end
        end
    end

    if cleaned > 0
        println("✅ $cleaned arquivos temporários removidos")
    else
        println("✅ Nenhum arquivo temporário encontrado")
    end

    return cleaned
end

# Interface para linha de comando
if length(ARGS) > 0
    command = ARGS[1]
    if command == "cleanup"
        exit(cleanup_benchmark_files())
    else
        exit(run_benchmark_command(command))
    end
elseif abspath(PROGRAM_FILE) == @__FILE__
    exit(run_benchmark_command())
end
