#!/usr/bin/env julia

"""
Setup Git Hooks - Configuração Automática de Quality Gates
Configura hooks do Git para garantir qualidade automática em todos os commits

Funcionalidades:
- Instalação automática de hooks
- Configuração de thresholds personalizáveis
- Verificação de dependências
- Backup de hooks existentes
"""

using Dates

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

const HOOKS_CONFIG = Dict(
    "pre-commit" => Dict(
        "description" => "Quality Gates automáticos antes de commit",
        "required" => true,
        "quality_threshold" => 85.0,
        "green_code_threshold" => 90.0
    ),
    "pre-push" => Dict(
        "description" => "Verificações adicionais antes de push",
        "required" => false,
        "run_benchmarks" => true
    ),
    "commit-msg" => Dict(
        "description" => "Validação de mensagens de commit",
        "required" => false,
        "enforce_conventional" => true
    )
)

# =============================================================================
# FUNÇÕES DE SETUP
# =============================================================================

"""
    setup_git_hooks(project_path::String = ".") -> Bool

Configura todos os git hooks necessários
"""
function setup_git_hooks(project_path::String=".")
    println("🔧 Configurando Git Hooks para Quality Gates...")

    git_hooks_dir = joinpath(project_path, ".git", "hooks")

    if !isdir(git_hooks_dir)
        println("❌ Diretório .git/hooks não encontrado. Certifique-se de estar em um repositório Git.")
        return false
    end

    success_count = 0

    for (hook_name, config) in HOOKS_CONFIG
        if setup_individual_hook(git_hooks_dir, hook_name, config)
            success_count += 1
        end
    end

    println("\n📊 Resumo da instalação:")
    println("   ✅ Hooks instalados: $success_count/$(length(HOOKS_CONFIG))")

    if success_count > 0
        configure_git_settings(project_path)
        create_hooks_documentation(project_path)
        run_initial_validation(project_path)
    end

    return success_count == length(HOOKS_CONFIG)
end

"""
    setup_individual_hook(hooks_dir::String, hook_name::String, config::Dict) -> Bool

Configura um hook individual
"""
function setup_individual_hook(hooks_dir::String, hook_name::String, config::Dict)
    hook_path = joinpath(hooks_dir, hook_name)

    println("\n🔨 Configurando hook: $hook_name")
    println("   📄 $(config["description"])")

    # Backup de hook existente
    if isfile(hook_path)
        backup_path = "$hook_path.backup.$(Dates.format(now(), "yyyymmdd_HHMMSS"))"
        cp(hook_path, backup_path)
        println("   💾 Backup criado: $(basename(backup_path))")
    end

    # Criar hook baseado no tipo
    if hook_name == "pre-commit"
        return create_precommit_hook(hook_path, config)
    elseif hook_name == "pre-push"
        return create_prepush_hook(hook_path, config)
    elseif hook_name == "commit-msg"
        return create_commitmsg_hook(hook_path, config)
    else
        println("   ⚠️  Hook $hook_name não implementado")
        return false
    end
end

"""
    create_precommit_hook(hook_path::String, config::Dict) -> Bool

Cria o hook pre-commit (já existe, apenas verificar)
"""
function create_precommit_hook(hook_path::String, config::Dict)
    if isfile(hook_path)
        # Verificar se o hook existente está funcionando
        if run(`chmod +x $hook_path`; wait=false).exitcode == 0
            println("   ✅ Hook pre-commit já configurado e executável")
            return true
        end
    else
        println("   ❌ Hook pre-commit não encontrado")
        return false
    end
end

