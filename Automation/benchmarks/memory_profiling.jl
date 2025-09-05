"""
Memory Profiling Utilities
Análise de uso de memória e garbage collection
"""

using BenchmarkTools
using Statistics

function profile_memory_usage()
    println("🧠 Memory Profiling...")

    # Remover GC forçado para melhorar performance
    # GC.gc()
    initial_memory = Base.gc_live_bytes()

    # Test memory allocation patterns
    result = @benchmark begin
        # Allocate and deallocate
        data = Vector{Float64}(undef, 10000)
        data .= rand(10000)
        sum(data)
    end

    final_memory = Base.gc_live_bytes()
    memory_diff = final_memory - initial_memory

    println("   ✅ Memory alloc test: $(round(median(result.times)/1e6, digits=3))ms")
    println("   ✅ Memory usage: $(result.memory) bytes allocated")
    println("   ✅ GC allocs: $(result.allocs)")

    return Dict(
        "median_time_ms" => median(result.times)/1e6,
        "memory_bytes" => result.memory,
        "allocs" => result.allocs,
        "memory_diff" => memory_diff,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    profile_memory_usage()
end
