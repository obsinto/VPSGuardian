# 🛡️ VPS Guardian

> Sistema completo de backup, manutenção e migração para Coolify + Docker

[![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)]()

## 🚀 Quick Start

```bash
cd /opt && git clone <seu-repo> vpsguardian
cd vpsguardian && sudo ./instalar.sh
```

**Comando global instalado:** `vps-guardian`

## ✨ Principais Recursos

- **Backup Completo:** DB + SSH keys + configs + volumes
- **Backup S3:** Upload automático para AWS, Backblaze, Wasabi, MinIO
- **Migração Automatizada:** Mover Coolify entre servidores em 15-30min
- **Retenção Inteligente:** Estratégias Simple, Count e GFS
- **Manutenção:** Limpeza automática de disco, logs e Docker
- **Firewall Interativo:** Perfis de segurança (Seguro/Híbrido/Básico)

## 📦 Principais Scripts

### Backup
- `backup-coolify.sh` - Backup completo local
- `backup-coolify-s3.sh` - Backup + upload S3
- `backup-databases.sh` - Backup de DBs específicos
- `restaurar-coolify-remoto.sh` - Restauração automatizada

### Migração
- `migrar-coolify.sh` - Migração completa entre servidores
- `validar-pre-migracao.sh` - 30+ verificações pré-migração
- `validar-pos-migracao.sh` - 40+ verificações pós-migração

### Manutenção
- `manutencao-completa.sh` - Limpeza de logs, Docker, apt
- `verificar-saude-completa.sh` - Diagnóstico do sistema
- `limpar-backups-antigos.sh` - Gestão de retenção
- `firewall-interativo.sh` - Gerenciador de firewall UFW

## 🎯 Comandos Globais

```bash
vps-guardian              # Menu interativo
vps-guardian backup       # Backup local
vps-guardian backup-s3    # Backup para S3
vps-guardian migrate      # Migração
vps-guardian status       # Status do sistema
vps-guardian firewall     # Gerenciar firewall

# Aliases rápidos
backup-vps                # = vps-guardian backup
backup-s3-vps             # = vps-guardian backup-s3
firewall-vps              # = vps-guardian firewall
status-vps                # = vps-guardian status
```

## 📚 Documentação

- **[INSTALACAO.md](docs/INSTALACAO.md)** - Instalação e configuração
- **[GUIA-RAPIDO.md](docs/GUIA-RAPIDO.md)** - Comandos essenciais
- **[USO-SCRIPTS.md](docs/USO-SCRIPTS.md)** - Documentação completa dos scripts
- **[BACKUP-S3-GUIDE.md](docs/BACKUP-S3-GUIDE.md)** - Backup para S3
- **[RETENCAO-BACKUPS.md](docs/RETENCAO-BACKUPS.md)** - Gestão de retenção
- **[GUIA-MIGRACAO-COMPLETA.md](docs/GUIA-MIGRACAO-COMPLETA.md)** - Migração entre servidores
- **[FIREWALL-GUIDE.md](docs/FIREWALL-GUIDE.md)** - Configuração de firewall
- **[COMANDOS.md](docs/COMANDOS.md)** - Referência de comandos

## 🏗️ Arquitetura

```
/opt/vpsguardian/
├── backup/              # Scripts de backup/restauração
├── migrar/              # Scripts de migração
├── manutencao/          # Scripts de manutenção
├── scripts-auxiliares/  # Utilitários e validadores
├── lib/                 # Bibliotecas compartilhadas
│   ├── common.sh        # → Loader principal
│   ├── logging.sh       # → Logging padronizado
│   ├── colors.sh        # → Cores ANSI
│   └── validation.sh    # → 50+ funções de validação
├── config/              # Configurações
└── menu-principal.sh    # Menu interativo

/var/backups/vpsguardian/
├── coolify/             # Backups Coolify (tar.gz)
├── databases/           # Dumps SQL (sql.gz)
└── volumes/             # Backups volumes (tar.gz)

/var/log/vpsguardian/
└── *.log                # Logs estruturados
```

## 💡 Exemplos Rápidos

### Backup Diário Automático
```bash
sudo vps-guardian cron
# Selecionar: backup-coolify.sh
# Frequência: diária às 02:00
```

### Migrar para Novo Servidor
```bash
# No servidor antigo:
sudo vps-guardian backup
sudo vps-guardian migrate
# Seguir assistente interativo
```

### Configurar Firewall Seguro
```bash
sudo firewall-vps
# Selecionar perfil: Seguro (Cloudflare Tunnel)
```

### Backup para S3
```bash
sudo backup-s3-vps
# Modo interativo na primeira vez
# Automático nas próximas
```

## 🔒 Segurança

**Permissões:**
- `/opt/vpsguardian` → 755 (rwxr-xr-x)
- `/var/backups/vpsguardian` → 700 (rwx------) - **Apenas root**
- `/var/log/vpsguardian` → 755 (rwxr-xr-x)

**Backups contêm dados sensíveis:**
- APP_KEY do Coolify
- Chaves SSH privadas
- Credenciais de banco de dados

**⚠️ Nunca exponha `/var/backups/vpsguardian` publicamente!**

## 📊 Estatísticas

- **997 linhas** de bibliotecas compartilhadas
- **50+ funções** de validação reutilizáveis
- **20+ scripts** especializados
- **14 scripts** refatorados com padrão moderno
- **0 duplicações** de código

## 🛠️ Requisitos

- Ubuntu 20.04+ / Debian 11+
- Docker instalado
- Coolify instalado (opcional)
- Acesso root
- 10GB+ espaço disponível

## 📄 Licença

MIT License - veja [LICENSE](LICENSE)

---

**🛡️ VPS Guardian - Proteja seu servidor com confiança**

<div align="center">

**[📥 Instalação](docs/INSTALACAO.md)** • **[📖 Documentação](docs/USO-SCRIPTS.md)** • **[⚡ Guia Rápido](docs/GUIA-RAPIDO.md)**

</div>
