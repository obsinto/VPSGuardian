# ⚡ Instalação Rápida - 5 Minutos

Siga estes passos para configurar o sistema completo de backup e manutenção.

---

## 🎯 Pré-requisitos

- Ubuntu/Debian com Docker instalado
- Coolify instalado e rodando
- Acesso root via SSH

---

## 📋 Passo a Passo

### 1. Clonar Repositório

```bash
cd ~
git clone https://github.com/SEU_USUARIO/manutencao_backup_vps.git
cd manutencao_backup_vps
```

### 2. Instalar Dependências

```bash
sudo apt update
sudo apt install unattended-upgrades apt-listchanges -y
```

### 3. Criar Diretórios

```bash
sudo mkdir -p /opt/manutencao
sudo mkdir -p /var/log/manutencao
sudo mkdir -p /root/coolify-backups
```

### 4. Copiar Scripts

```bash
# Scripts de backup
sudo cp backup/backup-coolify.sh /opt/manutencao/
sudo cp backup/backup-volume.sh /usr/local/bin/backup-volume
sudo cp backup/restaurar-volume.sh /usr/local/bin/restaurar-volume

# Scripts de manutenção
sudo cp manutencao/manutencao-completa.sh /opt/manutencao/
sudo cp manutencao/alerta-disco.sh /opt/manutencao/

# Scripts auxiliares
sudo cp scripts-auxiliares/status-completo.sh /usr/local/bin/status-completo
sudo cp scripts-auxiliares/test-sistema.sh /opt/manutencao/

# Dar permissão de execução
sudo chmod +x /opt/manutencao/*.sh
sudo chmod +x /usr/local/bin/backup-volume
sudo chmod +x /usr/local/bin/restaurar-volume
sudo chmod +x /usr/local/bin/status-completo
```

### 5. Configurar Unattended Upgrades

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Quando perguntado, selecione "Yes"**

### 6. Configurar Cron

```bash
sudo crontab -e
```

**Cole estas linhas no final do arquivo:**

```bash
# Backup completo do Coolify - Todo domingo às 2h
0 2 * * 0 /opt/manutencao/backup-coolify.sh >> /var/log/manutencao/cron.log 2>&1

# Manutenção preventiva - Toda segunda às 3h
0 3 * * 1 /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron.log 2>&1

# Alerta de disco cheio - Todo dia às 9h
0 9 * * * /opt/manutencao/alerta-disco.sh >> /var/log/manutencao/cron.log 2>&1
```

Salve e feche (Ctrl+X, depois Y, depois Enter).

### 7. Testar Tudo

```bash
# Testar backup
echo "🧪 Testando backup..."
sudo /opt/manutencao/backup-coolify.sh

# Testar manutenção
echo "🧪 Testando manutenção..."
sudo /opt/manutencao/manutencao-completa.sh

# Ver status
echo "📊 Status do sistema..."
status-completo

# Executar testes
echo "✅ Executando suite de testes..."
sudo /opt/manutencao/test-sistema.sh
```

---

## ✅ Verificação Final

Se tudo funcionou, você deve ver:

```
✅ TODOS OS TESTES PASSARAM!
```

E os seguintes arquivos devem existir:

```bash
ls /root/coolify-backups/  # Deve ter pelo menos 1 arquivo .tar.gz
ls /var/log/manutencao/    # Deve ter backup-coolify.log e manutencao.log
```

---

## 🎉 Pronto!

Seu sistema agora está configurado e rodando automaticamente:

- ✅ **Backup automático**: Todo domingo às 2h
- ✅ **Manutenção automática**: Toda segunda às 3h
- ✅ **Alerta de disco**: Todo dia às 9h
- ✅ **Updates de segurança**: Automático diariamente

---

## 📚 Próximos Passos

1. **Configure notificações** (opcional):
   ```bash
   sudo nano /opt/manutencao/backup-coolify.sh
   # Edite EMAIL ou WEBHOOK_URL
   ```

2. **Configure backup off-site** (recomendado):
   - Veja [GUIA-BACKUP.md](docs/GUIA-BACKUP.md#backup-off-site)

3. **Teste restauração de backup** (importante!):
   - Veja [GUIA-BACKUP.md](docs/GUIA-BACKUP.md#restauração-de-backups)

---

## 🆘 Problemas?

Consulte:
- [GUIA-BACKUP.md](docs/GUIA-BACKUP.md#troubleshooting)
- [GUIA-MANUTENCAO.md](docs/GUIA-MANUTENCAO.md#troubleshooting)
- [README.md](README.md)

---

**Boa sorte! 🚀**
