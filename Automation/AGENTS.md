# AGENTS.md - Automation Project

## Project Overview
This is a Julia automation project built on 4 fundamental pillars:
1. **Security First** - Segurança como prioridade máxima
2. **Clean Code** - Código limpo, bem estruturado e documentado  
3. **Green Code** - Eficiência de desempenho e uso responsável de recursos
4. **Advanced Automation** - Processos automatizados para testes, CI/CD, qualidade e documentação

## Environment Setup
- Julia 1.11.6 installed via Homebrew: `brew install julia`
- Use official JuliaLang packages only (.jl ecosystem)
- Project dependencies managed via Project.toml/Manifest.toml
- Development mode: `make dev`

## Build and Test Commands

### Essential Commands
```bash
make install    # Install dependencies
make test      # Run test suite (required >90% coverage)
make format    # Code formatting with JuliaFormatter
make clean     # Clean temporary files
make dev       # Start development mode with Revise
make pluto     # Launch Pluto notebooks
```

### Development Workflow
```bash
make setup     # Initial project setup
make csga      # Run CSGA evaluation
make validate  # Validate against 4 pillars
```

## Security Guidelines (SECURITY FIRST)

### Package Management
- **ONLY** use official JuliaLang packages (.jl ecosystem)
- Verify package sources: `julia --project=. -e "using Pkg; Pkg.status()"`
- Pin versions in Project.toml [compat] section
- Regular dependency audits: `julia --project=. -e "using Pkg; Pkg.audit()"`

### Code Security
- Never hardcode secrets/credentials
- Use environment variables for sensitive data
- Validate all external inputs with type checking
- Implement proper error handling without information leakage
- Use HTTPS for network communications

### Security Validation Commands
```bash
# Audit dependencies
julia --project=. -e "using Pkg; Pkg.audit()"

# Security validation included in tests
make test

# Clean sensitive temporary files
make clean
```

### Required Security Practices
- No eval() or @eval usage
- No unsafe_ function calls
- No ccall() without explicit validation
- Environment variables for all secrets

## Clean Code Standards

### Julia Conventions (MANDATORY)
- Variables: `snake_case` (e.g., `user_data`, `result_matrix`)
- Functions: descriptive verbs (e.g., `calculate_metrics`, `validate_input`)
- Types: `PascalCase` (e.g., `DataProcessor`, `SecurityValidator`)
- Constants: `UPPER_CASE` (e.g., `MAX_RETRIES`, `DEFAULT_TIMEOUT`)
- Always specify types: `function process(data::DataFrame)::Vector{Float64}`

### Function Quality Rules
- Maximum 20 lines per function
- Single responsibility principle
- Document public functions with docstrings
- Use type annotations for clarity
- Avoid global variables in performance-critical code

### Code Organization
- One main type per file
- Explicit exports and organized imports
- Separate interface from implementation
- Follow project structure: src/, test/, docs/, examples/, benchmarks/

### Formatting Commands
```bash
# Auto-format code
make format
julia --project=. -e "using JuliaFormatter; format('.')"

# Validate organization
make test
```

### Documentation Requirements
- Docstrings for all public functions
- README.md kept updated
- Comments explain 'why', not 'what'
- Examples in documentation

## Performance & Green Code Standards

### Efficiency Patterns (GREEN CODE)
- Use `view()` instead of array copying
- Preallocate arrays: `result = Vector{Float64}(undef, n)`
- Prefer `StaticArrays` for small fixed arrays
- Profile with `@benchmark` for optimization
- Monitor memory allocations

### Performance Commands
```bash
# Run performance benchmarks
make bench
julia --project=. benchmarks/run_benchmarks.jl

# Profile specific functions
julia --project=. -e "using ProfileView; @profile my_function(); ProfileView.view()"

# Memory allocation analysis
julia --project=. -e "using BenchmarkTools; @benchmark my_function()"
```

### Performance Targets
- Startup time ≤ 2 seconds
- Memory growth ≤ 5% per month
- CPU efficiency ≥ 85%
- Benchmark regression ≤ 5%
- GC time ratio <10%

### Resource Management
- Use try-finally for cleanup
- Close files explicitly: `close(file)`
- Avoid global variables in loops
- Use @inbounds with proper bounds checking
- Monitor garbage collection time

### Optimization Patterns
- Use broadcasting when possible
- Avoid unnecessary collect() calls
- Prefer in-place operations
- Use @simd and @inbounds judiciously

## Advanced Automation

### CI/CD Infrastructure
```bash
# Essential automation commands
make install       # Install dependencies
make test         # Run test suite
make format       # Code formatting
make clean        # Clean temporary files
make dev          # Development mode with Revise
make pluto        # Launch Pluto notebooks

# CSGA Quality System
make csga         # Full CSGA evaluation report
make csga-report  # Quick score summary
make validate     # Validate against 4 pillars
```

### Quality Gates & Automation
- All tests must pass: `make test`
- Code coverage >90% required
- No security vulnerabilities
- Performance within established thresholds
- Automated formatting before commit

### Pre-commit Requirements
```bash
# Required workflow before commit
make format && make test && make validate
```

### Project Structure (Automated)
```
├── src/                 # Source code
│   ├── Automation.jl    # Main module
│   └── csga_scoring.jl  # Quality assessment
├── test/               # Test files
├── benchmarks/         # Performance benchmarks
├── examples/           # Usage examples
├── docs/              # Documentation
├── .vscode/           # IDE configuration
├── Project.toml       # Dependencies
├── Manifest.toml      # Dependency lock
├── Makefile          # Automation commands
└── AGENTS.md         # This file
```

### Automated Workflows
- Continuous integration via make commands
- Quality assessment with CSGA scoring
- Performance monitoring with benchmarks
- Documentation generation
- Dependency management and auditing

## Agent-Specific Instructions

### Code Generation Rules
- Follow naming conventions strictly
- Include type annotations for all functions
- Add docstrings for public functions using Julia docstring format
- Implement comprehensive error handling
- Write corresponding tests for all new code

### Refactoring Guidelines
- Always maintain API compatibility
- Update all related tests
- Benchmark performance impact before/after
- Update documentation accordingly
- Validate security implications

### Optimization Priorities
1. **Correctness** - All tests must pass
2. **Security** - No vulnerabilities introduced
3. **Performance** - Benchmarks within thresholds
4. **Maintainability** - Clean, readable code
5. **Documentation** - Up-to-date and accurate

### CSGA Compliance
- Every change must maintain or improve CSGA score
- Use `make csga-report` to validate improvements
- Address any regressions immediately
- Target score progression: Intermediário → Avançado → Expert

## Emergency Procedures

### Security Incident Response
```bash
# Immediate security audit
julia --project=. -e "using Pkg; Pkg.audit()"

# Check for exposed secrets
grep -r "password\|secret\|key" src/ test/ --exclude-dir=.git

# Validate package integrity
make test
```

### Performance Degradation Response
```bash
# Performance diagnosis
make bench

# Memory analysis
julia --project=. -e "using BenchmarkTools; @benchmark problematic_function()"
```

### Build Failure Recovery
```bash
# Clean and rebuild
make clean && make install

# Dependency resolution
julia --project=. -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"

# Environment validation
make test
```

### CSGA Score Regression
```bash
# Immediate assessment
make csga-report

# Detailed analysis
make csga

# Rollback if critical
git revert HEAD
```

---
*This AGENTS.md is optimized for AI coding agents working with Julia projects following the 4 fundamental pillars.*
*Last updated: 2025-09-02*
*Compliance: Security First | Clean Code | Green Code | Advanced Automation*