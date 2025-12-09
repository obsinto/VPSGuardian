# ⚡ Comandos Rápidos - Migração

## 📦 Instalação

```bash
# VPS Principal - Instalar sistema
cd /opt
git clone <seu-repo> vpsguardian
cd vpsguardian
./instalador.sh
```

---

## ✅ Validação Pré-Migração

```bash
# Validar ambiente completo
./scripts-auxiliares/validar-pre-migracao.sh

# Verificações manuais rápidas
docker ps --filter name=coolify
docker exec coolify-db pg_isready -U coolify
ls -lh /root/coolify-backups/
```

---

## 💾 Backup

```bash
# Criar backup via comando global
vps-guardian backup

# OU manualmente
cd /opt/vpsguardian
./backup/backup-coolify.sh

# Verificar backup criado
ls -lht /root/coolify-backups/ | head -5

# Ver conteúdo do backup
tar -tzf /root/coolify-backups/coolify-*.tar.gz | head -20
```

---

## 🔑 SSH

```bash
# Criar chave SSH (se não tiver)
ssh-keygen -t rsa -b 4096 -C "migracao-vps"

# Copiar chave para VPS de teste
ssh-copy-id root@IP_VPS_TESTE

# Testar conexão sem senha
ssh -o BatchMode=yes root@IP_VPS_TESTE "echo OK"

# Adicionar chave ao agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
```

---

## 🚀 Migração

```bash
# Migração completa
cd /opt/vpsguardian
./migrar/migrar-coolify.sh

# Migrar volumes específicos
./migrar/migrar-volumes.sh

# Transferir apenas backups
./migrar/transferir-backups.sh
```

---

## ✅ Validação Pós-Migração

```bash
# Validação remota (da VPS Principal)
./scripts-auxiliares/validar-pos-migracao.sh --remote IP_VPS_TESTE

# Validação local (na VPS de Teste)
ssh root@IP_VPS_TESTE
cd /opt/vpsguardian
./scripts-auxiliares/validar-pos-migracao.sh
```

---

## 📋 Checklist Interativo

```bash
# Checklist completo com guia passo a passo
./scripts-auxiliares/checklist-migracao.sh

# Opções:
# [1] Migração completa
# [2] Apenas validação pré-migração
# [3] Apenas validação pós-migração
```

---

## 🔍 Verificações na VPS de Teste

```bash
# SSH na VPS de teste
ssh root@IP_VPS_TESTE

# Ver containers do Coolify
docker ps --filter name=coolify

# Ver logs
docker logs coolify --tail 50
docker logs coolify-db --tail 50
docker logs coolify-proxy --tail 50

# Status do banco
docker exec coolify-db pg_isready -U coolify

# Contar tabelas
docker exec coolify-db psql -U coolify -d coolify -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"

# Testar HTTP
curl -I http://localhost:8000

# Ver porta 8000
netstat -tlnp | grep 8000

# Status dos serviços
cd /data/coolify/source
docker compose ps
```

---

## 🔄 Restart/Reinício

```bash
# Na VPS de TESTE - Reiniciar Coolify completo
cd /data/coolify/source
docker compose restart

# Reiniciar apenas aplicação
docker restart coolify

# Reiniciar apenas banco
docker restart coolify-db

# Parar tudo
docker compose down

# Iniciar tudo
docker compose up -d

# Rebuild completo (caso necessário)
docker compose down
docker compose pull
docker compose up -d
```

---

## 🗄️ Banco de Dados

```bash
# Na VPS de TESTE - Verificar banco

# Status
docker exec coolify-db pg_isready -U coolify

# Tamanho do banco
docker exec coolify-db psql -U coolify -d coolify -c "SELECT pg_size_pretty(pg_database_size('coolify'));"

# Número de conexões
docker exec coolify-db psql -U coolify -d coolify -c "SELECT count(*) FROM pg_stat_activity;"

# Listar tabelas
docker exec coolify-db psql -U coolify -d coolify -c "\dt"

# Backup manual do banco
docker exec coolify-db pg_dump -U coolify -Fc coolify > backup-manual.dmp

# Restaurar banco manualmente
cat backup-manual.dmp | docker exec -i coolify-db pg_restore --clean --no-acl --no-owner -U coolify -d coolify
```

---

## 📊 Monitoramento

```bash
# Status geral
docker ps --filter name=coolify --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Uso de recursos
docker stats --no-stream --filter name=coolify

# Espaço em disco
df -h /

# Volumes Docker
docker volume ls --filter name=coolify

# Logs em tempo real
docker logs coolify --follow

# Rede Docker
docker network ls
docker network inspect coolify
```

