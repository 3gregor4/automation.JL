#!/usr/bin/env julia

"""
Setup Git Hooks - Versão Simplificada
Configura hooks básicos para quality gates
"""

using Dates

function setup_git_hooks()
    println("🔧 Configurando Git Hooks básicos...")

    # Verificar se estamos em um repositório Git
    if !isdir(".git")
        println("❌ Este diretório não é um repositório Git")
        return false
    end

    hooks_dir = ".git/hooks"

    # Verificar se pre-commit já existe e está executável
    precommit_path = joinpath(hooks_dir, "pre-commit")
    if isfile(precommit_path)
        try
            run(`chmod +x $precommit_path`)
            println("✅ Hook pre-commit já configurado")
        catch e
            println("⚠️  Erro configurando pre-commit: $e")
        end
    else
        println("❌ Hook pre-commit não encontrado")
        return false
    end

    # Criar documentação
    create_hooks_doc()

    println("✅ Git Hooks configurados com sucesso!")
    return true
end

function create_hooks_doc()
    doc_content = """
# 🔧 Git Hooks - Quality Gates

## Pre-commit Hook Configurado

O hook pre-commit executa as seguintes verificações:
- ✅ Sintaxe Julia
- ✅ Testes unitários
- ✅ Qualidade CSGA (≥85.0)
- ⚠️  Green Code (≥90.0)
- ⚠️  Formatação de código

## Como usar

```bash
# Commit normal (hooks executam automaticamente)
git commit -m "sua mensagem"

# Pular hooks temporariamente (use com cuidado!)
git commit --no-verify -m "sua mensagem"

# Testar hook manualmente
.git/hooks/pre-commit
```

## Thresholds Configurados
- CSGA Quality: 85.0/100
- Green Code: 90.0/100

---
Gerado em $(now())
"""

    write("GIT_HOOKS.md", doc_content)
    println("📚 Documentação criada: GIT_HOOKS.md")
end

function main()
    println("🚀 SETUP GIT HOOKS SIMPLIFICADO")
    println("="^35)

    success = setup_git_hooks()

    if success
        println("\n🎉 Setup concluído com sucesso!")
        println("🔐 Quality Gates ativos")
        println("📚 Consulte GIT_HOOKS.md")
    else
        println("\n⚠️  Problemas durante setup")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
