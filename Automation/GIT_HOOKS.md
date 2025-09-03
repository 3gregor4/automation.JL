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
Gerado em 2025-09-03T15:29:37.977
