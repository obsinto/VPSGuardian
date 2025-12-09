# 📚 Manual Completo do Sistema - Manutenção e Backup VPS

> **Documentação oficial do sistema de gerenciamento centralizado para Coolify + Cloudflare + Docker**
>
> Versão: 1.0 | Atualizado: 13 de Novembro de 2025

---

## 📖 Índice Completo

### PARTE I - VISÃO GERAL
- [1. Introdução](#1-introdução)
- [2. Arquitetura do Sistema](#2-arquitetura-do-sistema)
- [3. Componentes Principais](#3-componentes-principais)

### PARTE II - MENU E NAVEGAÇÃO
- [4. Como Usar o Menu Principal](#4-como-usar-o-menu-principal)
- [5. Submenus Disponíveis](#5-submenus-disponíveis)

### PARTE III - GUIA DETALHADO POR FUNÇÃO
- [6. Status e Diagnóstico](#6-status-e-diagnóstico)
- [7. Backups](#7-backups)
- [8. Manutenção](#8-manutenção)
- [9. Migração](#9-migração)
- [10. Configuração](#10-configuração)
- [11. Firewall (UFW)](#11-firewall-ufw)

### PARTE IV - DOCUMENTAÇÃO DE REFERÊNCIA
- [12. Estrutura de Funções](#12-estrutura-de-funções)
- [13. Logging e Monitoramento](#13-logging-e-monitoramento)
- [14. Segurança e Boas Práticas](#14-segurança-e-boas-práticas)

### PARTE V - SUPORTE
- [15. Troubleshooting](#15-troubleshooting)
- [16. Comandos Úteis](#16-comandos-úteis)
- [17. Checklist de Segurança](#17-checklist-de-segurança)

---

## 1. INTRODUÇÃO

### 🎯 O Que Este Sistema Faz

Este sistema oferece uma **interface centralizada** para gerenciar:

| Aspecto | Descrição |
|---------|-----------|
| **Backups** | Coolify completo, bancos de dados, volumes Docker |
| **Manutenção** | Atualizações, limpeza de recursos, verificação de saúde |
| **Migração** | Transferência completa entre servidores |
| **Configuração** | Firewall, cron jobs, variáveis de ambiente |
| **Monitoramento** | Status do sistema, logs, diagnóstico |

### 📊 Infraestrutura Protegida

Seu sistema segue o padrão **Zero Trust** da Cloudflare:

```
┌─────────────────────────────────────────────┐
│ USUÁRIOS (com WARP + Email Auth)            │
└─────────────┬───────────────────────────────┘
              │ Cloudflare WARP
              ↓
┌─────────────────────────────────────────────┐
│ CLOUDFLARE GLOBAL NETWORK                   │
│ • Zero Trust Access                         │
│ • Tunnels (cloudflared)                     │
│ • CDN/WAF para apps públicas                │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────┴─────────┐
    ↓                   ↓
┌─────────────┐    ┌─────────────┐
│ VPS (Cloud) │    │ Homelab     │
│ 31.97.23.42 │    │ 192.168.31  │
└─────────────┘    └─────────────┘
```

### 🔐 Firewall (UFW) - Sua Configuração

```
Status: active
Logging: on (low)
Default: deny incoming, allow outgoing

╔════════════════════════════════════════════════════════════╗
║ PORTAS ABERTAS                                             ║
╠════════════════════════════════════════════════════════════╣
║ 80/tcp (HTTP)       → PÚBLICO (Qualquer IP)               ║
║ 443/tcp (HTTPS)     → PÚBLICO (Qualquer IP)               ║
║ 22 SSH              → LOCALHOST (127.0.0.1)               ║
║ 22 SSH              → LAN LOCAL (192.168.31.0/24)         ║
║ 22 SSH              → DOCKER (10.0.0.0/8)                 ║
║ Loopback (lo)       → PERMITIDO (Cloudflare Tunnel)       ║
╠════════════════════════════════════════════════════════════╣
║ TUDO MAIS           → BLOQUEADO                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## 2. ARQUITETURA DO SISTEMA

### 📁 Estrutura de Diretórios

```
manutencao_backup_vps/
├── menu-principal.sh                 ← Interface centralizada
├── instalar.sh                        ← Instalação
│
├── backup/                            ← Scripts de backup (7)
│   ├── backup-coolify.sh              • Coolify completo
│   ├── backup-databases.sh            • PostgreSQL, MySQL, MongoDB
│   ├── backup-destinos.sh             • Enviar para S3, FTP, rsync
│   ├── backup-volume-interativo.sh    • Volume Docker específico
│   ├── backup-volume.sh               • Volume simples
│   ├── restaurar-coolify-remoto.sh    • Restaurar de backup remoto
│   └── restaurar-volume-interativo.sh • Restaurar volume específico
│
├── manutencao/                        ← Scripts de manutenção (4 + Firewall)
│   ├── manutencao-completa.sh         • Atualizar, limpar, verificar
│   ├── alerta-disco.sh                • Monitorar espaço
│   ├── configurar-updates-automaticos.sh • unattended-upgrades
│   ├── firewall-perfil-padrao.sh         • Firewall assistente
│   └── firewall-perfil-padrao.sh      • Firewall modo rápido
│
├── migrar/                            ← Scripts de migração (3)
│   ├── migrar-coolify.sh              • Instalação completa
│   ├── migrar-volumes.sh              • Volumes Docker
│   └── transferir-backups.sh          • Entre servidores
│
├── scripts-auxiliares/                ← Utilities (4)
│   ├── verificar-saude-completa.sh    • 17 seções, score 0-100
│   ├── verificar-saude-completa.sh             • Resumo rápido
│   ├── test-sistema.sh                • Testes funcionais
│   └── configurar-cron.sh             • Agendar tarefas
│
├── config/                            ← Configurações
│   ├── config.env                     • Variáveis de ambiente
│   └── crontab-exemplo.txt            • Exemplo de cron jobs
│
└── docs/                              ← Documentação
    ├── GUIA-FIREWALL.md               • Firewall detalhado
    ├── ESTRUTURA-MENU.md              • Menu detalhado
    ├── GUIA-COMPLETO-INFRAESTRUTURA-SEGURA.md
    └── MANUAL-COMPLETO-DO-SISTEMA.md  ← Este arquivo
```

### 🔄 Fluxo de Trabalho

```
1. EXECUÇÃO
   User → menu-principal.sh

2. SELEÇÃO
   Choose → Categoria (Status, Backup, Manutenção, etc)

3. SUBMENU
   Choose → Ação específica (ex: "Backup Coolify")

4. VALIDAÇÃO
   Script → Verifica permissões, configurações, pré-requisitos

5. CONFIRMAÇÃO
   User → Confirma (operações críticas têm confirmação extra)

6. EXECUÇÃO
   Script → Roda com logging automático

7. RESULTADO
   Output → Mostra resultado + código de saída

8. LOG
   Registra → /var/log/manutencao/menu-execucoes.log
```

---

## 3. COMPONENTES PRINCIPAIS

### 📊 Funções Auxiliares (Utilities)

Todas as funções abaixo são reutilizáveis em qualquer script:

#### `log_execution(mensagem)`
**Arquivo:** menu-principal.sh, linha 33-39
**O que faz:** Registra execução com timestamp
**Formato do log:** `[2025-11-13 15:30:45] INÍCIO: Backup Coolify`
**Localização:** `/var/log/manutencao/menu-execucoes.log`
**Exemplo:**
```bash
log_execution "INÍCIO: Backup Coolify"
log_execution "SUCESSO: Backup concluído"
log_execution "ERRO: Falha no backup (código: 1)"
```

#### `run_script(script_path, script_name)`
**Arquivo:** menu-principal.sh, linha 129-185
**O que faz:** Executa script com validações completas
**Responsabilidades:**
1. Verifica se script existe
2. Verifica/corrige permissão (chmod +x)
3. Loga início
4. Executa
5. Captura código de retorno
6. Loga resultado
7. Aguarda usuário (pause)
**Retorna:** Código de saída do script
**Exemplo:**
```bash
run_script "$SCRIPT_DIR/backup/backup-coolify.sh" "Backup Coolify"
```

#### `confirm(mensagem)`
**Arquivo:** menu-principal.sh, linha 58-73
**O que faz:** Confirmação simples (s/N)
**Retorna:** 0 (sim), 1 (não)
**Uso:** Operações normais
**Diferença:** `confirm_critical()` é para operações destrutivasExemplo:**
```bash
if confirm "Executar backup?"; then
    run_script ... "Backup"
fi
```

#### `confirm_critical(title, description, impacts, recommendations)`
**Arquivo:** menu-principal.sh, linha 75-127
**O que faz:** Confirmação DETALHADA para operações críticas
**Requer:** Usuário digitar "SIM" em MAIÚSCULAS
**Exibe:**
- Título em vermelho
- Descrição completa
- Impactos esperados
- Recomendações de segurança
**Uso:** Restauração, migração, reset de firewall
**Exemplo:**
```bash
if confirm_critical \
    "RESTAURAR BACKUP REMOTO" \
    "Isto vai SOBRESCREVER todos os dados do Coolify..." \
    "⚠ Todos os dados serão perdidos..." \
    "1. Faça backup antes..."; then
    run_script ... "Restaurar"
fi
```

#### `clear_screen()`
**Arquivo:** menu-principal.sh, linha 41-46
**O que faz:** Limpa terminal
**Uso:** Antes de exibir novo menu

#### `pause()`
**Arquivo:** menu-principal.sh, linha 48-56
**O que faz:** Aguarda ENTER do usuário
**Uso:** Permite ler output antes de voltar ao menu

#### `print_header()`
**Arquivo:** menu-principal.sh, linha 187-205
**O que faz:** Exibe cabeçalho padronizado
**Mostra:** Logo, caminho, hostname, data/hora

---

## 4. COMO USAR O MENU PRINCIPAL

### 🚀 Iniciando

```bash
# Via menu principal
sudo ./menu-principal.sh

# Direto um submenu (exemplo)
sudo ./menu-principal.sh 1  # Status

# Direto um script (não recomendado)
sudo bash backup/backup-coolify.sh
```

### 📋 Navegação Principal

```
╔════════════════════════════════════════════════════════════╗
║           🚀 MENU PRINCIPAL - GERENCIAMENTO VPS 🚀        ║
╚════════════════════════════════════════════════════════════╝

📍 Localização: /home/deyvid/Repositories/manutencao_backup_vps
🖥️  Servidor: agilytech
📅 Data/Hora: 13/11/2025 15:30:00

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MENU PRINCIPAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1 → 📊 Status e Diagnóstico
  2 → 💾 Backups
  3 → 🔧 Manutenção
  4 → 🚚 Migração
  5 → ⚙️  Configuração
  6 → 📚 Documentação

  7 → 📜 Ver Logs de Execução
  0 → 🚪 Sair

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Escolha uma opção: _
```

### ⌚ Tempo Estimado por Operação

| Operação | Tempo | Nota |
|----------|-------|------|
| Status Rápido | 5-10s | Menu 1, Opção 2 |
| Verificação Saúde | 30-60s | Menu 1, Opção 1 |
| Backup Coolify | 5-20 min | Menu 2, Opção 1 (depende do tamanho) |
| Backup BD | 2-10 min | Menu 2, Opção 2 |
| Manutenção Completa | 10-30 min | Menu 3, Opção 1 |
| Reset Firewall | 1-2 min | Menu 5, Opção 3 |

---

## 5. SUBMENUS DISPONÍVEIS

### Submenu 1: STATUS E DIAGNÓSTICO (Menu → 1)

```
📊 STATUS E DIAGNÓSTICO
  1 → 🏥 Verificação de Saúde Completa
       (17 seções, score 0-100, recomendações)
  2 → 📋 Status Resumido
       (Visão rápida: disco, memória, Docker, Coolify)
  3 → 🧪 Teste do Sistema
       (Verificar funcionalidades básicas)
  0 → ↩️  Voltar ao Menu Principal
```

**Script: verificar-saude-completa.sh**
- 17 seções analisadas
- Score geral 0-100
- Recomendações personalizadas
- Identifica problemas
**Quando usar:** Diagnóstico completo do sistema
**Tempo:** ~30-60 segundos

**Script: verificar-saude-completa.sh**
- Resumo rápido
- Informações principais
- Sem detalhes profundos
**Quando usar:** Verificação rápida do status
**Tempo:** ~5-10 segundos

**Script: test-sistema.sh**
- Testa instalação
- Verifica scripts
- Testa conectividade
- Valida configuração
**Quando usar:** Após instalação ou alterações
**Tempo:** ~10-20 segundos

---

### Submenu 2: BACKUPS (Menu → 2)

```
💾 BACKUPS

CRIAR BACKUPS:
  1 → 📦 Backup Completo do Coolify
       (Configurações, volumes, bancos de dados)
  2 → 🗄️  Backup de Bancos de Dados
       (PostgreSQL, MySQL, MongoDB)
  3 → 📁 Backup de Volume Específico (Interativo)
       (Escolher volume Docker manualmente)
  4 → 📤 Enviar Backups para Destinos Remotos
       (S3, FTP, SFTP, rsync)

RESTAURAR BACKUPS:
  5 → 📥 Restaurar Coolify de Backup Remoto
       (⚠️ CRÍTICO - Sobrescreve tudo)
  6 → 🔄 Restaurar Volume Específico (Interativo)
       (⚠️ CRÍTICO - Sobrescreve volume)

  0 → ↩️  Voltar
```

**Confirmações:** - Opção 1-4: `confirm()` simples
- Opção 5-6: `confirm_critical()` com detalhes

**Estrutura de Diretórios de Backup:**
```
/root/
├── coolify-backups/           (Backup Coolify completo)
├── database-backups/          (Backups de BD)
├── volume-backups/            (Backups de volumes)
└── backups-remotos/           (Sincronizados com remote)
```

---

### Submenu 3: MANUTENÇÃO (Menu → 3)

```
🔧 MANUTENÇÃO

  1 → 🔄 Manutenção Completa
       (Atualizar sistema, limpar Docker, verificar saúde)
  2 → ⚠️  Verificar Alerta de Disco
       (Checar uso de disco e alertar se necessário)
  3 → 🆙 Configurar Updates Automáticos
       (Instalar e configurar unattended-upgrades)
  4 → 🧹 Limpeza Manual do Docker
       (Remover imagens, containers, volumes não usados - ⚠️ CRÍTICO)
  5 → 🔄 Reiniciar Serviços Essenciais
       (Docker, Cloudflared, UFW)

  0 → ↩️  Voltar
```

**Opção 1: Manutenção Completa**
- Atualizar sistema (`apt update && apt upgrade`)
- Limpar Docker (`docker system prune -a`)
- Verificar saúde (rodar verificar-saude-completa.sh)
- Tempo: ~15-30 minutos
- Confirmação: Simples (s/N)

**Opção 2: Alerta de Disco**
- Verifica uso de disco da partição /
- Se > 80%: envia alerta (email se configurado)
- Se < 80%: tudo OK
- Tempo: ~5 segundos
- Confirmação: Nenhuma

**Opção 3: Updates Automáticos**
- Instala `unattended-upgrades`
- Configura para atualizar automaticamente
- Evita downtime de manutenção
- Confirmação: Simples (s/N)

**Opção 4: Limpeza Docker** ⚠️
- Remove imagens não usadas
- Remove containers parados
- Remove volumes órfãos
- Remove cache de build
- ⚠️ CONFIRMAÇÃO CRÍTICA (requer "SIM" em maiúsculas)
- Impacto: Libera espaço em disco significativo
- Comando: `docker system prune -a --volumes`

**Opção 5: Reiniciar Serviços**
- Reinicia: Docker, Cloudflared (se instalado), UFW
- Tempo: ~10 segundos
- Confirmação: Simples (s/N)

---

### Submenu 4: MIGRAÇÃO (Menu → 4)

```
🚚 MIGRAÇÃO

  ⚠️  ATENÇÃO: Operações de migração são CRÍTICAS!
      Certifique-se de ter backups antes de prosseguir.

  1 → 🚀 Migrar Coolify Completo
       (Migrar instalação completa do Coolify)
  2 → 📦 Migrar Volumes Docker
       (Transferir volumes entre servidores)
  3 → 📤 Transferir Backups Entre Servidores
       (Copiar backups via rsync/scp)

  0 → ↩️  Voltar
```

Todas as operações de migração requerem `confirm_critical()`.

**⚠️ AVISOS IMPORTANTES:**
- Downtime total: 30 minutos a 2 horas
- Requer acesso SSH remoto
- Plano de rollback obrigatório
- Backup prévio OBRIGATÓRIO

---

### Submenu 5: CONFIGURAÇÃO (Menu → 5)

```
⚙️  CONFIGURAÇÃO

  1 → ⏰ Configurar Tarefas Agendadas (Cron)
       (Agendar backups e manutenções automáticas)
  2 → 📝 Editar Configurações (config.env)
       (Editar variáveis de ambiente)
  3 → 🛡️  Configurar Firewall (UFW)
       (Modo Rápido + Assistente)
  4 → 🔐 Configurar Cloudflare Tunnel
       (Instalar e configurar cloudflared)
  5 → 📋 Mostrar Configurações Atuais
       (Exibir cron jobs, config.env, portas)

  0 → ↩️  Voltar
```

---

## 6. STATUS E DIAGNÓSTICO

### Menu → 1 → 1: Verificação de Saúde Completa

**Script:** `scripts-auxiliares/verificar-saude-completa.sh`

Analisa 17 seções do sistema:

1. **Sistema Operacional**
   - Versão Linux
   - Uptime
   - Carga do sistema

2. **Recursos de Hardware**
   - CPU (cores, modelo)
   - Memória RAM
   - Disco (espaço livre)

3. **Rede**
   - Conectividade internet
   - DNS resolution
   - Firewall (UFW)

4. **Docker**
   - Status
   - Versão
   - Containers rodando
   - Volumes

5. **Coolify**
   - Status
   - Containers
   - Volumes

6. **Bancos de Dados**
   - PostgreSQL
   - MySQL
   - MongoDB

7. **Cloudflare**
   - Tunnel status
   - Certificates

8. **Segurança**
   - SSH configurado
   - Firewall rules
   - Updates pendentes

9. **Armazenamento**
   - Backups recentes
   - Espaço disponível

10. **Certificados SSL**
    - Validade
    - Próxima renovação

E mais 7 seções...

**Output:** Score 0-100 com recomendações personalizadas

---

## 7. BACKUPS

### Menu → 2 → 1: Backup Coolify Completo

**Script:** `backup/backup-coolify.sh`

Faz backup de:
- Configurações do Coolify
- Todos os volumes Docker
- Todos os bancos de dados
- Certificados SSL

**Localização:** `/root/coolify-backups/`
**Formato:** `coolify-backup-YYYYMMDD_HHMMSS.tar.gz`
**Tamanho típico:** 1-10 GB (depende dos dados)
**Tempo:** 5-20 minutos
**Confirmação:** Simples (s/N)

**Como usar:**
```bash
# Via Menu
Menu → 2 → 1 → Confirma

# Direto
sudo bash backup/backup-coolify.sh

# Restaurar depois
Menu → 2 → 5 (restaurar de backup remoto)
```

### Menu → 2 → 2: Backup de Bancos de Dados

**Script:** `backup/backup-databases.sh`

Faz backup de:
- PostgreSQL
- MySQL
- MongoDB

**Localização:** `/root/database-backups/`
**Formato:** `{db}-backup-YYYYMMDD_HHMMSS.sql.gz`
**Tempo:** 2-10 minutos
**Confirmação:** Simples (s/N)

### Menu → 2 → 3: Backup de Volume Específico

**Script:** `backup/backup-volume-interativo.sh`

Permite escolher qual volume Docker fazer backup.

**Processo:**
1. Script lista volumes disponíveis
2. Você escolhe qual fazer backup
3. Script cria backup comprimido

**Localização:** `/root/volume-backups/`
**Tempo:** Depende do tamanho do volume

### Menu → 2 → 4: Enviar Backups para Destinos Remotos

**Script:** `backup/backup-destinos.sh`

Suporta:
- **S3:** Amazon S3, Minio, etc
- **FTP:** FTP tradicional
- **SFTP:** FTP seguro
- **rsync:** Sincronização com outro servidor

**Configuração:** Editada via `config/config.env`

---

## 8. MANUTENÇÃO

### Menu → 3 → 1: Manutenção Completa

**Script:** `manutencao/manutencao-completa.sh`

Executa em sequência:
1. `apt update && apt upgrade` (atualizar sistema)
2. `docker system prune -a` (limpar Docker)
3. `verificar-saude-completa.sh` (verificar saúde)

**Tempo:** 15-30 minutos
**Confirmação:** Simples (s/N)
**Downtime:** Mínimo (apenas reinicializações de serviços)

### Menu → 3 → 2: Alerta de Disco

**Script:** `manutencao/alerta-disco.sh`

**Configuração:**
- Limite padrão: 80% de uso
- Email: configurável via `$EMAIL_NOTIFICACAO`

**Verificação:**
```bash
# Via Menu
Menu → 3 → 2

# Direto
sudo bash manutencao/alerta-disco.sh

# Configurar email (opcional)
export EMAIL_NOTIFICACAO="seu-email@exemplo.com"
sudo bash manutencao/alerta-disco.sh
```

### Menu → 3 → 3: Configurar Updates Automáticos

**Script:** `manutencao/configurar-updates-automaticos.sh`

Instala e configura `unattended-upgrades` com as seguintes funcionalidades:

**Funcionalidades Principais:**
- ✅ Atualiza automaticamente (segurança + regulares, configurável)
- ✅ Reboot automático se necessário (horário configurável)
- ✅ Criação automática de logs de atualização
- ✅ **Detecção automática de Coolify** - protege Docker contra updates
- ✅ Notificações por email (opcional)
- ✅ Limpeza automática de dependências não usadas
- ✅ Backup automático da configuração original

**Como usar:**
```bash
sudo /manutencao/configurar-updates-automaticos.sh
# O script solicitará:
# 1. Incluir updates regulares? (y/N)
# 2. Reiniciar automaticamente? (y/N)
# 3. Horário para reinício (padrão: 03:00)
# 4. Email para notificações (opcional)
```

**Proteção de Docker (Coolify):**
- Se Coolify for detectado, Docker será **automaticamente adicionado à blacklist**
- Motivo: Updates de Docker podem causar downtime
- Docker será mantido na blacklist até você removê-lo manualmente
- **Recomendação:** Teste updates de Docker em staging antes de aplicar em produção

**Após instalação:**
- Verificar logs: `tail -f /var/log/unattended-upgrades/unattended-upgrades.log`
- Editar configuração: `sudo nano /etc/apt/apt.conf.d/50unattended-upgrades`
- Testar manualmente: `sudo unattended-upgrade --dry-run --debug`
- Restaurar backup se necessário: `sudo cp /etc/apt/apt.conf.d/50unattended-upgrades.bak /etc/apt/apt.conf.d/50unattended-upgrades`

### Menu → 3 → 4: Limpeza Docker ⚠️

**Comando:** `docker system prune -a --volumes`

**O que remove:**
- ❌ Imagens não associadas a containers
- ❌ Containers parados
- ❌ Redes não utilizadas
- ❌ Volumes órfãos
- ❌ Cache de build

**O que NÃO remove:**
- ✅ Containers em execução
- ✅ Volumes em uso
- ✅ Dados de produção

**⚠️ CONFIRMAÇÃO CRÍTICA NECESSÁRIA**

---

## 9. MIGRAÇÃO

### Menu → 4 → 1: Migrar Coolify Completo ⚠️

**Script:** `migrar/migrar-coolify.sh`

**Processo:**
1. Criar backup completo do Coolify atual
2. Parar todos os serviços
3. Transferir dados para novo servidor
4. Configurar Coolify no novo servidor
5. Verificar integridade

**⚠️ OPERAÇÃO EXTREMAMENTE CRÍTICA:**
- Downtime total: 30 min - 2 horas
- Todos os dados transferidos
- Certificados SSL reconfigurados necessário
- DNS pode precisar atualização

**Requer:**
- Backup prévio em local seguro
- Acesso SSH ao servidor destino
- Espaço suficiente em ambos
- Plano de rollback

**Confirmação:** `confirm_critical()` com 4 parâmetros

---

## 10. CONFIGURAÇÃO

### Menu → 5 → 1: Configurar Cron Jobs

**Script:** `scripts-auxiliares/configurar-cron.sh`

Permite agendar:
- Backups automáticos (horários personalizados)
- Manutenção automática (diária, semanal, mensal)
- Verificação de saúde (alertas)
- Alerta de disco (monitoramento)

**Exemplo de cron job:**
```bash
# Backup diário às 2 da manhã
0 2 * * * /opt/manutencao/backup-coolify.sh

# Manutenção completa toda semana (domingo às 3 AM)
0 3 * * 0 /opt/manutencao/manutencao-completa.sh

# Verificação de saúde diária às 8 AM
0 8 * * * /opt/manutencao/verificar-saude-completa.sh
```

**Ver cron jobs configurados:**
```bash
# Via Menu
Menu → 5 → 5 (mostrar configurações)

# Direto
crontab -l
```

### Menu → 5 → 2: Editar Configurações (config.env)

**Arquivo:** `config/config.env`

Contém variáveis de ambiente:
- Email para alertas
- Credenciais S3
- Configurações de backup
- etc

**Como editar:**
```bash
# Via Menu (abre editor nano)
Menu → 5 → 2

# Direto
sudo nano config/config.env
```

---

## 11. FIREWALL (UFW)

### Menu → 5 → 3: Configurar Firewall

**Submenu Firewall:**
```
🛡️  CONFIGURAÇÃO DE FIREWALL (UFW)

  1 → ⚡ Modo Rápido (Perfil Padrão)
       (Você digita sua rede LAN, resto é automático)
  2 → 🔧 Modo Assistente (Configuração Personalizada)
       (Detecta sua rede e permite customização)
  3 → 📊 Ver Status Atual
       (Mostra configuração do firewall agora)
  0 → ↩️  Voltar
```

### Modo Rápido: firewall-perfil-padrao.sh

**Você digita:** Seus 3 primeiros octetos de rede
**Exemplo:** Se seu IP é 192.168.31.105, você digita: `192.168.31`

**Resultado:**
```
SSH Permitido De:
  • 127.0.0.1         (Localhost)
  • 192.168.31.0/24   (Sua LAN)
  • 10.0.0.0/8        (Docker networks)

HTTP/HTTPS: PÚBLICO
Tudo mais: BLOQUEADO
```

**⚠️ Confirmação crítica necessária**

### Modo Assistente: firewall-perfil-padrao.sh

**Oferece:**
- Detecção automática de rede
- Suporte a múltiplas LANs
- Instruções passo a passo
- Testes de conectividade

**Use se:**
- Tem múltiplas redes LAN
- Está atrás de CGNAT
- Quer customizações avançadas

### Ver Status: `ufw status verbose`

```bash
# Via Menu
Menu → 5 → 3 → 3

# Direto
sudo ufw status verbose
sudo ufw status numbered  # Com números para deletar
```

---

## 12. ESTRUTURA DE FUNÇÕES

### Padrão show_xxx_menu() → handle_xxx_menu()

Cada submenu segue este padrão:

```bash
# 1. EXIBIR MENU
show_xxx_menu() {
    print_header
    echo -e "Opções do submenu..."
}

# 2. PROCESSAR ENTRADA
handle_xxx_menu() {
    while true; do
        show_xxx_menu
        read -r option
        case $option in
            1) run_script ... "Descrição" ;;
            2) run_script ... "Descrição" ;;
            0) return ;;
        esac
    done
}

# 3. INTEGRAR NO MENU PRINCIPAL
main() {
    ...
    case $option in
        X) handle_xxx_menu ;;
    esac
    ...
}
```

**Benefícios:**
- ✅ Fácil adicionar novas opções (3 linhas)
- ✅ Padrão consistente
- ✅ Escalável
- ✅ Reutilizável

---

## 13. LOGGING E MONITORAMENTO

### Arquivo de Logs

**Localização:** `/var/log/manutencao/menu-execucoes.log`

**Formato:**
```
[2025-11-13 15:30:45] INÍCIO: Backup Completo do Coolify
[2025-11-13 15:35:20] SUCESSO: Backup Completo do Coolify
[2025-11-13 16:00:00] ERRO: Teste do Sistema (código: 1)
```

**Como visualizar:**
```bash
# Últimas 30 linhas
tail -30 /var/log/manutencao/menu-execucoes.log

# Monitorar em tempo real
tail -f /var/log/manutencao/menu-execucoes.log

# Ver apenas erros
grep "ERRO" /var/log/manutencao/menu-execucoes.log

# Via Menu
Menu → 7
```

### Monitoramento Contínuo

**Backup:**
```bash
# Ver tamanho dos backups
du -sh /root/*/

# Backups recentes
ls -lh /root/coolify-backups/ | tail -10
```

**Sistema:**
```bash
# Espaço em disco
df -h

# Processos Docker
docker ps -a

# Status do firewall
sudo ufw status
```

---

## 14. SEGURANÇA E BOAS PRÁTICAS

### ✅ Checklist de Segurança

- [ ] UFW ativado e configurado
- [ ] SSH restrito (não exposto públicamente)
- [ ] Cloudflare WARP configurado para acesso remoto
- [ ] Backups automatizados via cron
- [ ] Updates automáticos habilitados
- [ ] Certificados SSL válidos
- [ ] Logs sendo monitorados
- [ ] Passwords fortes para bancos de dados

### 🔐 Configuração de Firewall Recomendada

```
┌─────────────────────────────────────────────┐
│ SEU FIREWALL ESTÁ CONFIGURADO ASSIM:        │
├─────────────────────────────────────────────┤
│ HTTP/HTTPS (80/443):  ✅ PÚBLICO            │
│ SSH (22):             ✅ RESTRITO           │
│   • 127.0.0.1 (localhost)                   │
│   • 192.168.31.0/24 (sua LAN)               │
│   • 10.0.0.0/8 (Docker/Coolify)             │
│ Loopback:             ✅ PERMITIDO          │
│   (Necessário para Cloudflare Tunnel)       │
│                                              │
│ TUDO MAIS:            ❌ BLOQUEADO          │
└─────────────────────────────────────────────┘
```

### 🚨 Operações Críticas

Requerem `confirm_critical()`:
- ❌ Restaurar backup remoto
- ❌ Restaurar volume específico
- ❌ Limpeza completa do Docker
- ❌ Migração de Coolify
- ❌ Reset de firewall

**Por que críticas?**
- Perda de dados possível
- Downtime potencial
- Reconfiguração necessária
- Sem undo/rollback fácil

### 📝 Recomendações

1. **Sempre faça backup antes de:**
   - Restaurar dados
   - Fazer migração
   - Resetar firewall
   - Fazer clean no Docker

2. **Mantenha Cloudflare Tunnel como backup:**
   - SSH restrito não afeta tunnel
   - Acesso remoto sempre disponível
   - Escape hatch em caso de erro de firewall

3. **Monitore regularmente:**
   - Espaço em disco
   - Saúde do sistema
   - Logs de erro
   - Certificados SSL

4. **Gerenciamento de Updates (especialmente importante com Coolify):**
   - ⚠️  **Docker está protegido** pela blacklist automática (se Coolify detectado)
   - Updates de Docker devem ser testados em staging primeiro
   - Atualize Docker manualmente quando necessário: `sudo apt update && sudo apt upgrade docker-ce docker-ce-cli containerd.io`
   - Sempre verifique compatibilidade de versões com suas aplicações
   - Mantenha logs de atualização para auditoria

5. **Procedimento seguro para atualizar Docker em produção:**
   ```bash
   # 1. Faça backup completo
   sudo bash /backup/backup-coolify.sh

   # 2. Teste em staging (se tiver)
   # 3. Verifique logs de compatibilidade
   # 4. Remova temporariamente da blacklist
   sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
   # Comente: "docker-ce", "docker-ce-cli", "containerd.io"

   # 5. Atualize manualmente
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io

   # 6. Teste aplicações
   docker ps -a
   # ou
   coolify status

   # 7. Re-adicione à blacklist (recomendado)
   sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
   # Descomente as linhas de novo
   ```

---

## 15. TROUBLESHOOTING

### Problema: "SSH não está funcionando"

**Causas possíveis:**
1. Firewall bloqueando SSH
2. SSH não está rodando
3. IP não autorizado

**Solução:**
```bash
# Verificar firewall
sudo ufw status

# Se bloqueado, permitir
sudo ufw allow from 192.168.31.0/24 to any port 22

# Verificar se SSH está rodando
sudo systemctl status ssh

# Reiniciar SSH
sudo systemctl restart ssh
```

### Problema: "Não consigo acessar Cloudflare Tunnel"

**Causas possíveis:**
1. cloudflared não está rodando
2. Certificado expirado
3. Tunnel mal configurado

**Solução:**
```bash
# Verificar status
sudo systemctl status cloudflared

# Ver logs
sudo journalctl -u cloudflared -f

# Reiniciar
sudo systemctl restart cloudflared
```

### Problema: "Backup está falhando"

**Causas possíveis:**
1. Sem espaço em disco
2. Permissões insuficientes
3. Docker não está rodando

**Solução:**
```bash
# Verificar espaço
df -h

# Verificar Docker
sudo systemctl status docker
sudo docker ps

# Executar manualmente (via Menu)
Menu → 2 → 1
```

### Problema: "Updates falham"

**Causas possíveis:**
1. Conexão ruim
2. Repositório indisponível
3. Dependências quebradas

**Solução:**
```bash
# Tentar manual
sudo apt update
sudo apt dist-upgrade

# Se falhar, logs
cat /var/log/apt/term.log
```

---

## 16. COMANDOS ÚTEIS

### Gerenciamento de Scripts

```bash
# Validar sintaxe
bash -n menu-principal.sh
bash -n backup/backup-coolify.sh

# Executar diretamente
sudo bash backup/backup-coolify.sh
sudo bash scripts-auxiliares/verificar-saude-completa.sh

# Ver permissões
ls -la backup/*.sh
```

### Firewall

```bash
# Ver status
sudo ufw status
sudo ufw status verbose
sudo ufw status numbered

# Adicionar regra
sudo ufw allow from 192.168.1.0/24 to any port 22

# Remover regra
sudo ufw delete allow 22
sudo ufw delete 5  # Por número

# Reset
sudo ufw reset
sudo ufw enable
```

### Docker

```bash
# Ver containers
docker ps -a

# Ver volumes
docker volume ls

# Ver espaço usado
docker system df

# Limpeza
docker system prune -a --volumes

# Logs
docker logs <container_id>
```

### Backup

```bash
# Listar backups
ls -lh /root/coolify-backups/

# Tamanho dos backups
du -sh /root/*/

# Restaurar
tar -xzf /root/coolify-backups/backup.tar.gz -C /
```

### Cron

```bash
# Ver cron jobs
crontab -l

# Editar cron jobs
crontab -e

# Ver logs de cron
sudo grep CRON /var/log/syslog
```

---

## 17. CHECKLIST DE SEGURANÇA

### ✅ Antes de Produção

- [ ] Firewall configurado (Menu → 5 → 3)
- [ ] SSH restrito (não público)
- [ ] Backups testados (Menu → 2)
- [ ] Updates automáticos ativados (Menu → 3 → 3)
- [ ] Cron jobs agendados (Menu → 5 → 1)
- [ ] Cloudflare Tunnel funcionando
- [ ] Certificados SSL válidos
- [ ] Passwords alterados (padrão → seguro)

### ✅ Mensalmente

- [ ] Rodar verificação de saúde (Menu → 1 → 1)
- [ ] Revisar logs (Menu → 7)
- [ ] Testar restauração de backup (Menu → 2 → 5)
- [ ] Verificar espaço em disco (Menu → 1 → 2)
- [ ] Revisar alertas de segurança

### ✅ Anualmente

- [ ] Audit completo de segurança
- [ ] Revisar políticas de firewall
- [ ] Testar plano de disaster recovery
- [ ] Revisar certificados SSL
- [ ] Atualizar documentação

---

## 📞 RESUMO RÁPIDO

| Tarefa | Menu | Tempo |
|--------|------|-------|
| Ver status | 1 → 2 | 10s |
| Backup completo | 2 → 1 | 10-20 min |
| Manutenção | 3 → 1 | 15-30 min |
| Configurar firewall | 5 → 3 | 1-2 min |
| Ver logs | 7 | 5s |
| Verificar saúde | 1 → 1 | 30-60s |
| Restaurar backup | 2 → 5 | 5-30 min |

---

## 🎓 Próximos Passos

1. **Instalação:**
   ```bash
   sudo ./instalar.sh
   ```

2. **Primeira Verificação:**
   ```bash
   sudo ./menu-principal.sh
   Menu → 1 → 2  # Status rápido
   ```

3. **Configurar Backup:**
   ```bash
   Menu → 2 → 1  # Fazer primeiro backup
   ```

4. **Agendar Tarefas:**
   ```bash
   Menu → 5 → 1  # Configurar cron
   ```

5. **Testar Tudo:**
   ```bash
   Menu → 1 → 3  # Test sistema
   ```

---

**Documentação Atualizada:** 13 de Novembro de 2025
**Versão:** 1.0
**Compatibilidade:** Ubuntu 22.04/24.04, Debian 11/12
**Autor:** Sistema de Manutenção e Backup VPS