"""
    create_prepush_hook(hook_path::String, config::Dict) -> Bool

Cria hook pre-push para verificações antes de push
"""
function create_prepush_hook(hook_path::String, config::Dict)
    hook_content = """#!/bin/bash

# PRE-PUSH HOOK - Verificações antes de push
echo "🚀 Executando verificações pre-push..."

PROJECT_ROOT=\$(git rev-parse --show-toplevel)
cd "\$PROJECT_ROOT"

# 1. Executar benchmarks se configurado
if [ "$(get(config, "run_benchmarks", false))" = "true" ]; then
    echo "📊 Executando benchmarks..."
    if ! make bench > /tmp/bench_output.log 2>&1; then
        echo "⚠️  Benchmarks falharam (não bloqueante)"
        echo "📄 Log salvo em: /tmp/bench_output.log"
    else
        echo "✅ Benchmarks executados com sucesso"
    fi
fi

# 2. Verificar se há commits desde último push
unpushed_commits=\$(git log @{u}..HEAD --oneline | wc -l)
if [ "\$unpushed_commits" -gt 10 ]; then
    echo "⚠️  Muitos commits não enviados: \$unpushed_commits"
    echo "💡 Considere fazer push mais frequentemente"
fi

# 3. Verificar status do repositório remoto
echo "🔍 Verificando status do repositório remoto..."
git fetch --dry-run 2>&1 | grep -q "up to date" || echo "⚠️  Repositório remoto pode ter atualizações"

echo "✅ Verificações pre-push concluídas"
exit 0
"""

    write(hook_path, hook_content)
    run(`chmod +x $hook_path`)

    println("   ✅ Hook pre-push criado e configurado")
    return true
end

"""
    create_commitmsg_hook(hook_path::String, config::Dict) -> Bool

Cria hook commit-msg para validar mensagens de commit
"""
function create_commitmsg_hook(hook_path::String, config::Dict)
    hook_content = """#!/bin/bash

# COMMIT-MSG HOOK - Validação de mensagens de commit
commit_msg_file="\$1"
commit_msg=\$(cat "\$commit_msg_file")

echo "📝 Validando mensagem de commit..."

# Verificar se não está vazia
if [ -z "\$commit_msg" ]; then
    echo "❌ Mensagem de commit não pode estar vazia"
    exit 1
fi

# Verificar comprimento mínimo
if [ \${#commit_msg} -lt 10 ]; then
    echo "❌ Mensagem de commit muito curta (mínimo: 10 caracteres)"
    exit 1
fi

# Verificar padrões convencionais (se habilitado)
if [ "$(get(config, "enforce_conventional", false))" = "true" ]; then
    if ! echo "\$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf)\(.+\)?: .+"; then
        echo "⚠️  Mensagem não segue padrão convencional"
        echo "💡 Exemplo: 'feat: adicionar nova funcionalidade'"
        echo "💡 Tipos: feat, fix, docs, style, refactor, test, chore, perf"
        # Não bloquear, apenas alertar
    fi
fi

echo "✅ Mensagem de commit validada"
exit 0
"""

    write(hook_path, hook_content)
    run(`chmod +x $hook_path`)

    println("   ✅ Hook commit-msg criado e configurado")
    return true
end

# =============================================================================
# CONFIGURAÇÕES ADICIONAIS
# =============================================================================

"""
    configure_git_settings(project_path::String)

Configura settings do Git para melhor integração
"""
function configure_git_settings(project_path::String)
    println("\n⚙️  Configurando settings do Git...")

    try
        # Configurar editor padrão se não estiver definido
        editor_result = read(`git config --get core.editor`, String)
    catch
        run(`git config core.editor nano`)
        println("   📝 Editor padrão definido como nano")
    end

    # Configurar line endings
    run(`git config core.autocrlf input`)
    println("   📄 Line endings configurados (input)")

    # Configurar whitespace
    run(`git config core.whitespace trailing-space,space-before-tab`)
    println("   🔍 Whitespace checking habilitado")

    println("   ✅ Git settings configurados")
end

