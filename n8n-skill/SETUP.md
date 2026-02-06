# Setup da Skill n8n-analyze

## Pré-requisitos

1. **Claude Code** instalado e funcionando
2. **n8n** com API habilitada
3. **curl** e **jq** instalados no sistema

## Passo 1: Criar API Key no n8n

1. Acesse seu n8n: `https://n8n.srvXXXXXX.hstgr.cloud`
2. Vá em **Settings** (ícone de engrenagem)
3. Clique em **API**
4. Clique em **Create API Key**
5. Copie a chave gerada

## Passo 2: Configurar variáveis de ambiente

Adicione ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
export N8N_BASE_URL='https://n8n.srvXXXXXX.hstgr.cloud'
export N8N_API_KEY='sua-api-key-aqui'
```

Depois execute:
```bash
source ~/.bashrc
```

## Passo 3: Testar conexão

```bash
bash n8n-skill/scripts/n8n-api.sh test
```

Deve retornar: `Conexão bem-sucedida`

## Passo 4: Usar a skill

No Claude Code, execute:

```
/n8n-analyze          # Listar e analisar interativamente
/n8n-analyze all      # Analisar todos os workflows
/n8n-analyze <id>     # Analisar workflow específico
/n8n-analyze fix <id> # Corrigir workflow específico
/n8n-analyze backup   # Backup de todos os workflows
/n8n-analyze report   # Relatório consolidado
```

## Comandos do script auxiliar

```bash
# Listar workflows
bash n8n-skill/scripts/n8n-api.sh list

# Ver detalhes de um workflow
bash n8n-skill/scripts/n8n-api.sh get <workflow_id>

# Backup de um workflow
bash n8n-skill/scripts/n8n-api.sh backup <workflow_id>

# Backup de todos
bash n8n-skill/scripts/n8n-api.sh backup

# Ver execuções
bash n8n-skill/scripts/n8n-api.sh executions <workflow_id> [limit]

# Atualizar workflow
bash n8n-skill/scripts/n8n-api.sh update <workflow_id> '<json>'

# Ativar/desativar
bash n8n-skill/scripts/n8n-api.sh activate <workflow_id>
bash n8n-skill/scripts/n8n-api.sh deactivate <workflow_id>
```

## Solução de Problemas

### "N8N_BASE_URL não configurada"
Execute `export N8N_BASE_URL='sua-url'` ou adicione ao `.bashrc`

### "Erro HTTP 401"
Sua API key está incorreta ou expirou. Gere uma nova no n8n.

### "Erro HTTP 403"
A API do n8n pode não estar habilitada. Verifique em Settings > API.

### "Falha na conexão"
- Verifique se a URL está correta (sem `/` no final)
- Verifique se o n8n está rodando
- Verifique se não há firewall bloqueando
