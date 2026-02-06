#!/bin/bash
# n8n API Helper Script
# Interage com a API REST do n8n para gerenciar workflows

set -euo pipefail

# Configuração
N8N_BASE_URL="${N8N_BASE_URL:-}"
N8N_API_KEY="${N8N_API_KEY:-}"
BACKUP_DIR="/home/user/Bielleon/n8n-skill/backups"
TEMP_DIR="/home/user/Bielleon/n8n-skill/temp"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar dependências
check_deps() {
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}ERRO: '$cmd' não encontrado. Instale com: apt-get install $cmd${NC}"
            exit 1
        fi
    done
}

# Verificar configuração
check_config() {
    if [ -z "$N8N_BASE_URL" ]; then
        echo -e "${RED}ERRO: N8N_BASE_URL não configurada${NC}"
        echo "Execute: export N8N_BASE_URL='https://n8n.srvXXXXXX.hstgr.cloud'"
        exit 1
    fi
    if [ -z "$N8N_API_KEY" ]; then
        echo -e "${RED}ERRO: N8N_API_KEY não configurada${NC}"
        echo "Execute: export N8N_API_KEY='sua-api-key-aqui'"
        exit 1
    fi
}

# Função para chamadas à API com retry
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local max_retries=4
    local retry_delay=2

    local url="${N8N_BASE_URL}/api/v1${endpoint}"

    for ((i=1; i<=max_retries; i++)); do
        local response
        local http_code

        if [ "$method" = "GET" ]; then
            response=$(curl -s -w "\n%{http_code}" \
                -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
                -H "Accept: application/json" \
                "$url" 2>/dev/null) || true
        elif [ "$method" = "PUT" ]; then
            response=$(curl -s -w "\n%{http_code}" \
                -X PUT \
                -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                -d "$data" \
                "$url" 2>/dev/null) || true
        elif [ "$method" = "POST" ]; then
            response=$(curl -s -w "\n%{http_code}" \
                -X POST \
                -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json" \
                -d "$data" \
                "$url" 2>/dev/null) || true
        fi

        # Extrair http code (última linha) e body (restante)
        http_code=$(echo "$response" | tail -n1)
        local body=$(echo "$response" | sed '$d')

        if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ] 2>/dev/null; then
            echo "$body"
            return 0
        elif [ "$http_code" -ge 400 ] && [ "$http_code" -lt 500 ] 2>/dev/null; then
            echo -e "${RED}ERRO (HTTP $http_code): Erro na requisição${NC}" >&2
            echo "$body" >&2
            return 1
        else
            if [ "$i" -lt "$max_retries" ]; then
                echo -e "${YELLOW}Tentativa $i falhou (HTTP $http_code). Retentando em ${retry_delay}s...${NC}" >&2
                sleep "$retry_delay"
                retry_delay=$((retry_delay * 2))
            else
                echo -e "${RED}ERRO: Todas as $max_retries tentativas falharam${NC}" >&2
                echo "$body" >&2
                return 1
            fi
        fi
    done
}

# Listar todos os workflows
list_workflows() {
    echo -e "${BLUE}Buscando workflows...${NC}" >&2

    local result
    result=$(api_call GET "/workflows") || return 1

    # Formatar saída como JSON limpo
    echo "$result" | jq '{
        total: (.data | length),
        workflows: [.data[] | {
            id: .id,
            name: .name,
            active: .active,
            nodes_count: (.nodes | length),
            created_at: .createdAt,
            updated_at: .updatedAt,
            tags: [.tags[]?.name]
        }]
    }' 2>/dev/null || echo "$result"
}

# Obter detalhes de um workflow específico
get_workflow() {
    local workflow_id="$1"

    if [ -z "$workflow_id" ]; then
        echo -e "${RED}ERRO: ID do workflow não fornecido${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Buscando workflow $workflow_id...${NC}" >&2

    local result
    result=$(api_call GET "/workflows/${workflow_id}") || return 1

    echo "$result" | jq '.' 2>/dev/null || echo "$result"
}

# Fazer backup de um workflow
backup_workflow() {
    local workflow_id="$1"

    if [ -z "$workflow_id" ]; then
        echo -e "${RED}ERRO: ID do workflow não fornecido${NC}" >&2
        return 1
    fi

    mkdir -p "$BACKUP_DIR"

    local result
    result=$(api_call GET "/workflows/${workflow_id}") || return 1

    local workflow_name
    workflow_name=$(echo "$result" | jq -r '.name' 2>/dev/null | tr ' ' '_' | tr -cd '[:alnum:]_-')
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${BACKUP_DIR}/${workflow_id}_${workflow_name}_${timestamp}.json"

    echo "$result" | jq '.' > "$backup_file"

    echo -e "${GREEN}Backup salvo em: ${backup_file}${NC}" >&2
    echo "$backup_file"
}

