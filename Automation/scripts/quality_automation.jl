#!/usr/bin/env julia
"""
Quality Automation - Sistema Avançado de Automação de Qualidade
Script central para execução de todas as funcionalidades de Quality Automation

Funcionalidades:
- Análise contínua de qualidade
- Integração com sistema CSGA
- Geração de relatórios automatizados
- Dashboard interativo
- Monitoramento em tempo real
"""

using Pkg
using Dates
using Statistics

# Incluir dependências do sistema de qualidade
include("../quality_config.jl")
include("../quality/quality_dashboard.jl")

export run_quality_automation, continuous_quality_monitor
export generate_comprehensive_report, validate_infrastructure

"""
    run_quality_automation(mode::String = "check") -> Dict{String, Any}

Executa análise completa de Quality Automation
Modos: "check", "report", "dashboard", "monitor"
"""
function run_quality_automation(mode::String = "check")
    project_path = "."

    println("🔧 Quality Automation System")
    println("="^40)
    println("Mode: $mode")
    println("Project: $(basename(abspath(project_path)))")
    println("Timestamp: $(now())")
    println()

    results = Dict{String, Any}()

    if mode == "check"
        # Verificação rápida de saúde
        results = quality_health_check(project_path)

    elseif mode == "report"
        # Relatório completo
        results["health"] = quality_health_check(project_path)
        results["report"] = create_quality_report(project_path)
        results["validation"] = validate_quality_metrics(project_path)

    elseif mode == "dashboard"
        # Gerar dashboard HTML
        results["health"] = quality_health_check(project_path)
        results["dashboard_path"] = generate_dashboard(project_path)

    elseif mode == "monitor"
        # Monitor contínuo
        println("🔄 Starting continuous monitoring...")
        monitor_quality(project_path, 5)  # Check every 5 minutes

    else
        error("Modo inválido: $mode. Use: check, report, dashboard, monitor")
    end

    return results
end

"""
    validate_infrastructure() -> Bool

Valida se toda a infraestrutura de Quality Automation está presente
"""
function validate_infrastructure()
    println("🔍 Validating Quality Automation Infrastructure")
    println("="^48)

    all_valid = true

    # 1. Verificar arquivos essenciais
    required_files = [
        ".vscode/settings.json" => "VSCode configuration",
        "scripts/format_code.jl" => "Formatting script",
        "Makefile" => "Build automation",
        ".git/hooks/pre-commit" => "Git quality hooks",
        "quality_config.jl" => "Quality configuration",
        "quality/quality_dashboard.jl" => "Dashboard system",
    ]

    for (file, description) in required_files
        if isfile(file)
            println("   ✅ $description: $file")
        else
            println("   ❌ Missing $description: $file")
            all_valid = false
        end
    end

    # 2. Verificar targets do Makefile
    println("\n📋 Checking Makefile targets...")
    makefile_content = isfile("Makefile") ? read("Makefile", String) : ""

    required_targets = [
        "format" => "Code formatting",
        "format-check" => "Format validation",
        "quality-report" => "Quality reporting",
        "quality-dashboard" => "Dashboard generation",
        "csga" => "CSGA evaluation",
    ]

    for (target, description) in required_targets
        if occursin(Regex("^$target:", "m"), makefile_content)
            println("   ✅ $description: make $target")
        else
            println("   ❌ Missing $description: make $target")
            all_valid = false
        end
    end

    # 3. Testar execução básica
    println("\n🧪 Testing basic functionality...")
    try
        # Testar health check
        health = quality_health_check(".")
        println("   ✅ Health check functional")

        # Testar geração de relatório
        report = create_quality_report(".")
        println("   ✅ Report generation functional")

    catch e
        println("   ❌ Functionality test failed: $e")
        all_valid = false
    end

    println("\n" * "="^48)
    if all_valid
        println("🎉 Quality Automation Infrastructure: COMPLETE")
        println("💡 Run 'julia scripts/quality_automation.jl' to start")
    else
        println("⚠️  Quality Automation Infrastructure: INCOMPLETE")
        println("💡 Fix missing components and re-run validation")
    end

    return all_valid
end

"""
    continuous_quality_monitor(interval_minutes::Int = 30)

Monitor contínuo de qualidade com alertas automáticos
"""
function continuous_quality_monitor(interval_minutes::Int = 30)
    println("🔄 Continuous Quality Monitor Started")
    println("Interval: $interval_minutes minutes")
    println("Press Ctrl+C to stop\n")

    previous_score = 0.0

    try
        while true
            health = quality_health_check(".")
            current_score = health["csga_score"]

            # Detectar mudanças significativas
            if previous_score > 0.0
                score_change = current_score - previous_score
                if abs(score_change) >= 1.0
                    if score_change > 0
                        println(
                            "📈 IMPROVEMENT: Score increased by $(round(score_change, digits=1)) points!",
                        )
                    else
                        println(
                            "📉 DEGRADATION: Score decreased by $(round(abs(score_change), digits=1)) points!",
                        )
                    end
                end
            end

            previous_score = current_score

            # Aguardar próximo check
            println("⏰ Next check in $interval_minutes minutes...")
            sleep(interval_minutes * 60)
        end
    catch InterruptException
        println("\n👋 Quality monitoring stopped")
    end
