# Migração Completa - Coolify + Aplicações

Guia para migrar Coolify + TODAS as aplicações (DB + volumes + configurações) para um novo servidor.

## 🎯 O Que Será Migrado

### ✅ Coolify (Infraestrutura)
- PostgreSQL database (todas as configurações)
- SSH keys (para deployments)
- APP_KEY (criptografia)
- Authorized keys (acesso SSH)

### ✅ Aplicações (Dados)
- **Volumes Docker**: Dados persistentes de TODAS as aplicações
- **Bind mounts**: Arquivos mapeados do host
- **Configurações**: Variáveis de ambiente preservadas no banco

## 🚀 Quick Start - Migração Completa

### Modo Automático (Recomendado)

```bash
# 1. Configurar
cp /opt/vpsguardian/config/migration.conf.example \
   /opt/vpsguardian/config/migration.conf

nano /opt/vpsguardian/config/migration.conf
# Configurar:
# NEW_SERVER_IP="192.168.1.100"
# SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"

# 2. Executar migração completa
sudo /opt/vpsguardian/migrar/migrar-completo.sh \
  --config=/opt/vpsguardian/config/migration.conf \
  --auto

# 3. Aguardar (30min-3h dependendo do tamanho)

# 4. Acessar Coolify no novo servidor
# http://IP-NOVO:8000

# 5. Deploy de cada aplicação
# Dashboard → Application → Deploy
```

**Pronto!** Coolify + todas as aplicações migradas.

---

## 📋 Migração Passo a Passo

### Pré-requisitos

**Servidor Novo:**
- Ubuntu 22.04+ ou Debian 11+
- 2+ vCPUs, 4GB+ RAM
- Espaço em disco = 2x tamanho atual
- Acesso SSH configurado

**Servidor Antigo:**
- VPS Guardian instalado
- Coolify funcionando
- Aplicações paradas (recomendado)

### Passo 1: Parar Aplicações (Opcional mas Recomendado)

```bash
# No dashboard Coolify, para cada aplicação:
# Application → Stop

# OU via CLI (todos os containers exceto Coolify):
docker ps --format '{{.Names}}' | \
  grep -v coolify | \
  xargs -r docker stop
```

**Por quê?** Garante consistência dos dados durante backup.

### Passo 2: Executar Migração Completa

```bash
sudo /opt/vpsguardian/migrar/migrar-completo.sh
```

O script executa automaticamente:

1. **Backup Coolify** (DB + SSH keys + config)
2. **Backup de TODOS os volumes Docker** (aplicações)
3. **Migração Coolify** para novo servidor
4. **Transferência volumes** para novo servidor
5. **Restore volumes** no novo servidor

### Passo 3: Verificar Migração

```bash
# No NOVO servidor, verificar volumes:
docker volume ls

# Verificar Coolify:
docker ps | grep coolify

# Acessar dashboard:
# http://IP-NOVO:8000
```

### Passo 4: Redeployar Aplicações

**IMPORTANTE:** Após restore de volumes, containers não existem. É necessário Deploy:

```bash
# No dashboard Coolify:
# Para CADA aplicação:
#   1. Clicar na aplicação
#   2. Clicar "Deploy"
#   3. Aguardar deployment
#   4. Verificar se aplicação iniciou
```

### Passo 5: Atualizar DNS

```bash
# No provedor DNS:
# seu-app.com → IP-NOVO

# Verificar propagação:
dig seu-app.com +short
```

---

## 🛠️ Migração Manual (Avançada)

### Opção 1: Por Componente

**1. Migrar apenas Coolify:**
```bash
sudo /opt/vpsguardian/migrar/migrar-coolify.sh --auto
```

**2. Migrar apenas volumes:**
```bash
# Backup
sudo /opt/vpsguardian/migrar/backup-volumes.sh --all

# Transferir
sudo /opt/vpsguardian/migrar/transfer-volumes.sh --auto

# No servidor NOVO, restaurar:
sudo /opt/vpsguardian/migrar/restore-volumes.sh --all
```

### Opção 2: Volume Específico

```bash
# Backup de 1 volume
sudo /opt/vpsguardian/migrar/backup-volumes.sh

# Selecionar volume interativamente

# Transferir
scp ./volume-backup/meu-volume-backup-*.tar.gz \
  root@IP-NOVO:/root/backups/

# No servidor NOVO:
sudo /opt/vpsguardian/migrar/restore-volumes.sh

# Selecionar backup e volume destino
```

---

## 📊 Estimativa de Tempo e Espaço

### Tempo de Migração

| Tamanho Total | Tempo Estimado |
|---------------|----------------|
| < 5GB | 30min-1h |
| 5-20GB | 1-2h |
| 20-50GB | 2-4h |
| 50-100GB | 4-8h |
| > 100GB | 8h+ |

**Fatores:**
- Velocidade rede entre servidores
- Número de volumes
- Compressão dos dados

### Espaço Necessário

