# Demonstração dos Pacotes Oficiais JuliaLang
# Este exemplo showcases todos os pacotes oficiais instalados

println("🎯 === DEMO PACOTES OFICIAIS JULIALANG ===\n")

# 1. CORE JULIA
using Statistics, Test
println("📊 Statistics:")
data = randn(1000)
println("   Mean: $(round(mean(data), digits=3))")
println("   Std:  $(round(std(data), digits=3))")

# 2. JULIAATA ECOSYSTEM
using DataFrames, CSV, StatsBase, Distributions
println("\n📈 DataFrames & Stats:")
df = DataFrame(
    x = randn(100),
    y = rand(Normal(0, 1), 100),
    category = rand(["A", "B", "C"], 100),
)
println("   DataFrame criado: $(size(df)) com $(ncol(df)) colunas")
println("   Correlação x,y: $(round(cor(df.x, df.y), digits=3))")

# 3. JULIAIO ECOSYSTEM  
using FileIO, JLD2, JSON3, Dates
println("\n💾 File I/O:")
temp_data = Dict("test" => randn(10), "timestamp" => now())
jldsave("temp_test.jld2", test = randn(10), timestamp = now())
println("   Dados salvos em JLD2 (formato nativo Julia)")

json_str = JSON3.write(Dict("status" => "ok", "count" => 42))
println("   JSON gerado: $json_str")

# 4. JULIAMATH ECOSYSTEM
using SpecialFunctions, StaticArrays
println("\n🔢 Julia Math:")
println("   Γ(5) = $(gamma(5))")
vec_static = SVector(1.0, 2.0, 3.0)
println("   StaticArray criado: $vec_static")

# 5. JULIAPARALLEL ECOSYSTEM
using ThreadsX
println("\n⚡ Parallel Processing:")
result = ThreadsX.sum(1:1000000)
println("   Soma paralela 1:1M = $result")

# 6. WEB ECOSYSTEM
using HTTP
println("\n🌐 HTTP Client:")
try
    response = HTTP.get("https://httpbin.org/json", readtimeout = 5)
    println("   HTTP Status: $(response.status)")
catch e
    println("   HTTP test skipped (sem internet)")
end

# 7. DEVELOPMENT TOOLS
using BenchmarkTools
println("\n🛠️ Development:")
benchmark_result = @benchmark sum(randn(1000))
println(
    "   Benchmark sum(randn(1000)): $(round(mean(benchmark_result.times)/1000, digits=2))μs",
)

# 8. CLEANUP
rm("temp_test.jld2", force = true)

println("\n✅ Todos os pacotes oficiais funcionando perfeitamente!")
