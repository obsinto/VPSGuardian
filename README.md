# 🚀 Sistema de Manutenção e Backup VPS

> **Gerenciamento centralizado, seguro e automatizado para infraestrutura com Coolify + Docker + Cloudflare**

[![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)]()
[![Docker](https://img.shields.io/badge/Docker-Coolify-blue.svg)]()
[![Security](https://img.shields.io/badge/Security-Zero%20Trust-red.svg)]()

---

## 📋 Visão Geral

Um **sistema completo e profissional** para gerenciar backups, manutenção, segurança e migração de servidores VPS com Coolify e Docker. Interface intuitiva baseada em **menu interativo** com operações críticas protegidas.

```
┌─────────────────────────────────────────────────────┐
│  USUÁRIOS (WARP + Email Auth)                      │
└────────────────────┬────────────────────────────────┘
                     │ Zero Trust
                     ↓
┌─────────────────────────────────────────────────────┐
│  CLOUDFLARE GLOBAL NETWORK                         │
│  • Tunnels (cloudflared)                           │
│  • WAF/DDoS Protection                             │
└────────────────────┬────────────────────────────────┘
          ┌──────────┴──────────┐
          ↓                     ↓
    ┌─────────────┐       ┌──────────────┐
    │ VPS (Cloud) │       │ Homelab      │
    │ Coolify     │       │ Homelab      │
    └─────────────┘       └──────────────┘
```

---

## ✨ Características Principais

### 🛡️ **Segurança em Primeiro Lugar**
- ✅ UFW Firewall com Zero Trust (SSH restrito, HTTP/HTTPS público)
- ✅ Detecção automática de Coolify
- ✅ Proteção inteligente de Docker contra updates perigosos
- ✅ Operações críticas requerem confirmação dupla
- ✅ Logs centralizados e auditáveis

### 📦 **Backups Inteligentes**
- ✅ Backup completo do Coolify (Docker volumes + configs)
- ✅ Backup de bancos de dados (PostgreSQL, MySQL, MongoDB)
- ✅ Suporte múltiplos destinos (S3, FTP, SFTP, rsync)
- ✅ Restauração seletiva (banco específico, volume específico)
- ✅ Verificação automática de integridade

### 🔧 **Manutenção Automatizada**
- ✅ Updates automáticos com menu de seleção de pacotes
- ✅ Limpeza inteligente de Docker (volumes, imagens, networks)
- ✅ Monitoramento de saúde do sistema
- ✅ Alertas de disco cheio com notificações por email
- ✅ Cron jobs agendáveis via interface

### 🚀 **Migração Segura**
- ✅ Migração completa entre servidores
- ✅ Preservação de certificados SSL
- ✅ Verificação de integridade pós-migração
- ✅ Plano de rollback

### 🎮 **Interface Profissional**
- ✅ Menu centralizado e intuitivo
- ✅ Seleção interativa de pacotes (com checkboxes visuais)
- ✅ Feedback em tempo real de operações
- ✅ Cores e formatação clara
- ✅ Validação de entrada robusta

---

## 🏗️ Arquitetura

```
manutencao_backup_vps/
├── menu-principal.sh                    ← 🎯 PONTO DE ENTRADA
├── backup/                              ← Backups inteligentes
│   ├── backup-coolify.sh
│   ├── backup-volume.sh
│   ├── backup-database.sh
│   └── restaurar-*.sh
├── manutencao/                          ← Manutenção do sistema
│   ├── configurar-updates-automaticos.sh (⭐ Menu interativo!)
│   ├── alerta-disco.sh
│   ├── configurar-firewall.sh
│   └── firewall-perfil-padrao.sh       (⭐ Detecção Coolify!)
├── migrar/                              ← Migração segura
│   ├── migrar-coolify.sh
│   ├── migrar-dns.sh
│   └── verificar-integridade.sh
├── scripts-auxiliares/                  ← Utilitários
│   ├── test-sistema.sh
│   ├── configurar-cron.sh
│   └── gerar-relatorio.sh
└── docs/                                ← Documentação completa
    └── MANUAL-COMPLETO-DO-SISTEMA.md
```

---

## 🚀 Quick Start

### 1️⃣ Instalação Rápida
```bash
cd /opt
git clone <seu-repositorio> manutencao_backup_vps
cd manutencao_backup_vps
./instalador.sh
```

### 2️⃣ Executar o Sistema
```bash
# Comando global (disponível de qualquer lugar)
vps-guardian

# OU manualmente
cd /opt/manutencao_backup_vps
./menu-principal.sh
```

### 3️⃣ Navegue pelo Menu
```
╔════════════════════════════════════════════════════════════╗
║        MENU PRINCIPAL - Sistema de Backup e Manutenção    ║
╚════════════════════════════════════════════════════════════╝

1️⃣  Status e Diagnóstico
2️⃣  Backups
3️⃣  Manutenção
4️⃣  Migração
5️⃣  Configuração
6️⃣  Sair

Digite a opção desejada:
```

---

## 📚 Menu Completo

### 1️⃣ Status e Diagnóstico
- Ver status geral do sistema
- Verificar saúde de Coolify
- Monitorar espaço em disco
- Ver últimos logs

### 2️⃣ Backups
- **Backup completo** do Coolify
- **Backup de volumes** específicos
- **Backup de bancos** (PostgreSQL, MySQL, MongoDB)
- **Restaurar** backups (com verificação)
- **Listar** backups disponíveis

### 3️⃣ Manutenção
- **Manutenção completa** (updates, limpeza, etc.)
- **Limpeza de Docker** (com confirmação crítica)
- **Configurar updates automáticos** ⭐ (menu interativo de pacotes!)
- **Verificar saúde** do sistema

### 4️⃣ Migração ⚠️
- Migrar Coolify completo para nova VPS
- Migrar volumes Docker individuais
- Transferir backups entre servidores
- **Validação pré-migração** (checagem de requisitos)
- **Validação pós-migração** (verificação de sucesso)
- **Checklist interativo** (guia passo a passo)

📖 **[Guia Completo de Teste de Migração](docs/TESTE-MIGRACAO.md)**
⚡ **[Guia Rápido de Migração](docs/GUIA-RAPIDO-MIGRACAO.md)**

### 5️⃣ Configuração
- **Configurar firewall** (detecta Coolify, pede rede LAN)
- **Configurar cron jobs** (agendamentos)
- **Gerar relatório** de sistema

---

## 🎯 Exemplos de Uso

### Fazer Backup Completo
```bash
sudo bash menu-principal.sh
# Menu → 2 → 1: Backup Coolify Completo
# ou diretamente:
sudo bash backup/backup-coolify.sh
```

### Configurar Updates com Proteção de Docker
```bash
sudo bash menu-principal.sh
# Menu → 3 → 3: Configurar Updates Automáticos
# Aparece menu interativo para selecionar pacotes:
# [✓] Docker Engine
# [✓] Docker CLI
# [✓] Containerd
# [ ] PostgreSQL
# [ ] MySQL
# ...
```

### Restaurar Backup Específico
```bash
sudo bash menu-principal.sh
# Menu → 2 → 4: Restaurar Backup
# Mostra lista de backups disponíveis
# Pede confirmação crítica antes de restaurar
```

### Configurar Firewall Automático
```bash
sudo bash menu-principal.sh
# Menu → 5 → 1: Configurar Firewall
# Detecta se Coolify está instalado
# Pergunta qual é sua rede LAN (ex: 192.168.31)
# Configura: SSH restrito + HTTP/HTTPS público
```

### Agendar Backups Automáticos
```bash
sudo bash menu-principal.sh
# Menu → 5 → 2: Configurar Cron Jobs
# Escolher: Backup diário às 2h da manhã
# Escolher: Manutenção semanal aos domingos 3h
# Etc.
```

---

## 🧪 Teste de Migração com 100% de Confiança

### Passo 1: Validar Ambiente Antes da Migração

```bash
# Na VPS PRINCIPAL
vps-guardian
# → Scripts Auxiliares → Validar Pré-Migração

# OU diretamente:
./scripts-auxiliares/validar-pre-migracao.sh
```

**Verifica:**
- ✅ Sistema operacional e dependências
- ✅ Docker e containers do Coolify
- ✅ Banco de dados PostgreSQL
- ✅ Backups existentes e válidos
- ✅ SSH configurado
- ✅ Espaço em disco

### Passo 2: Executar Migração Completa

```bash
# Na VPS PRINCIPAL
./migrar/migrar-coolify.sh

# Informações solicitadas:
# - IP da VPS de destino
# - Usuário SSH (padrão: root)
# - Porta SSH (padrão: 22)
# - Selecionar backup para migrar
```

**O script faz automaticamente:**
1. Conecta via SSH na VPS destino
2. Instala Coolify
3. Transfere backup
4. Restaura banco de dados
5. Copia SSH keys e configurações
6. Atualiza variáveis de ambiente
7. Inicia todos os containers

### Passo 3: Validar Migração Completa

```bash
# Na VPS PRINCIPAL (validação remota)
./scripts-auxiliares/validar-pos-migracao.sh --remote [IP_VPS_DESTINO]

# OU na VPS DESTINO (validação local)
./scripts-auxiliares/validar-pos-migracao.sh
```

**Verifica:**
- ✅ Coolify instalado e rodando
- ✅ Todos os containers ativos
- ✅ Banco de dados restaurado
- ✅ Interface web acessível
- ✅ Configurações preservadas
- ✅ Logs sem erros críticos

### Checklist Interativo (Recomendado)

```bash
./scripts-auxiliares/checklist-migracao.sh
```

Interface interativa que guia você por cada etapa:
- Marca progresso automaticamente
- Sugere comandos para executar
- Valida cada passo
- Gera relatório final

**Modos disponíveis:**
1. **Migração completa** - Processo end-to-end
2. **Apenas pré-validação** - Checar se sistema está pronto
3. **Apenas pós-validação** - Verificar sucesso da migração

### Documentação Completa de Testes

📚 **[Guia Detalhado de Teste de Migração](docs/TESTE-MIGRACAO.md)**
- Infraestrutura de teste
- 8 fases de validação
- Troubleshooting completo
- Checklist final de 25+ itens

⚡ **[Guia Rápido (5 Passos)](docs/GUIA-RAPIDO-MIGRACAO.md)**
- Quick start em 5 minutos
- Comandos essenciais
- Troubleshooting rápido
- Critérios de sucesso

---

## 🔐 Segurança

### Configuração Padrão do Firewall
```
╔════════════════════════════════════════════════════════════╗
║ PORTAS ABERTAS                                             ║
╠════════════════════════════════════════════════════════════╣
║ 80/tcp (HTTP)       → PÚBLICO (Qualquer IP)               ║
║ 443/tcp (HTTPS)     → PÚBLICO (Qualquer IP)               ║
║ 22 SSH              → LOCALHOST (127.0.0.1)               ║
║ 22 SSH              → LAN LOCAL (192.168.31.0/24) *        ║
║ 22 SSH              → DOCKER (10.0.0.0/8)                 ║
║ Loopback (lo)       → PERMITIDO (Cloudflare Tunnel)       ║
╠════════════════════════════════════════════════════════════╣
║ TUDO MAIS           → BLOQUEADO                            ║
╚════════════════════════════════════════════════════════════╝
* Configurável durante setup
```

### Operações Críticas
Requerem confirmação adicional:
- ❌ Restaurar backup remoto
- ❌ Migração de Coolify
- ❌ Limpeza completa do Docker
- ❌ Reset de firewall

Validação:
```bash
# Operações críticas requerem digitar "SIM" em MAIÚSCULA
Tem CERTEZA? Digite "SIM" para confirmar: SIM
```

### Updates Inteligentes
- ✅ Docker **protegido por padrão** se Coolify detectado
- ✅ Menu interativo para escolher quais pacotes proteger
- ✅ Suporte a 15+ pacotes (Docker, PostgreSQL, MySQL, Nginx, etc.)
- ✅ **Escalável**: adicionar novo pacote = 1 linha no código

---

## 📊 Logging e Monitoramento

Todos os eventos são registrados em:
```bash
/var/log/manutencao/menu-execucoes.log
/var/log/manutencao/backup-execucoes.log
/var/log/unattended-upgrades/unattended-upgrades.log
```

Ver logs:
```bash
tail -f /var/log/manutencao/menu-execucoes.log
grep "ERROR" /var/log/manutencao/*.log
```

---

## 📖 Documentação Completa

Consulte o **[Manual Completo do Sistema](docs/MANUAL-COMPLETO-DO-SISTEMA.md)** para:
- Guia detalhado de cada função
- Screenshots e exemplos
- Troubleshooting
- Comandos úteis
- Checklist de segurança
- Procedimentos avançados

---

## 🛠️ Requisitos

- **OS**: Ubuntu/Debian (testado em 20.04, 22.04, 24.04)
- **Bash**: 5.0+
- **Docker**: 20.10+
- **Permissões**: root ou sudo sem senha configurado
- **Ferramentas**: curl, wget, tar, rsync, ufw

### Opcional
- **mailutils**: Para notificações por email
- **S3 CLI**: Para backups em S3
- **MongoDB Tools**: Para backup de MongoDB
- **Cloudflare Tunnel**: Para acesso remoto seguro

---

## 📥 Instalação Rápida

```bash
# 1. Clonar
git clone <seu-repositorio> /opt/manutencao_backup_vps
cd /opt/manutencao_backup_vps

# 2. Permissões
chmod +x menu-principal.sh
chmod +x backup/*.sh
chmod +x manutencao/*.sh
chmod +x migrar/*.sh
chmod +x scripts-auxiliares/*.sh

# 3. Configurar acesso sudo sem senha (OPCIONAL)
# sudo visudo
# Adicionar: seu-usuario ALL=(ALL) NOPASSWD: /opt/manutencao_backup_vps/*

# 4. Executar
sudo bash menu-principal.sh
```

---

## 🔄 Atualizações

O sistema é auto-contido. Para atualizar:

```bash
cd /opt/manutencao_backup_vps
git pull origin main
chmod +x **/*.sh
```

---

## 🤝 Contribuindo

Sugestões e melhorias são bem-vindas!

1. Fork do repositório
2. Crie uma branch (`git checkout -b feature/melhoria`)
3. Commit suas mudanças (`git commit -m 'Adicionar nova feature'`)
4. Push para a branch (`git push origin feature/melhoria`)
5. Abra um Pull Request

---

## 📋 Checklist de Setup Inicial

- [ ] Clonar repositório
- [ ] Dar permissões de execução
- [ ] Executar `sudo bash menu-principal.sh`
- [ ] Configurar firewall (Menu → 5 → 1)
- [ ] Testar conexão SSH
- [ ] Configurar backup automático (Menu → 5 → 2)
- [ ] Configurar updates automáticos (Menu → 3 → 3)
- [ ] Realizar teste de backup/restore
- [ ] Verificar logs (Menu → 1 → 4)
- [ ] Documentar configuração

---

## 🐛 Troubleshooting

### SSH não funciona após configurar firewall
```bash
# Via Cloudflare Tunnel ou console local:
sudo ufw allow from 192.168.31.0/24 to any port 22
sudo ufw reload
```

### Backup falha
```bash
# Verificar logs
tail -f /var/log/manutencao/backup-execucoes.log

# Verificar espaço
df -h

# Verificar permissões
ls -la /backup/
```

### Updates falhando
```bash
# Ver logs
cat /var/log/apt/term.log

# Solucionar manualmente
sudo apt update
sudo apt dist-upgrade
```

Veja [docs/MANUAL-COMPLETO-DO-SISTEMA.md](docs/MANUAL-COMPLETO-DO-SISTEMA.md#15-troubleshooting) para mais soluções.

---

## 📞 Suporte

- 📖 **Documentação**: Leia o [Manual Completo](docs/MANUAL-COMPLETO-DO-SISTEMA.md)
- 💬 **Issues**: Relate problemas no GitHub
- 🔗 **Cloudflare Tunnel**: Configure para acesso remoto seguro

---

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

---

## 🌟 Reconhecimentos

Desenvolvido com ❤️ para infraestrutura segura com:
- **Coolify** - Gerenciador de containers
- **Docker** - Containerização
- **Cloudflare** - Segurança e acesso remoto
- **UFW** - Firewall simples

---

## 📈 Roadmap

- [ ] Dashboard web para monitoramento
- [ ] Notificações Slack/Discord
- [ ] API REST para automação
- [ ] Backup incremental
- [ ] Suporte para Kubernetes
- [ ] Sincronização de múltiplos servidores

---

<div align="center">

### 🚀 Pronto para começar?

```bash
sudo bash menu-principal.sh
```

**Desenvolvido com paixão para infraestrutura em produção** 💙

Made with ❤️ for secure and reliable server management

</div>
