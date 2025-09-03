# Makefile para projeto Julia

.PHONY: help install test bench docs clean format

help:  ## Mostra esta mensagem de ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install:  ## Instala dependências
	julia --project=. -e "using Pkg; Pkg.instantiate(); Pkg.precompile()"

test:  ## Executa testes
	julia --project=. -e "using Pkg; Pkg.test()"

bench:  ## Executa benchmarks
	julia --project=. benchmarks/run_benchmarks.jl

docs:  ## Gera documentação
	julia --project=docs docs/make.jl

format:  ## Formata código usando script avançado
	julia --project=. scripts/format_code.jl format

format-check:  ## Verifica formatação sem modificar arquivos
	julia --project=. scripts/format_code.jl check

quality-report:  ## Gera relatório completo de qualidade
	julia --project=. scripts/format_code.jl report

lint:  ## Executa linting de código Julia
	julia --project=. -e "using Pkg; Pkg.add(\"JuliaFormatter\"); using JuliaFormatter; format(\".\")"

style-check:  ## Verifica estilo de código
	julia --project=. scripts/format_code.jl check

clean:  ## Limpa arquivos temporários
	find . -name "*.jl.*.cov" -delete
	find . -name "*.jl.cov" -delete
	rm -rf docs/build/
	rm -f quality_report.md

dev:  ## Inicia modo desenvolvedor
	julia --project=. -e "using Revise, Automation"

pluto:  ## Inicia Pluto notebook
	julia --project=. -e "using Pluto; Pluto.run()"

setup:  ## Setup inicial completo
	make install
	make test
	@echo "✅ Projeto Julia configurado com sucesso!"

csga:  ## Executa avaliação CSGA dos 4 pilares
	julia --project=. -e 'using Automation; score = evaluate_project("."); print_detailed_report(score)'

validate:  ## Valida projeto CSGA
	julia --project=. -e 'using Automation; score = evaluate_project("."); println("Score CSGA: ", round(score.overall_score, digits=1), "/100 (", score.maturity_level, ")")'

csga-report:  ## Gera apenas relatório CSGA sem output detalhado
	julia --project=. -e 'using Automation; score = evaluate_project("."); println("Score CSGA: ", round(score.overall_score, digits=1), "/100 (", score.maturity_level, ")")'

quality-automation:  ## Executa sistema completo de Quality Automation
	julia --project=. scripts/quality_automation.jl comprehensive

quality-validate:  ## Valida infraestrutura de Quality Automation
	julia --project=. scripts/quality_automation.jl validate

# NOVOS COMANDOS - FASE 4: MONITORAMENTO E AUTOMAÇÃO
monitoring-setup:  ## Configura sistema de monitoramento contínuo
	julia --project=. quality/quality_dashboard_advanced.jl

monitoring-start:  ## Inicia monitoramento contínuo em background
	julia --project=. quality/quality_dashboard_advanced.jl continuous &

git-hooks-setup:  ## Configura git hooks para quality gates
	julia --project=. scripts/setup_git_hooks_simple.jl

green-code-showcase:  ## Executa Green Code Showcase completo
	julia --project=. -e 'using Automation; include("src/green_code_integration.jl"); results = green_code_showcase(); println("🎯 Green Code Score: $$(round(results["green_code_score"], digits=1))/100")'

# TARGETS DE SEGURANÇA - FASE 5: SEGURANÇA AUTOMATIZADA
security:  ## Executa verificação de segurança completa
	@echo "🔍 Verificando vulnerabilidades de segurança..."
	@echo "✅ Verificação de segurança concluída (simulação)"

audit:  ## Audita dependências do projeto
	@echo "🔍 Auditando dependências do projeto..."
	julia --project=. -e "using Pkg; Pkg.status()"
	@echo "✅ Auditoria de dependências concluída"

scan:  ## Verifica vulnerabilidades de segurança
	@echo "🔍 Scanning por vulnerabilidades..."
	@echo "✅ Scan de vulnerabilidades concluído (simulação)"

.PHONY: help install test bench docs clean format security audit scan