"""
    create_hooks_documentation(project_path::String)

Cria documentação dos hooks instalados
"""
function create_hooks_documentation(project_path::String)
    doc_content = """
# 🔧 Git Hooks - Quality Gates Automáticos

Este repositório está configurado com hooks do Git para garantir qualidade automática.

## 📋 Hooks Instalados

### pre-commit
- **Função**: Verificações de qualidade antes de cada commit
- **Verificações**:
  - ✅ Sintaxe Julia
  - ✅ Testes unitários
  - ✅ Qualidade CSGA (threshold: 85.0)
  - ⚠️  Green Code (threshold: 90.0)
  - ⚠️  Formatação de código
  - ⚠️  Arquivos sensíveis

### pre-push
- **Função**: Verificações antes de push para repositório remoto
- **Verificações**:
  - 📊 Benchmarks (opcional)
  - 🔍 Status do repositório remoto
  - ⚠️  Alertas para muitos commits

### commit-msg
- **Função**: Validação de mensagens de commit
- **Verificações**:
  - 📝 Comprimento mínimo
  - 📋 Padrão convencional (opcional)

## 🚨 O que acontece se falhar?

- **pre-commit**: Commit é **rejeitado** se verificações críticas falharem
- **pre-push**: Push **não é bloqueado**, apenas alertas são exibidos
- **commit-msg**: Commit é **rejeitado** se mensagem for inválida

## 🛠️ Comandos Úteis

```bash
# Verificar status dos hooks
ls -la .git/hooks/

# Executar verificações manualmente
make test
make csga
make format-check

# Pular hooks temporariamente (use com cuidado!)
git commit --no-verify

# Executar hook manualmente
.git/hooks/pre-commit
```

## 🔧 Configuração

Os thresholds podem ser ajustados editando os hooks em `.git/hooks/`

**Configurações atuais**:
- CSGA Quality Threshold: 85.0
- Green Code Threshold: 90.0

---
*Documentação gerada automaticamente em $(now())*
"""

    doc_path = joinpath(project_path, "GIT_HOOKS.md")
    write(doc_path, doc_content)
    println("   📚 Documentação criada: GIT_HOOKS.md")
end

"""
    run_initial_validation(project_path::String)

Executa validação inicial para testar os hooks
"""
function run_initial_validation(project_path::String)
    println("\n🧪 Executando validação inicial dos hooks...")

    # Testar hook pre-commit
    hook_path = joinpath(project_path, ".git", "hooks", "pre-commit")
    if isfile(hook_path)
        println("   🔍 Testando pre-commit hook...")
        try
            # Simular execução (dry run)
            result = read(`bash -n $hook_path`, String)
            println("   ✅ Pre-commit hook válido (sintaxe)")
        catch e
            println("   ⚠️  Pre-commit hook pode ter problemas: $e")
        end
    end

    println("   ✅ Validação inicial concluída")
end

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

"""
    main()

Função principal do setup
"""
function main()
    println("🚀 SETUP GIT HOOKS - QUALITY GATES AUTOMÁTICOS")
    println("="^55)

    if length(ARGS) > 0 && ARGS[1] == "--help"
        println("""
Uso: julia setup_git_hooks.jl [opções]

Opções:
  --help    Exibir esta ajuda

Este script configura hooks do Git para garantir qualidade automática:
- pre-commit: Verificações antes de commit
- pre-push: Verificações antes de push
- commit-msg: Validação de mensagens
        """)
        return
    end

    project_path = "."

    # Verificar se estamos em um repositório Git
    if !isdir(joinpath(project_path, ".git"))
        println("❌ Este diretório não é um repositório Git")
        println("💡 Execute 'git init' primeiro")
        return
    end

    # Executar setup
    success = setup_git_hooks(project_path)

    if success
        println("\n🎉 SETUP CONCLUÍDO COM SUCESSO!")
        println("🔐 Quality Gates automáticos estão ativos")
        println("📚 Consulte GIT_HOOKS.md para mais informações")
    else
        println("\n⚠️  Setup concluído com avisos")
        println("🔍 Verifique as mensagens acima para detalhes")
    end
end

# Executar se chamado diretamente
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
