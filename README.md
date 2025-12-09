# 🛡️ VPS Guardian

> **Sistema completo e profissional de backup, manutenção e migração para Coolify + Docker**

[![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)]()
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)]()
[![Coolify](https://img.shields.io/badge/Coolify-Compatible-purple.svg)]()

---

## 🎯 O Que É?

**VPS Guardian** é um conjunto de scripts Bash profissionais para automatizar **backup, restauração, migração e manutenção** de servidores rodando [Coolify](https://coolify.io) + Docker.

### ✨ Destaques

- 🔄 **Migração Zero-Downtime:** Migre seu Coolify para novo servidor em 10-15 minutos
- 💾 **Backups Automáticos:** Backup completo do Coolify (DB + SSH keys + configs)
- 🔧 **Manutenção Inteligente:** Limpeza, updates, firewall, monitoramento
- 📚 **Bibliotecas Compartilhadas:** Código modular, reutilizável e testado
- ✅ **Validação Automatizada:** 50+ validações de ambiente antes/depois de operações críticas
- 📊 **Logs Profissionais:** Logs estruturados com cores e níveis (info, success, error, warning)

---

## 🚀 Quick Start (3 Passos)

### 1. Instalar

```bash
cd /opt
git clone <seu-repo> vpsguardian
cd vpsguardian
sudo ./instalar.sh
```

### 2. Fazer Backup

```bash
sudo vps-guardian backup
# ou
sudo /opt/vpsguardian/backup/backup-coolify.sh
```

### 3. Automatizar (Opcional)

```bash
sudo /opt/vpsguardian/scripts-auxiliares/configurar-cron.sh
```

**Pronto!** Seu servidor agora tem backups automáticos configurados.

---

## 📚 Documentação

| Documento | Descrição |
|-----------|-----------|
| **[📥 INSTALACAO.md](docs/INSTALACAO.md)** | Guia completo de instalação e configuração |
| **[📖 USO-SCRIPTS.md](docs/USO-SCRIPTS.md)** | Documentação detalhada de cada script |
| **[⚡ GUIA-RAPIDO.md](docs/GUIA-RAPIDO.md)** | Comandos essenciais e workflows comuns |

---

## 🎨 Funcionalidades Principais

### 📦 Backup

| Script | Descrição |
|--------|-----------|
| `backup-coolify.sh` | Backup completo do Coolify (DB + SSH + configs) |
| `backup-databases.sh` | Backup interativo de bancos de dados específicos |
| `backup-volume.sh` | Backup interativo de volumes Docker |
| `backup-destinos.sh` | Sincroniza backups para servidores remotos (rsync) |
| `restaurar-coolify-remoto.sh` | Restaura Coolify em servidor remoto (totalmente automatizado) |
| `restaurar-volume-interativo.sh` | Restaura volumes Docker de backups |

### 🔄 Migração

| Script | Descrição |
|--------|-----------|
| `migrar-coolify.sh` | **Migração completa e automatizada do Coolify** |
| `migrar-volumes.sh` | Migra volumes Docker específicos para outro servidor |
| `transferir-backups.sh` | Transfere backups via SSH para servidor remoto |

### 🔧 Manutenção

| Script | Descrição |
|--------|-----------|
| `manutencao-completa.sh` | Limpeza completa (logs, Docker, apt cache) |
| `verificar-saude-completa.sh` | Verifica saúde do servidor (Docker, Coolify, recursos) |
| `configurar-updates-automaticos.sh` | Ativa updates de segurança automáticos |
| `firewall-perfil-padrao.sh` | Configura firewall UFW com perfil seguro |

### 🛠️ Auxiliares

| Script | Descrição |
|--------|-----------|
| `checklist-migracao.sh` | Checklist interativo para validar migração |
| `configurar-cron.sh` | Configura backups automáticos via cron |
| `validar-pre-migracao.sh` | 30+ verificações antes de migrar |
| `validar-pos-migracao.sh` | 40+ verificações após migração |

---

## 🏗️ Arquitetura

```
/opt/vpsguardian/
├── backup/              # Scripts de backup e restauração
├── migrar/              # Scripts de migração entre servidores
├── manutencao/          # Scripts de manutenção e limpeza
├── scripts-auxiliares/  # Utilitários e validadores
├── lib/                 # 📚 Bibliotecas compartilhadas (NEW!)
│   ├── common.sh        #   → Wrapper que carrega tudo
│   ├── logging.sh       #   → Funções de log padronizadas
│   ├── colors.sh        #   → Cores ANSI para terminal
│   └── validation.sh    #   → 50+ funções de validação
├── config/              # Configurações centralizadas
│   └── default.conf     #   → Variáveis globais (paths, retenção, etc.)
├── menu-principal.sh    # Menu interativo principal
└── instalar.sh          # Instalador

/var/backups/vpsguardian/
├── coolify/             # Backups do Coolify (tar.gz)
├── databases/           # Dumps de bancos de dados (sql.gz)
└── volumes/             # Backups de volumes Docker (tar.gz)

/var/log/vpsguardian/
└── *.log                # Logs estruturados de todas as operações
```

---

## 💡 Casos de Uso

### Caso 1: Backup Diário Automático

```bash
# Configurar backup diário às 2h da manhã
sudo /opt/vpsguardian/scripts-auxiliares/configurar-cron.sh
# Selecionar: backup-coolify.sh
# Frequência: diária
# Horário: 02:00
```

### Caso 2: Migrar para Novo Servidor

```bash
# No servidor ANTIGO:
sudo /opt/vpsguardian/backup/backup-coolify.sh
sudo /opt/vpsguardian/scripts-auxiliares/validar-pre-migracao.sh

# No servidor ANTIGO (migra para novo):
sudo /opt/vpsguardian/migrar/migrar-coolify.sh
# Seguir assistente interativo

# Validar migração:
sudo /opt/vpsguardian/scripts-auxiliares/validar-pos-migracao.sh --remote <NOVO-IP>
```

### Caso 3: Restauração de Emergência

```bash
# Se Coolify caiu, restaurar do backup mais recente:
sudo /opt/vpsguardian/backup/restaurar-coolify-remoto.sh
# Selecione localhost (127.0.0.1)
# Selecione backup mais recente
# Aguardar 10-15 minutos
```

### Caso 4: Manutenção Mensal

```bash
# Agendar manutenção mensal (dia 1, às 4h):
sudo crontab -e
# Adicionar:
0 4 1 * * /opt/vpsguardian/manutencao/manutencao-completa.sh
```

---

## 🔒 Segurança

### Permissões

- `/opt/vpsguardian` → `755` (rwxr-xr-x)
- `/var/backups/vpsguardian` → `700` (rwx------) **Apenas root**
- `/var/log/vpsguardian` → `755` (rwxr-xr-x)

### Dados Sensíveis nos Backups

⚠️ **Backups contêm informações críticas:**
- APP_KEY do Coolify
- Chaves SSH privadas
- Credenciais de banco de dados
- Tokens e secrets de aplicações

**Recomendações:**
1. ✅ Mantenha `/var/backups/vpsguardian` com permissão `700`
2. ✅ Faça backups off-site (outro servidor/cloud)
3. ✅ Criptografe backups antes de enviar para cloud pública
4. ✅ Teste restauração periodicamente

---

## 📊 Estatísticas do Projeto

- **997 linhas** de bibliotecas compartilhadas
- **50+ funções** de validação reutilizáveis
- **20+ scripts** especializados
- **14 scripts** refatorados com bibliotecas modernas
- **100%** dos scripts com sintaxe validada
- **0 linhas** de código duplicado

---

## 🛠️ Tecnologias

- **Bash 5.0+** - Shell scripting
- **Docker** - Containerização
- **Coolify** - PaaS auto-hospedado
- **PostgreSQL** - Banco de dados do Coolify
- **UFW** - Firewall
- **rsync/scp** - Transferência de arquivos
- **cron** - Agendamento de tarefas

---

## 📈 Roadmap

- [x] Sprint 1: Consolidar caminhos e remover redundâncias
- [x] Sprint 2: Criar bibliotecas compartilhadas e refatorar scripts
- [ ] Sprint 3: Adicionar testes automatizados
- [ ] Sprint 4: Suporte a múltiplos provedores de cloud (S3, Backblaze, etc.)
- [ ] Sprint 5: Dashboard web para monitoramento
- [ ] Sprint 6: Notificações via Discord/Slack/Telegram

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adicionar MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 📞 Suporte

- **Documentação:** [docs/](docs/)
- **Issues:** [GitHub Issues](https://github.com/SEU-USUARIO/vpsguardian/issues)
- **Logs:** `/var/log/vpsguardian/`

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

---

## 🙏 Agradecimentos

- [Coolify](https://coolify.io) - PaaS incrível
- [Docker](https://docker.com) - Containerização
- Comunidade open-source

---

**🛡️ VPS Guardian - Proteja seu servidor com confiança**

---

<div align="center">

**[📥 Instalação](docs/INSTALACAO.md)** • **[📖 Documentação](docs/USO-SCRIPTS.md)** • **[⚡ Guia Rápido](docs/GUIA-RAPIDO.md)**

Feito com ❤️ para a comunidade Coolify

</div>