**Servidor Antigo:**
- Backup Coolify: ~500MB
- Backup volumes: Igual ao tamanho atual dos volumes
- **Total:** 1x tamanho atual

**Servidor Novo:**
- Coolify: ~2GB
- Volumes: Igual ao backup
- **Total:** 1.5x tamanho atual

---

## 🔍 Troubleshooting

### Problema: Volume não restaurado corretamente

```bash
# Verificar volume existe
docker volume ls | grep nome-volume

# Inspecionar volume
docker volume inspect nome-volume

# Ver conteúdo (criar container temporário)
docker run --rm -v nome-volume:/data busybox ls -la /data

# Se vazio, restaurar novamente:
sudo /opt/vpsguardian/migrar/restore-volumes.sh \
  --volume=nome-volume \
  --backup=./volume-backup/nome-volume-backup-*.tar.gz
```

### Problema: Aplicação não inicia após deploy

**Causas comuns:**
1. Volume vazio ou corrompido
2. Credenciais de banco incorretas
3. Variáveis de ambiente faltando

**Solução:**
```bash
# 1. Verificar logs
docker logs <container-name>

# 2. Verificar volume montado
docker inspect <container-name> | grep -A10 Mounts

# 3. Verificar variáveis de ambiente no Coolify dashboard:
# Application → Environment Variables

# 4. Se necessário, restaurar volume novamente
```

### Problema: Banco de dados vazio após migração

```bash
# Verificar se PostgreSQL do Coolify tem dados:
docker exec coolify-db psql -U coolify -d coolify \
  -c "SELECT COUNT(*) FROM applications;"

# Se retornar 0, restaurar banco novamente:
# Ver logs de migração em /var/log/vpsguardian/migration-*/
```

### Problema: Transferência de volume muito lenta

```bash
# Opção 1: Compactar com nível máximo
docker run --rm \
  -v volume-name:/source:ro \
  -v ./backup:/backup \
  busybox \
  tar -czf /backup/volume-backup.tar.gz --best -C /source .

# Opção 2: Usar rsync incremental
rsync -avz --partial --progress \
  ./volume-backup/ \
  root@IP-NOVO:/root/backups/volume-backup/
```

---

## ✅ Checklist Pós-Migração

### Imediatamente Após Migração

- [ ] Coolify acessível em http://IP-NOVO:8000
- [ ] Todas as aplicações listadas no dashboard
- [ ] Login funciona (mesmo usuário/senha)
- [ ] Variáveis de ambiente corretas

### Antes de Atualizar DNS

- [ ] Deploy de CADA aplicação executado
- [ ] Todas as aplicações startaram com sucesso
- [ ] Bancos de dados acessíveis
- [ ] Volumes montados corretamente
- [ ] Certificados SSL configurados (serão renovados automaticamente)

### Monitoramento (Primeiros 7 Dias)

- [ ] Nenhum erro crítico nos logs
- [ ] Performance aceitável
- [ ] Deployments funcionando
- [ ] Webhooks funcionando
- [ ] Backups automáticos configurados

---

## 💡 Dicas Importantes

### 1. Sempre Pare Aplicações Antes de Backup

```bash
# Para garantir consistência de dados
docker stop <app-container>
```

### 2. Teste em Ambiente de Staging Primeiro

Se possível, teste a migração em VPS de teste antes da produção.

### 3. Mantenha Servidor Antigo Por 7-14 Dias

Não destrua o servidor antigo imediatamente. Mantenha como fallback.

### 4. Volumes vs Bind Mounts

**Volumes Docker** (migrados automaticamente):
- Gerenciados pelo Docker
- Localizados em `/var/lib/docker/volumes/`
- Backup/restore via scripts

**Bind Mounts** (migração manual):
- Diretórios mapeados do host
- Precisam ser copiados manualmente via rsync/scp

### 5. Credenciais de Banco de Dados

Se as credenciais de banco mudarem no novo servidor, atualizar no Coolify:
```
Application → Configuration → Database
```

---

## 🎯 Resumo dos Comandos

```bash
# Migração completa automática
sudo /opt/vpsguardian/migrar/migrar-completo.sh \
  --config=config/migration.conf --auto

# Migração completa interativa
sudo /opt/vpsguardian/migrar/migrar-completo.sh

# Apenas Coolify
sudo /opt/vpsguardian/migrar/migrar-coolify.sh --auto

# Apenas volumes
sudo /opt/vpsguardian/migrar/backup-volumes.sh --all
sudo /opt/vpsguardian/migrar/transfer-volumes.sh --auto
sudo /opt/vpsguardian/migrar/restore-volumes.sh --all

# Pular volumes (apenas Coolify)
sudo /opt/vpsguardian/migrar/migrar-completo.sh --skip-volumes
```

---

**Tempo Total:** 30min-8h | **Downtime:** Sim | **Dificuldade:** Médio
**Logs:** `/var/log/vpsguardian/migration-*/`