# Fazer backup de todos os workflows
backup_all() {
    mkdir -p "$BACKUP_DIR"

    echo -e "${BLUE}Fazendo backup de todos os workflows...${NC}" >&2

    local list_result
    list_result=$(api_call GET "/workflows") || return 1

    local ids
    ids=$(echo "$list_result" | jq -r '.data[].id' 2>/dev/null)

    local count=0
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    while IFS= read -r id; do
        if [ -n "$id" ]; then
            local result
            result=$(api_call GET "/workflows/${id}") || continue

            local workflow_name
            workflow_name=$(echo "$result" | jq -r '.name' 2>/dev/null | tr ' ' '_' | tr -cd '[:alnum:]_-')
            local backup_file="${BACKUP_DIR}/${id}_${workflow_name}_${timestamp}.json"

            echo "$result" | jq '.' > "$backup_file"
            echo -e "${GREEN}  Backup: ${workflow_name} (ID: ${id})${NC}" >&2
            count=$((count + 1))
        fi
    done <<< "$ids"

    echo -e "${GREEN}Total: $count workflows salvos em ${BACKUP_DIR}${NC}" >&2
}

# Atualizar um workflow
update_workflow() {
    local workflow_id="$1"
    local json_data="$2"

    if [ -z "$workflow_id" ] || [ -z "$json_data" ]; then
        echo -e "${RED}ERRO: ID e JSON são obrigatórios${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}Atualizando workflow $workflow_id...${NC}" >&2

    local result
    result=$(api_call PUT "/workflows/${workflow_id}" "$json_data") || return 1

    echo -e "${GREEN}Workflow atualizado com sucesso!${NC}" >&2
    echo "$result" | jq '{id: .id, name: .name, active: .active, updatedAt: .updatedAt}' 2>/dev/null || echo "$result"
}

# Obter execuções de um workflow
get_executions() {
    local workflow_id="$1"
    local limit="${2:-10}"

    echo -e "${BLUE}Buscando últimas $limit execuções do workflow $workflow_id...${NC}" >&2

    local result
    result=$(api_call GET "/executions?workflowId=${workflow_id}&limit=${limit}") || return 1

    echo "$result" | jq '{
        total: (.data | length),
        executions: [.data[] | {
            id: .id,
            finished: .finished,
            status: .status,
            started_at: .startedAt,
            stopped_at: .stoppedAt,
            mode: .mode
        }]
    }' 2>/dev/null || echo "$result"
}

# Ativar um workflow
activate_workflow() {
    local workflow_id="$1"

    echo -e "${YELLOW}Ativando workflow $workflow_id...${NC}" >&2
    api_call POST "/workflows/${workflow_id}/activate" || return 1
    echo -e "${GREEN}Workflow ativado!${NC}" >&2
}

# Desativar um workflow
deactivate_workflow() {
    local workflow_id="$1"

    echo -e "${YELLOW}Desativando workflow $workflow_id...${NC}" >&2
    api_call POST "/workflows/${workflow_id}/deactivate" || return 1
    echo -e "${GREEN}Workflow desativado!${NC}" >&2
}

# Testar conexão
test_connection() {
    echo -e "${BLUE}Testando conexão com n8n...${NC}" >&2

    local result
    result=$(api_call GET "/workflows?limit=1") || {
        echo -e "${RED}Falha na conexão!${NC}" >&2
        return 1
    }

    local total
    total=$(echo "$result" | jq '.data | length' 2>/dev/null || echo "?")

    echo -e "${GREEN}Conexão OK! Instância acessível.${NC}" >&2
    echo "Conexão bem-sucedida"
}

# Main
check_deps

case "${1:-help}" in
    list)
        check_config
        list_workflows
        ;;
    get)
        check_config
        get_workflow "${2:-}"
        ;;
    backup)
        check_config
        if [ -n "${2:-}" ]; then
            backup_workflow "$2"
        else
            backup_all
        fi
        ;;
    update)
        check_config
        update_workflow "${2:-}" "${3:-}"
        ;;
    executions)
        check_config
        get_executions "${2:-}" "${3:-10}"
        ;;
    activate)
        check_config
        activate_workflow "${2:-}"
        ;;
    deactivate)
        check_config
        deactivate_workflow "${2:-}"
        ;;
    test)
        check_config
        test_connection
        ;;
    help|*)
        echo "n8n API Helper - Gerenciador de Workflows"
        echo ""
        echo "Uso: $0 <comando> [argumentos]"
        echo ""
        echo "Comandos:"
        echo "  list                    Listar todos os workflows"
        echo "  get <id>                Obter detalhes de um workflow"
        echo "  backup [id]             Fazer backup (de um ou todos)"
        echo "  update <id> '<json>'    Atualizar um workflow"
        echo "  executions <id> [limit] Ver execuções de um workflow"
        echo "  activate <id>           Ativar um workflow"
        echo "  deactivate <id>         Desativar um workflow"
        echo "  test                    Testar conexão com n8n"
        echo "  help                    Mostrar esta ajuda"
        echo ""
        echo "Variáveis de ambiente necessárias:"
        echo "  N8N_BASE_URL  - URL da instância n8n (ex: https://n8n.srv123.hstgr.cloud)"
        echo "  N8N_API_KEY   - API Key do n8n"
        ;;
esac