---

## 🧹 Limpeza

```bash
# Na VPS de TESTE - Limpar migração

# Remover containers (mantém volumes)
cd /data/coolify/source
docker compose down

# Remover tudo (incluindo volumes)
docker compose down -v

# Remover dados do Coolify
rm -rf /data/coolify

# Remover backups temporários
rm -rf /root/coolify-backup*
rm -rf /root/coolify-restore*

# Limpar Docker completo
docker system prune -a --volumes -f
```

---

## 🐛 Troubleshooting

### Coolify não inicia

```bash
# Ver logs detalhados
docker logs coolify --tail 200

# Ver eventos do container
docker events --filter container=coolify

# Inspecionar container
docker inspect coolify

# Verificar .env
cat /data/coolify/source/.env | grep -i "app_key\|app_url"
```

### Banco não conecta

```bash
# Verificar se banco está rodando
docker ps --filter name=coolify-db

# Logs do banco
docker logs coolify-db --tail 100

# Tentar conectar manualmente
docker exec -it coolify-db psql -U coolify -d coolify

# Verificar variáveis de conexão
docker exec coolify env | grep -i "db\|database\|postgres"
```

### Interface não carrega

```bash
# Verificar porta
ss -tlnp | grep 8000

# Verificar Nginx/Proxy
docker logs coolify-proxy

# Testar curl
curl -v http://localhost:8000

# Verificar DNS/IP
cat /data/coolify/source/.env | grep APP_URL
```

### SSH Keys não copiadas

```bash
# Verificar diretório de SSH keys
ls -lah /data/coolify/ssh/keys/

# Corrigir permissões
chmod 700 /data/coolify/ssh/keys
chmod 600 /data/coolify/ssh/keys/*

# Recopiar do backup
tar -xzf /root/coolify-backups/coolify-*.tar.gz ssh-keys/
cp -r ssh-keys/* /data/coolify/ssh/keys/
```

---

## 🔐 Segurança Pós-Migração

```bash
# Na VPS de TESTE - Configurar firewall
vps-guardian firewall

# OU manualmente
cd /opt/vpsguardian
./manutencao/firewall-perfil-padrao.sh

# Verificar regras do firewall
ufw status verbose

# Configurar updates automáticos
vps-guardian updates
```

---

## 📈 Testes de Carga

```bash
# Testar múltiplas requisições
for i in {1..10}; do curl -I http://localhost:8000; done

# Apache Bench (se instalado)
ab -n 100 -c 10 http://localhost:8000/

# Verificar logs durante teste
docker logs coolify --follow
```

---

## 🔄 Repetir Migração (Teste de Recuperação)

```bash
# Na VPS de TESTE - Destruir tudo
cd /data/coolify/source
docker compose down -v
rm -rf /data/coolify

# Na VPS PRINCIPAL - Migrar novamente
cd /opt/vpsguardian
./migrar/migrar-coolify.sh

# Validar novamente
./scripts-auxiliares/validar-pos-migracao.sh --remote IP_VPS_TESTE
```

---

## 📝 Gerar Relatórios

```bash
# Status completo do sistema
vps-guardian status > /tmp/status-pos-migracao.txt

# Logs de migração
cat /opt/vpsguardian/migration-logs/migration-agent-*.log

# Logs de validação
cat /tmp/post-migration-validation-*.log

# Informações do Docker
docker info > /tmp/docker-info.txt
docker ps -a > /tmp/docker-containers.txt
docker images > /tmp/docker-images.txt
```

---

## 🎯 Atalhos Úteis

```bash
# Alias para comandos frequentes (adicionar ao ~/.bashrc)
alias coolify-logs='docker logs coolify --tail 100 --follow'
alias coolify-db-logs='docker logs coolify-db --tail 100 --follow'
alias coolify-restart='cd /data/coolify/source && docker compose restart'
alias coolify-status='docker ps --filter name=coolify'
alias coolify-stats='docker stats --no-stream --filter name=coolify'

# Recarregar aliases
source ~/.bashrc
```

---

## 📚 Documentação Completa

- **[Guia Detalhado](TESTE-MIGRACAO.md)** - Teste completo com 8 fases
- **[Guia Rápido](GUIA-RAPIDO-MIGRACAO.md)** - Quick start em 5 passos
- **[Resumo](RESUMO-TESTE-MIGRACAO.md)** - Processo em 3 comandos
- **[README](../README.md)** - Documentação geral

---

**💡 Dica:** Salve este arquivo para referência rápida durante a migração!
