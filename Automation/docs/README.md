# Automation.jl Documentation

This directory contains the documentation for Automation.jl.

## Building Documentation

To build the documentation locally:

```julia
julia --project=docs
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()

include("docs/make.jl")
```

## Documentation Structure

- `src/` - Documentation source files
- `build/` - Generated HTML documentation (auto-generated)
- `make.jl` - Documentation build script

## Automatic Builds

Documentation is automatically built and deployed by GitHub Actions:

- On every push to `main` branch
- Available at: `https://username.github.io/Automation.jl/`

## Coverage Integration

The documentation includes:

- API reference
- Quality metrics dashboard
- Coverage reports
- Performance benchmarks
- CSGA assessment results
