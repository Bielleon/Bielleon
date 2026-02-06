# Bielleon - Projeto de Automações n8n

## Sobre
Este repositório contém ferramentas e skills para análise e otimização de automações n8n focadas em criação de conteúdo.

## Estrutura
```
.claude/
  commands/
    n8n-analyze.md    # Skill principal de análise n8n
  settings.json       # Permissões do projeto
n8n-skill/
  scripts/
    n8n-api.sh        # Script de interação com API do n8n
    n8n-patterns.json # Padrões conhecidos de problemas e boas práticas
  backups/            # Backups automáticos de workflows
```

## Configuração necessária
```bash
export N8N_BASE_URL='https://n8n.srvXXXXXX.hstgr.cloud'
export N8N_API_KEY='sua-api-key'
```

## Skill disponível
- `/n8n-analyze` - Analisar automações n8n (ver .claude/commands/n8n-analyze.md)

## Contexto do usuário
- Workflows focados em **criação de conteúdo**
- Integrações principais: Heygen, ChatGPT, Claude, Gemini, Google (Drive/Sheets), Blotato, Creatomate, Apify, OpenRouter, Telegram, WhatsApp (Z-API)
- Triggers principais: Webhook (WhatsApp via Z-API), Telegram, Manual
- Error workflow existente: envia alerta via WhatsApp
- n8n hospedado na Hostinger
- Idioma: sempre português brasileiro
