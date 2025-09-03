"""
Performance Regression Detection
Sistema de detecção de regressão de performance
"""

using BenchmarkTools
using Statistics
using JSON3
using Dates

function establish_baseline()
    println("📏 Establishing Performance Baseline...")

    # Core benchmarks for baseline
    benchmarks = Dict()

    # Math operations baseline
    result1 = @benchmark sum(rand(1000) .^ 2)
    benchmarks["math_ops"] = median(result1.times) / 1e6

    # String processing baseline  
    result2 = @benchmark split(uppercase("test " ^ 100), " ")
    benchmarks["string_ops"] = median(result2.times) / 1e6

    # I/O operations baseline
    result3 = @benchmark begin
        if isfile("Project.toml")
            length(read("Project.toml", String))
        else
            0
        end
    end
    benchmarks["io_ops"] = median(result3.times) / 1e6

    # Save baseline
    baseline_data = Dict(
        "timestamp" => string(now()),
        "julia_version" => string(VERSION),
        "benchmarks" => benchmarks,
    )

    try
        open("benchmarks/baseline.json", "w") do f
            JSON3.pretty(f, baseline_data)
        end
        println("   ✅ Baseline saved to benchmarks/baseline.json")
    catch e
        println("   ⚠️  Could not save baseline: $e")
    end

    for (name, time_ms) in benchmarks
        println("   ✅ $name baseline: $(round(time_ms, digits=3))ms")
    end

    return benchmarks
end

function check_regression(tolerance_percent = 20.0)
    println("🔍 Checking for Performance Regression...")

    # Load baseline if exists
    baseline = nothing
    try
        if isfile("benchmarks/baseline.json")
            baseline_data = JSON3.read("benchmarks/baseline.json", Dict)
            baseline = baseline_data["benchmarks"]
        end
    catch e
        println("   ⚠️  Could not load baseline: $e")
    end

    if baseline === nothing
        println("   ⚠️  No baseline found, establishing new baseline...")
        return establish_baseline()
    end

    # Run current benchmarks
    current = establish_baseline()

    # Compare with baseline
    regressions = []
    improvements = []

    for (name, current_time) in current
        if haskey(baseline, name)
            baseline_time = baseline[name]
            change_percent = ((current_time - baseline_time) / baseline_time) * 100

            if change_percent > tolerance_percent
                push!(regressions, (name, change_percent))
                println("   ❌ REGRESSION in $name: +$(round(change_percent, digits=1))%")
            elseif change_percent < -5.0  # 5% improvement threshold
                push!(improvements, (name, abs(change_percent)))
                println(
                    "   ✅ IMPROVEMENT in $name: +$(round(abs(change_percent), digits=1))%",
                )
            else
                println(
                    "   ✅ $name: within tolerance ($(round(change_percent, digits=1))%)",
                )
            end
        end
    end

    # Summary
    if !isempty(regressions)
        println("   ⚠️  $(length(regressions)) performance regressions detected!")
    else
        println("   ✅ No significant regressions detected")
    end

    return Dict(
        "regressions" => regressions,
        "improvements" => improvements,
        "tolerance_percent" => tolerance_percent,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    check_regression()
end