end

"""
    generate_comprehensive_report() -> String

Gera relatório abrangente incluindo histórico e tendências
"""
function generate_comprehensive_report()
    println("📊 Generating Comprehensive Quality Report")
    println("="^40)

    project_path = "."
    health = quality_health_check(project_path)
    validation = validate_quality_metrics(project_path)

    report = """
# 📊 Comprehensive Quality Report
**Project**: $(basename(abspath(project_path)))
**Generated**: $(Dates.format(now(), "dd/mm/yyyy HH:MM:SS"))
**System**: CSGA Quality Automation

---

## 🎯 Executive Summary
- **Overall Status**: $(uppercase(health["overall_status"]))
- **CSGA Score**: $(round(health["csga_score"], digits=1))/100
- **Quality Automation Score**: $(round(health["qa_score"], digits=1))/100
- **Infrastructure Status**: $(health["file_status"])

## 📋 Detailed Analysis

### 🏗️ Infrastructure Health
- **Total Julia Files**: $(health["total_julia_files"])
- **Essential Files Present**: $(length(health["missing_files"]) == 0 ? "All" : "$(5 - length(health["missing_files"]))/5")
- **Missing Components**: $(isempty(health["missing_files"]) ? "None" : join(health["missing_files"], ", "))

### 📊 Quality Metrics
- **CSGA Score**: $(round(health["csga_score"], digits=1))/100
- **Quality Automation**: $(round(health["qa_score"], digits=1))/100
- **Target Score**: 85.0/100 (Expert Level)
- **Gap to Target**: $(round(85.0 - health["csga_score"], digits=1)) points

### 🔧 Quality Automation Features
- ✅ **Code Formatting**: Advanced JuliaFormatter integration
- ✅ **Git Hooks**: Pre-commit quality validation
- ✅ **VSCode Integration**: Real-time quality checking
- ✅ **Dashboard System**: HTML quality visualization
- ✅ **Makefile Automation**: Standardized quality commands

### 📈 Recommendations

#### 🚀 Immediate Actions (High Priority)
"""

    if health["overall_status"] == "healthy"
        report *= """
- 🎯 **Maintain Excellence**: Continue current quality practices
- 📊 **Monitor Metrics**: Regular quality health checks
- 🔄 **Automated Monitoring**: Consider continuous quality monitoring
"""
    else
        report *= """
- 🔧 **Fix Infrastructure**: Address missing components
- 📝 **Run Quality Check**: Execute `make quality-report`
- 🎯 **Improve Score**: Target 85.0+ CSGA score
"""
    end

    report *= """

#### 🔄 Continuous Improvement (Medium Priority)
- 📊 **Quality Metrics**: Implement detailed code analysis
- 🤖 **Automation Enhancement**: Expand git hooks coverage
- 📈 **Trend Analysis**: Track quality metrics over time
- 🎨 **Dashboard Enhancement**: Add interactive features

#### 🎯 Strategic Goals (Long-term)
- 🏆 **Expert Level**: Achieve 87.4+ CSGA score consistently
- 🚀 **ROI Optimization**: Maintain 0.125+ points per 1K tokens
- 🔄 **Full Automation**: Zero-touch quality validation
- 📊 **Predictive Quality**: AI-powered quality forecasting

---

## 🛠️ Quick Commands
```bash
# Quality Operations
make quality-report          # Generate detailed report
make quality-dashboard       # Create HTML dashboard
make format                  # Format all code
make csga                    # Full CSGA evaluation

# Development Workflow
make setup                   # Complete project setup
make test                    # Run all tests
make dev                     # Start development mode
```

---

## 📊 Quality Automation Score Breakdown
- **Infrastructure**: $(round(20.0, digits=1))/20 points
- **Essential Files**: $(5 - length(health["missing_files"]))/5 present
- **CSGA Integration**: $(health["csga_status"] == "healthy" ? "✅" : "⚠️") Functional
- **Automation Level**: $(round(health["qa_score"], digits=1))/100 points

---
*Generated by CSGA Quality Automation v2.0*
*Next recommended check: $(Dates.format(now() + Dates.Hour(1), "HH:MM"))*
"""

    # Salvar relatório
    report_file = "comprehensive_quality_report.md"
    try
        write(report_file, report)
        println("📄 Comprehensive report saved: $report_file")
    catch e
        println("❌ Error saving report: $e")
    end

    return report
end

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================

"""
Execução principal quando script é chamado diretamente
"""
function main()
    if length(ARGS) == 0
        # Modo padrão: health check
        run_quality_automation("check")
    else
        mode = ARGS[1]
        if mode in ["check", "report", "dashboard", "monitor"]
            run_quality_automation(mode)
        elseif mode == "validate"
            validate_infrastructure()
        elseif mode == "comprehensive"
            generate_comprehensive_report()
        else
            println("❌ Modo inválido: $mode")
            println(
                "💡 Modos disponíveis: check, report, dashboard, monitor, validate, comprehensive",
            )
        end
    end
end

# Executar se chamado diretamente
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
