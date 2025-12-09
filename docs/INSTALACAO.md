# 📥 Instalação do VPS Guardian

Guia rápido e direto para instalar o VPS Guardian no seu servidor.

---

## 🎯 Requisitos

- **Sistema Operacional:** Ubuntu 20.04+ / Debian 11+
- **Docker:** Instalado e funcionando
- **Coolify:** Instalado (opcional, mas recomendado)
- **Root Access:** Necessário para instalação
- **Espaço em Disco:** Mínimo 10GB disponível para backups

---

## ⚡ Instalação Rápida (3 Passos)

### 1. Clonar o Repositório

```bash
cd /opt
git clone https://github.com/SEU-USUARIO/manutencao_backup_vps.git vpsguardian
cd vpsguardian
```

### 2. Executar Instalador

```bash
sudo chmod +x instalar.sh
sudo ./instalar.sh
```

O instalador irá:
- ✅ Criar diretórios necessários (`/opt/vpsguardian`, `/var/backups/vpsguardian`, `/var/log/vpsguardian`)
- ✅ Configurar permissões corretas
- ✅ Instalar comando global `vps-guardian`
- ✅ Configurar cron jobs (opcional)
- ✅ Validar dependências (docker, tar, gzip, etc.)

### 3. Verificar Instalação

```bash
vps-guardian --version
vps-guardian --help
```

---

## 🔧 Configuração Avançada

### Personalizar Diretórios

Edite `config/default.conf` após instalação:

```bash
nano /opt/vpsguardian/config/default.conf
```

**Variáveis principais:**
```bash
VPSGUARDIAN_ROOT="/opt/vpsguardian"
BACKUP_ROOT="/var/backups/vpsguardian"
LOG_DIR="/var/log/vpsguardian"
BACKUP_RETENTION_DAYS="30"  # Manter backups por 30 dias
LOG_RETENTION_DAYS="90"     # Manter logs por 90 dias
```

### Configurar Backups Automáticos

Durante a instalação, escolha configurar cron jobs ou configure manualmente:

```bash
sudo crontab -e
```

**Exemplos de agendamento:**

```bash
# Backup diário do Coolify às 2h da manhã
0 2 * * * /opt/vpsguardian/backup/backup-coolify.sh

# Backup semanal dos bancos de dados (domingo, 3h)
0 3 * * 0 /opt/vpsguardian/backup/backup-databases.sh

# Manutenção completa mensal (dia 1, 4h)
0 4 1 * * /opt/vpsguardian/manutencao/manutencao-completa.sh
```

---

## 📦 Estrutura de Diretórios Após Instalação

```
/opt/vpsguardian/
├── backup/              # Scripts de backup
├── manutencao/          # Scripts de manutenção
├── migrar/              # Scripts de migração
├── scripts-auxiliares/  # Utilitários
├── lib/                 # Bibliotecas compartilhadas
├── config/              # Configurações
└── menu-principal.sh    # Menu interativo

/var/backups/vpsguardian/
├── coolify/             # Backups do Coolify
├── databases/           # Dumps de bancos de dados
└── volumes/             # Backups de volumes Docker

/var/log/vpsguardian/
└── *.log                # Logs de todas as operações

/usr/local/bin/
└── vps-guardian         # Comando global
```

---

## 🔒 Permissões e Segurança

**Diretórios criados com permissões seguras:**
- `/opt/vpsguardian` → 755 (rwxr-xr-x)
- `/var/backups/vpsguardian` → 700 (rwx------) - Apenas root
- `/var/log/vpsguardian` → 755 (rwxr-xr-x)

**Backups contêm dados sensíveis:**
- ✅ APP_KEY do Coolify
- ✅ Chaves SSH privadas
- ✅ Credenciais de banco de dados
- ✅ Tokens e secrets

**⚠️ IMPORTANTE:** Nunca exponha `/var/backups/vpsguardian` publicamente!

---

## 🧪 Testar Instalação

Execute os testes básicos:

```bash
# 1. Verificar comando global
vps-guardian

# 2. Testar backup (dry-run)
sudo /opt/vpsguardian/backup/backup-coolify.sh

# 3. Verificar logs
tail -f /var/log/vpsguardian/backup-coolify.log

# 4. Listar backups criados
ls -lh /var/backups/vpsguardian/coolify/
```

---

## 🔄 Atualização

Para atualizar o VPS Guardian:

```bash
cd /opt/vpsguardian
git pull origin main
sudo ./instalar.sh  # Re-executar instalador
```

---

## ❌ Desinstalação

```bash
# Remover comando global
sudo rm /usr/local/bin/vps-guardian

# Remover cron jobs
sudo crontab -e  # Deletar linhas do VPS Guardian

# Remover arquivos (CUIDADO: apaga backups!)
sudo rm -rf /opt/vpsguardian
sudo rm -rf /var/backups/vpsguardian
sudo rm -rf /var/log/vpsguardian
```

**⚠️ ATENÇÃO:** Faça download dos backups antes de desinstalar!

---

## 🆘 Troubleshooting

### Erro: "Comando não encontrado"
```bash
# Verificar se está no PATH
which vps-guardian

# Recarregar PATH
source ~/.bashrc
```

### Erro: "Permissão negada"
```bash
# Todos os scripts precisam ser executados como root
sudo vps-guardian
```

### Erro: "Docker não está rodando"
```bash
sudo systemctl status docker
sudo systemctl start docker
```

### Erro: "Coolify não encontrado"
```bash
# Verificar se Coolify está instalado
docker ps | grep coolify

# Instalar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

---

## 📞 Próximos Passos

Após instalação bem-sucedida:

1. ✅ Leia [`USO-SCRIPTS.md`](./USO-SCRIPTS.md) para aprender a usar cada script
2. ✅ Configure backups automáticos com cron
3. ✅ Teste a restauração em ambiente de teste
4. ✅ Configure alertas (webhook/email) nos scripts de backup
5. ✅ Mantenha backups off-site (outro servidor ou cloud)

---

**✅ Instalação Concluída!** Seu servidor agora está protegido com o VPS Guardian.
