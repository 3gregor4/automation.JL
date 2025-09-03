"""
Core Functions Benchmarks
Benchmarks das funções principais do projeto
"""

using BenchmarkTools
using Statistics

function benchmark_julia_core()
    println("⚡ Benchmarking Julia Core Functions...")

    results = []

    # Vector operations
    result1 = @benchmark begin
        v = rand(10000)
        sum(v .* v)
    end
    push!(results, ("vector_ops", median(result1.times)/1e6))

    # String operations  
    result2 = @benchmark begin
        s = "Julia Performance Testing " ^ 50
        split(uppercase(s), " ")
    end
    push!(results, ("string_ops", median(result2.times)/1e6))

    # File I/O
    result3 = @benchmark begin
        if isfile("Project.toml")
            content = read("Project.toml", String)
            length(split(content, '\n'))
        else
            0
        end
    end
    push!(results, ("file_io", median(result3.times)/1e6))

    for (name, time_ms) in results
        println("   ✅ $name: $(round(time_ms, digits=3))ms")
    end

    return results
end

if abspath(PROGRAM_FILE) == @__FILE__
    benchmark_julia_core()
end
