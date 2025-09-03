using Documenter
using Automation

# Define documentation structure
makedocs(
    sitename="Automation.jl",
    authors="Automation.jl Contributors",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true",
        canonical="https://username.github.io/Automation.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => [
            "Installation" => "installation.md",
            "Quick Start" => "quickstart.md",
            "Basic Usage" => "basic_usage.md",
        ],
        "CSGA Framework" => [
            "Overview" => "csga/overview.md",
            "Clean Code" => "csga/clean_code.md",
            "Security" => "csga/security.md",
            "Green Code" => "csga/green_code.md",
            "Automation" => "csga/automation.md",
        ],
        "Quality Analysis" => [
            "Quality Analyzer" => "quality/analyzer.md",
            "Metrics" => "quality/metrics.md",
            "Dashboard" => "quality/dashboard.md",
        ],
        "Performance" => [
            "Optimization" => "performance/optimization.md",
            "Benchmarks" => "performance/benchmarks.md",
            "Memory Management" => "performance/memory.md",
        ],
        "CI/CD Integration" => [
            "GitHub Actions" => "cicd/github_actions.md",
            "Quality Gates" => "cicd/quality_gates.md",
            "Coverage" => "cicd/coverage.md",
        ],
        "API Reference" => "api.md",
        "Contributing" => "contributing.md",
    ],
    doctest=true,
    linkcheck=true,
)

# Deploy documentation
deploydocs(
    repo="github.com/username/Automation.jl.git",
    target="build",
    branch="gh-pages",
    devbranch="main",
    push_preview=true,
)
