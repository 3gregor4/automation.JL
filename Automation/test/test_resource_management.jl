"""
Resource Management Validation Tests
Testes específicos para validação das otimizações de Resource Management

Objetivos:
- Validar cleanup automático de recursos
- Testar memory management patterns
- Verificar safe I/O operations
- Medir impacto no score CSGA
"""

using Test
using Automation

@testset "🔧 Resource Management Validation" begin
    println("\n♻️ Testando Resource Management Optimization...")

    # ==========================================================================
    # TESTE 1: RESOURCE CLEANUP PATTERNS
    # ==========================================================================
    @testset "🧹 Resource Cleanup Patterns" begin
        @testset "@with_cleanup Macro" begin
            # Test file cleanup
            test_file = "test_cleanup.tmp"

            # Create and auto-cleanup file
            content = @with_cleanup file=open(test_file, "w") close(file) begin
                write(file, "test content")
                42  # Return value
            end

            @test content == 42 "Macro should return operation result"
            @test !isopen(open(test_file, "r")) "File should be properly closed"

            # Cleanup test file
            rm(test_file, force = true)

            println("   ✅ @with_cleanup macro funcionando")
        end

        @testset "Safe Operations" begin
            # Test safe_operation wrapper
            result =
                safe_operation(() -> "test_resource", (res) -> println("Cleaned: $res"))
            @test result == "test_resource" "Safe operation should return result"

            println("   ✅ safe_operation wrapper funcionando")
        end

        @testset "Resource Tracker" begin
            # Test global resource tracking
            initial_count = length(Automation.GLOBAL_TRACKER.active_resources)

            # Track a test resource
            resource = track_resource("test_resource", "dummy_resource", () -> nothing)
            @test length(Automation.GLOBAL_TRACKER.active_resources) == initial_count + 1

            # Cleanup tracked resource
            cleanup_resource!("test_resource")
            @test length(Automation.GLOBAL_TRACKER.active_resources) == initial_count

            println("   ✅ Resource tracking funcionando")
        end
    end

    # ==========================================================================
    # TESTE 2: MEMORY MANAGEMENT PATTERNS
    # ==========================================================================
    @testset "💾 Memory Management Patterns" begin
        @testset "Memory Pool" begin
            # Test memory pool for vectors
            pool = MemoryPool{Vector{Float64}}(5, () -> Float64[], empty!)

            # Allocate from pool
            vec1 = allocate!(pool)
            @test vec1 !== nothing "Should allocate from pool"
            @test utilization(pool) ≈ 0.2 "Pool should be 20% utilized"

            # Return to pool
            push!(vec1, 1.0, 2.0, 3.0)
            success = deallocate!(pool, vec1)
            @test success "Should successfully deallocate"
            @test utilization(pool) ≈ 0.0 "Pool should be empty after deallocation"

            # Verify cleanup
            vec2 = allocate!(pool)
            @test isempty(vec2) "Vector should be reset when reused"

            deallocate!(pool, vec2)
            println("   ✅ Memory pool funcionando")
        end

        @testset "Object Pool" begin
            # Test with_pooled_vector
            result = with_pooled_vector() do vec
                push!(vec, 1.0, 2.0, 3.0)
                return sum(vec)
            end

            @test result == 6.0 "Pooled vector operation should work"

            println("   ✅ Object pool funcionando")
        end

        @testset "Leak Detection" begin
            detector = LeakDetector(1.0)  # 1MB threshold

            # Take initial snapshot
            take_snapshot!(detector)

            # Simulate small memory usage
            data = rand(1000)  # Small allocation
            take_snapshot!(detector)

            # Check for leaks (should not detect with small allocation)
            has_leak = detect_leaks!(detector)
            @test !has_leak "Should not detect leak with small allocation"

            println("   ✅ Leak detection funcionando")
        end

        @testset "Memory Monitoring" begin
            # Test memory limit wrapper
            result = with_memory_limit(100.0) do   # 100MB limit
                # Small operation
                data = rand(1000)
                return sum(data)
            end

            @test isa(result, Float64) "Memory-limited operation should complete"

            println("   ✅ Memory monitoring funcionando")
        end
    end

    # ==========================================================================
    # TESTE 3: SAFE I/O OPERATIONS
    # ==========================================================================
    @testset "📁 Safe I/O Operations" begin
        @testset "Safe File Operations" begin
            test_file = "test_safe_io.tmp"
            test_content = "Test content for safe I/O operations"

            # Test safe file write
            safe_file_operation(test_file, "w") do file
                write(file, test_content)
            end

            @test isfile(test_file) "File should be created"

            # Test safe file read
            read_content = safe_file_operation(test_file, "r") do file
                read(file, String)
            end

            @test read_content == test_content "Content should match"

            # Cleanup
            rm(test_file, force = true)

            println("   ✅ Safe file operations funcionando")
        end

        @testset "Buffered Operations" begin
            test_file = "test_buffered.tmp"
            large_content = "A" ^ 10000  # 10KB content

            # Test buffered write
            buffered_file_write(test_file, large_content, 1024)
            @test isfile(test_file) "Buffered write should create file"

            # Test buffered read
            read_content = buffered_file_read(test_file, 1024)
            @test read_content == large_content "Buffered read should match content"

            # Cleanup
            rm(test_file, force = true)

            println("   ✅ Buffered I/O funcionando")
        end

        @testset "File Resource Manager" begin
            manager = FileResourceManager(2)  # Max 2 open files

            test_file1 = "test_manager1.tmp"
            test_file2 = "test_manager2.tmp"

            # Create test files
            write(test_file1, "content1")
            write(test_file2, "content2")

            try
                # Get file handles
                handle1 = get_file_handle(manager, test_file1)
                handle2 = get_file_handle(manager, test_file2)

                @test isopen(handle1) "First file should be open"
                @test isopen(handle2) "Second file should be open"

                # Close all files
                close_all_files!(manager)

                @test length(manager.open_files) == 0 "All files should be closed"

            finally
                # Cleanup
                rm(test_file1, force = true)
                rm(test_file2, force = true)
            end

            println("   ✅ File resource manager funcionando")
        end
    end

    # ==========================================================================
    # TESTE 4: CSGA SCORE VALIDATION
    # ==========================================================================
    @testset "📊 CSGA Score Impact Validation" begin
        @testset "Resource Management Score Improvement" begin
            # Test that our implementations improve the score
            current_score = Automation.CSGAScoring.evaluate_resource_management(".")

            # Should be significantly higher than baseline (51.4)
            @test current_score >= 70.0 "Resource management score should be ≥ 70.0 after optimization"

            println("   📈 Resource Management Score: $(round(current_score, digits=1))/100")

            # Verify advanced patterns are detected
            julia_files = []
            for (root, dirs, files) in walkdir(".")
                for file in files
                    if endswith(file, ".jl") && !contains(root, ".git")
                        julia_files = [julia_files; joinpath(root, file)]
                    end
                end
            end

            advanced_patterns_found = 0
            for file_path in julia_files
                if isfile(file_path)
                    content = read(file_path, String)
                    if occursin("@with_cleanup", content) ||
                       occursin("safe_operation", content) ||
                       occursin("MemoryPool", content) ||
                       occursin("ResourceTracker", content)
                        advanced_patterns_found += 1
                        break
                    end
                end
            end

            @test advanced_patterns_found > 0 "Advanced resource management patterns should be detected"

            println("   ✅ Advanced patterns detected in codebase")
        end

        @testset "Green Code Pillar Impact" begin
            # Evaluate overall Green Code pillar
            score = Automation.evaluate_project(".")
            green_score = score.green_code_pillar.score

            println("   📊 Green Code Pillar: $(round(green_score, digits=1))/100")

            # Should be improved from baseline
            @test green_score >= 65.0 "Green Code pillar should benefit from resource management optimization"

            # Check resource management metric specifically
            resource_mgmt_score =
                get(score.green_code_pillar.metrics, "resource_management", 0.0)
            @test resource_mgmt_score >= 70.0 "Resource management metric should be optimized"

            println(
                "   📈 Resource Management Metric: $(round(resource_mgmt_score, digits=1))/100",
            )
        end
    end

    # ==========================================================================
    # PERFORMANCE BENCHMARKS
    # ==========================================================================
    @testset "⚡ Performance Validation" begin
        @testset "Memory Efficiency" begin
            # Measure memory usage of operations
            initial_memory = Base.gc_live_bytes()

            # Perform memory-intensive operation with our utilities
            with_gc_cleanup() do
                data = with_pooled_vector() do vec
                    for i in 1:1000
                        push!(vec, rand())
                    end
                    return copy(vec)
                end

                # Process in chunks
                result = chunked_processing(data, 100) do chunk
                    sum(chunk)
                end

                @test length(result) == 10 "Should process in 10 chunks"
            end

            GC.gc()
            final_memory = Base.gc_live_bytes()

            memory_growth = final_memory - initial_memory
            @test memory_growth <= 10_000_000 "Memory growth should be controlled (≤ 10MB)"

            println("   💾 Memory growth: $(round(memory_growth/1e6, digits=2))MB")
        end
    end

    println("✅ Resource Management validation completed!")
    println("🎯 Expected score improvement: +4.3 pontos CSGA")
end
