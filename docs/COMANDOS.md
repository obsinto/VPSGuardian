# 🎯 Comandos Globais - VPS Guardian

Após instalação, você pode usar o VPS Guardian de **qualquer lugar** com comandos globais.

---

## 🚀 Comando Principal

### vps-guardian

**Uso:**
```bash
vps-guardian [comando]
```

**Sem argumentos = Menu Interativo:**
```bash
vps-guardian
# Abre menu principal com todas as opções
```

---

## 📋 Comandos Disponíveis

### Principais

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `vps-guardian` | Abre menu principal interativo | `vps-guardian` |
| `vps-guardian menu` | Abre menu principal (explícito) | `vps-guardian menu` |
| `vps-guardian backup` | Faz backup completo do Coolify | `sudo vps-guardian backup` |
| `vps-guardian migrate` | Migra Coolify para novo servidor | `sudo vps-guardian migrate` |
| `vps-guardian restore` | Restaura backup do Coolify | `sudo vps-guardian restore` |

### Manutenção

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `vps-guardian status` | Mostra status completo do sistema | `vps-guardian status` |
| `vps-guardian firewall` | Gerenciador interativo de firewall | `sudo vps-guardian firewall` |
| `vps-guardian maintenance` | Executa manutenção completa | `sudo vps-guardian maintenance` |
| `vps-guardian updates` | Configura updates automáticos | `sudo vps-guardian updates` |

### Configuração

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `vps-guardian cron` | Configura cron jobs para backups | `sudo vps-guardian cron` |
| `vps-guardian --help` | Mostra ajuda completa | `vps-guardian --help` |
| `vps-guardian --version` | Mostra versão instalada | `vps-guardian --version` |

---

## ⚡ Aliases Rápidos

Para facilitar, também foram criados aliases curtos:

| Alias | Equivalente | Uso |
|-------|-------------|-----|
| `firewall-vps` | `vps-guardian firewall` | `sudo firewall-vps` |
| `backup-vps` | `vps-guardian backup` | `sudo backup-vps` |
| `status-vps` | `vps-guardian status` | `status-vps` |

---

## 💡 Exemplos Práticos

### Backup Diário
```bash
# Fazer backup manualmente
sudo backup-vps

# Ou usar comando completo
sudo vps-guardian backup
```

### Configurar Firewall
```bash
# Abre menu interativo do firewall
sudo firewall-vps

# Ou usar comando completo
sudo vps-guardian firewall
```

### Ver Status do Sistema
```bash
# Mostra saúde do servidor
status-vps

# Ou usar comando completo
vps-guardian status
```

### Migrar para Novo Servidor
```bash
# Inicia processo de migração completo
sudo vps-guardian migrate

# Assistente interativo guia você no processo
```

### Restaurar Backup
```bash
# Restaura Coolify de um backup
sudo vps-guardian restore

# Lista backups disponíveis e restaura
```

### Manutenção Completa
```bash
# Limpa logs, Docker, apt cache
sudo vps-guardian maintenance
```

### Configurar Updates Automáticos
```bash
# Ativa updates de segurança automáticos
sudo vps-guardian updates
```

### Configurar Backups Automáticos
```bash
# Configura cron jobs interativamente
sudo vps-guardian cron
```

---

## 🔧 Comandos Avançados

### Ver Ajuda Completa
```bash
vps-guardian --help

# Mostra:
# - Todos os comandos disponíveis
# - Descrição de cada um
# - Exemplos de uso
# - Aliases disponíveis
```

### Ver Versão
```bash
vps-guardian --version

# Mostra:
# - Versão do VPS Guardian
# - Diretório de instalação
```

### Menu Interativo (Mais Opções)
```bash
vps-guardian
# Ou
vps-guardian menu

# Menu completo com:
# - Backups
# - Migração
# - Manutenção
# - Configurações
# - Ferramentas
```

---

## 🎓 Workflows Comuns

### Workflow 1: Setup Inicial Completo
```bash
# 1. Configurar firewall
sudo firewall-vps
# Selecionar modo (Seguro/Híbrido/Básico)

# 2. Configurar updates automáticos
sudo vps-guardian updates

# 3. Configurar backups automáticos
sudo vps-guardian cron
# Backup diário às 2h da manhã

# 4. Testar backup
sudo backup-vps

# 5. Verificar status
status-vps
```

### Workflow 2: Backup Manual Rápido
```bash
# Apenas rodar:
sudo backup-vps

# Backup salvo em:
# /var/backups/vpsguardian/coolify/YYYYMMDD_HHMMSS.tar.gz
```

### Workflow 3: Migração Completa
```bash
# No servidor ANTIGO:
sudo backup-vps
sudo vps-guardian migrate

# Seguir assistente interativo
# Aguardar 10-15 minutos
# Servidor migrado!
```

### Workflow 4: Manutenção Mensal
```bash
# Verificar status antes
status-vps

# Fazer backup preventivo
sudo backup-vps

# Executar manutenção
sudo vps-guardian maintenance

# Verificar status depois
status-vps
```

---

## 📍 Onde Funcionam?

**✅ Todos os comandos funcionam de QUALQUER lugar:**

```bash
# Na pasta home
cd ~
sudo backup-vps  ✅

# Em /tmp
cd /tmp
sudo firewall-vps  ✅

# Em /var/log
cd /var/log
status-vps  ✅

# Em qualquer diretório!
vps-guardian  ✅
```

**Não precisa:**
- ❌ Ir até `/opt/vpsguardian`
- ❌ Lembrar caminhos completos
- ❌ Usar `./script.sh`

**Basta:**
- ✅ Digitar o comando
- ✅ De qualquer lugar
- ✅ Funciona!

---

## 🆘 Troubleshooting

### Erro: "Comando não encontrado"

**Solução:**
```bash
# Recarregar PATH
source ~/.bashrc

# Ou
hash -r

# Verificar se está instalado
which vps-guardian
which firewall-vps
```

### Erro: "VPS Guardian não está instalado"

**Solução:**
```bash
# Reinstalar
cd /opt/vpsguardian
sudo ./instalar.sh
```

### Ver Onde Está Instalado

```bash
# Ver diretório de instalação
vps-guardian --version

# Ver localização dos comandos
which vps-guardian
which firewall-vps
which backup-vps
```

---

## 📊 Resumo Visual

```
Qualquer Pasta
     │
     ├─ vps-guardian         → Menu Principal
     ├─ vps-guardian backup  → Backup
     ├─ vps-guardian migrate → Migração
     ├─ vps-guardian restore → Restauração
     ├─ vps-guardian status  → Status
     │
     ├─ firewall-vps         → Firewall (alias)
     ├─ backup-vps           → Backup (alias)
     └─ status-vps           → Status (alias)
```

**Todos os comandos:**
- ✅ Estão em `/usr/local/bin/` (no PATH)
- ✅ Funcionam de qualquer lugar
- ✅ Não precisam de `./` ou caminho completo
- ✅ Podem ser usados em scripts/cron

---

## 🎯 Cheat Sheet

**Copy-paste ready:**

```bash
# Ver ajuda
vps-guardian --help

# Backup rápido
sudo backup-vps

# Status rápido
status-vps

# Firewall interativo
sudo firewall-vps

# Manutenção
sudo vps-guardian maintenance

# Migração
sudo vps-guardian migrate

# Restaurar
sudo vps-guardian restore

# Configurar cron
sudo vps-guardian cron

# Menu completo
vps-guardian
```

---

**🚀 Agora você pode usar o VPS Guardian de qualquer lugar, a qualquer momento!**
