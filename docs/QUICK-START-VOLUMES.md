# Quick Start: Migração de Volumes Docker

## 🚀 Migração em 1 Comando (Recomendado)

```bash
cd /opt/vpsguardian
./migrar/migrar-volumes.sh
```

**O que faz:**
1. ✅ Lista backups disponíveis
2. ✅ Permite selecionar volumes
3. ✅ Transfere para servidor remoto
4. ✅ Restaura automaticamente
5. ✅ Valida migração

**Tempo estimado:** 5-30 minutos (depende do tamanho)

---

## 📋 Migração Manual em 3 Passos

### Passo 1: Criar Backups

```bash
# Todos os volumes
./migrar/backup-volumes.sh --all

# Volume específico
./migrar/backup-volumes.sh --volume=meu-volume

# Interativo
./migrar/backup-volumes.sh
```

**Saída:** `./volume-backup/`

---

### Passo 2: Transferir Backups

```bash
# Modo interativo
./migrar/transfer-volumes.sh

# Com config file
./migrar/transfer-volumes.sh --config=server.conf --auto
```

**Config file (server.conf):**
```bash
SSH_IP="192.168.1.100"
SSH_USER="root"
SSH_PORT="22"
SSH_KEY="/root/.ssh/id_rsa"
SOURCE_PATH="./volume-backup"
DESTINATION_PATH="/root/backups/volume-backup"
```

---

### Passo 3: Restaurar no Destino

**No servidor de destino:**

```bash
# Todos os backups
./migrar/restore-volumes.sh --all --dir=/root/backups/volume-backup

# Volume específico
./migrar/restore-volumes.sh --volume=nome --backup=/path/to/backup.tar.gz

# Interativo
./migrar/restore-volumes.sh
```

---

## 🔍 Validação Rápida

### No servidor de destino:

```bash
# Listar volumes
docker volume ls

# Ver conteúdo
docker run --rm -v VOLUME_NAME:/v busybox ls -la /v

# Contar arquivos
docker run --rm -v VOLUME_NAME:/v busybox find /v -type f | wc -l

# Tamanho
docker run --rm -v VOLUME_NAME:/v busybox du -sh /v
```

---

## ⚡ Comandos Úteis

### Verificar Backups

```bash
# Listar backups
ls -lh /root/volume-backups/

# Ver conteúdo de backup
tar -tzf backup.tar.gz | head -20

# Tamanho total
du -sh /root/volume-backups/
```

### Espaço em Disco

```bash
# Origem
df -h /var/lib/docker/volumes

# Destino
ssh root@IP "df -h /var/lib/docker/volumes"
```

### Logs

```bash
# Backup
tail -f /var/log/vpsguardian/backup-volumes.log

# Migração
tail -f volume-migration-logs/volume-migration-*.log

# Buscar erros
grep -i error /var/log/vpsguardian/*.log
```

---

## 🛡️ Boas Práticas

1. **Pare containers antes de backup**
   ```bash
   docker stop container-name
   ./migrar/backup-volumes.sh --volume=volume-name
   docker start container-name
   ```

2. **Verifique espaço antes**
   ```bash
   # Tamanho dos volumes
   docker system df -v
   ```

3. **Teste conexão SSH**
   ```bash
   ssh -i /root/.ssh/id_rsa root@IP "docker --version"
   ```

4. **Não delete backups imediatamente**
   - Valide completamente antes
   - Mantenha por 7-30 dias

---

## ❌ Troubleshooting

### Erro: "No volume backups found"
```bash
# Criar backups primeiro
./migrar/backup-volumes.sh --all
```

### Erro: "SSH connection failed"
```bash
# Testar SSH
ssh -i /root/.ssh/id_rsa root@IP

# Verificar firewall
sudo ufw status
```

### Erro: "Docker not installed"
```bash
# No servidor destino, instalar Docker
curl -fsSL https://get.docker.com | bash
```

### Backup/Restore lento
- Volumes grandes levam tempo
- Execute em horário de baixo uso
- Use conexão de rede rápida

---

## 📊 Exemplo Completo

```bash
# ====================
# SERVIDOR ORIGEM (A)
# ====================

# 1. Listar volumes
docker volume ls

# 2. Criar backups
cd /opt/vpsguardian
./migrar/backup-volumes.sh --all

# 3. Verificar backups
ls -lh /root/volume-backups/

# 4. Migrar
./migrar/migrar-volumes.sh
# IP destino: 192.168.1.100
# Selecionar: all
# Confirmar: yes

# ====================
# SERVIDOR DESTINO (B)
# ====================

# 5. Verificar volumes
docker volume ls

# 6. Testar volume
docker run --rm -v meu-volume:/v busybox ls -la /v

# 7. Iniciar aplicações
docker-compose up -d

# 8. Validar aplicação
curl http://localhost
```

---

## 🎯 Acesso pelo Menu

```bash
vps-guardian
# → 3. Migração
# → 2. Migrar Volumes Docker
```

---

## 📚 Documentação Completa

Para mais detalhes: `docs/MIGRACAO-VOLUMES.md`
