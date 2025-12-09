# 🚀 Guia Completo - Migração de VPS com Coolify

Migre sua instalação completa do Coolify para um novo servidor de forma segura e sem perda de dados.

---

## 📋 Índice

1. [Pré-requisitos](#-pré-requisitos)
2. [Planejamento](#-planejamento)
3. [Método 1: Migração Automatizada (Recomendado)](#-método-1-migração-automatizada-recomendado)
4. [Método 2: Migração Manual (Avançado)](#-método-2-migração-manual-avançado)
5. [Método 3: Migração via S3 (Intermediário)](#-método-3-migração-via-s3-intermediário)
6. [Pós-Migração](#-pós-migração)
7. [Troubleshooting](#-troubleshooting)
8. [Rollback](#-rollback)

---

## ✅ Pré-requisitos

### Servidor Antigo (Origem)
- ✅ VPS Guardian instalado
- ✅ Coolify funcionando
- ✅ Acesso SSH como root
- ✅ Backups recentes

### Servidor Novo (Destino)
- ✅ Ubuntu 22.04/24.04 ou Debian 11/12
- ✅ Mínimo 2 vCPUs, 4GB RAM
- ✅ 40GB+ de disco (mais se tiver muitos volumes)
- ✅ Acesso SSH como root
- ✅ IP público

### Preparação
- ✅ Chaves SSH configuradas (sem senha)
- ✅ Janela de manutenção agendada
- ✅ Usuários avisados sobre downtime
- ✅ DNS TTL reduzido (se vai mudar IP)

---

## 📝 Planejamento

### 1. Calcular Tempo de Downtime

| Tamanho dos Dados | Tempo Estimado |
|-------------------|----------------|
| < 5GB | 15-30 minutos |
| 5-20GB | 30min-1h |
| 20-50GB | 1-2 horas |
| 50-100GB | 2-4 horas |
| > 100GB | 4+ horas |

**Fórmula:** `Tempo = (Tamanho_Dados / Velocidade_Rede) + 20min_setup`

### 2. Verificar Espaço Necessário

```bash
# No servidor antigo
df -h /data/coolify
docker system df
du -sh /var/backups/vpsguardian

# Você precisará de:
# - Servidor novo: 1.5x o espaço usado no antigo
# - Backup local: 1x o espaço usado
```

### 3. Janela de Manutenção

**Recomendação:**
- Horário de baixo tráfego (madrugada, fim de semana)
- Buffer de 2x o tempo estimado
- Comunicação prévia com usuários (48h antes)

---

## 🎯 Método 1: Migração Automatizada (Recomendado)

**Vantagens:**
- ✅ Automatizado e testado
- ✅ Validações em cada etapa
- ✅ Rollback facilitado
- ✅ Ideal para a maioria dos casos

**Tempo:** 30min-2h (depende do tamanho)

### Passo 1: Preparar Servidor Novo

**No servidor NOVO:**

```bash
# 1. Atualizar sistema
apt update && apt upgrade -y

# 2. Instalar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Aguardar instalação (5-10 minutos)
# Verificar se está rodando
docker ps | grep coolify

# 3. Instalar VPS Guardian
cd /opt
git clone https://github.com/SEU-USUARIO/vpsguardian.git
cd vpsguardian
sudo ./instalar.sh

# 4. Configurar SSH keys (para receber migração)
# Se não tiver chave SSH, criar:
ssh-keygen -t ed25519 -C "migracao-coolify"

# Copiar chave pública para authorized_keys
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
```

### Passo 2: Fazer Backup no Servidor Antigo

**No servidor ANTIGO:**

```bash
# 1. Acessar VPS Guardian
vps-guardian
# → 2 (Backups)
# → 1 (Backup Completo do Coolify)

# OU via linha de comando:
sudo vps-guardian backup

# 2. Verificar backup criado
ls -lh /var/backups/vpsguardian/coolify/

# Exemplo de saída:
# 20241209_153045.tar.gz  (1.2G)

# 3. Validar integridade
tar -tzf /var/backups/vpsguardian/coolify/20241209_153045.tar.gz | head -20
```

### Passo 3: Executar Migração Automatizada

**No servidor ANTIGO:**

```bash
# 1. Iniciar assistente de migração
vps-guardian
# → 4 (Migração)
# → 1 (Migrar Coolify Completo)

# OU via linha de comando:
sudo /opt/vpsguardian/migrar/migrar-coolify.sh
```

**O assistente vai perguntar:**

```
📋 Informações do Servidor Destino

1. IP do servidor novo: 203.0.113.50
2. Usuário SSH (padrão: root): root
3. Porta SSH (padrão: 22): 22
4. Testar conexão SSH? (Y/n): Y

✅ Conexão SSH OK!

5. Coolify já está instalado no destino? (Y/n): Y

⚠️  ATENÇÃO: Esta operação irá:
  • Parar o Coolify atual (DOWNTIME!)
  • Criar backup completo
  • Transferir para servidor novo
  • Restaurar no servidor novo
  • Validar migração

Tempo estimado: 45 minutos
Downtime total: 45 minutos

Confirmar migração? (digite 'SIM' em maiúsculas): SIM

🚀 Iniciando migração...
```

**O script vai:**
1. ✅ Parar Coolify (containers continuam rodando)
2. ✅ Criar backup completo
3. ✅ Transferir via rsync/scp
4. ✅ Parar Coolify no destino
5. ✅ Restaurar banco de dados
6. ✅ Restaurar SSH keys
7. ✅ Restaurar configurações
8. ✅ Validar integridade
9. ✅ Iniciar Coolify no destino

### Passo 4: Validar Migração

**Automático (pelo script):**
```
✅ Validações automáticas:
  ✓ Banco de dados acessível
  ✓ Containers iniciados
  ✓ SSH keys presentes
  ✓ Configurações corretas
  ✓ Volumes montados

Score: 95/100 - EXCELENTE
```

**Manual (recomendado):**

```bash
# No servidor NOVO:

# 1. Verificar containers
docker ps | grep coolify
# Deve mostrar 5+ containers rodando

# 2. Verificar banco de dados
docker exec coolify-db psql -U coolify -d coolify -c "SELECT COUNT(*) FROM applications;"

# 3. Verificar SSH keys
ls -lh /data/coolify/ssh/keys/

# 4. Acessar Coolify web
# http://IP-NOVO:8000 ou https://seu-dominio.com

# 5. Testar deploy de uma aplicação
```

### Passo 5: Atualizar DNS

**Se o IP mudou:**

```bash
# 1. Atualizar registros DNS
# No seu provedor DNS (Cloudflare, Route53, etc):

# A record:
# seu-dominio.com → 203.0.113.50 (IP novo)

# 2. Verificar propagação
dig seu-dominio.com +short
# Deve retornar o IP novo

# 3. Testar acesso
curl -I https://seu-dominio.com
# Deve responder 200 OK
```

### Passo 6: Monitorar

**Nas primeiras 24h:**

```bash
# Verificar logs de erro
docker logs coolify | grep -i error

# Monitorar recursos
htop

# Verificar aplicações
# Coolify dashboard → Applications → Status de cada app
```

---

## 🔧 Método 2: Migração Manual (Avançado)

**Vantagens:**
- ✅ Controle total sobre cada etapa
- ✅ Flexibilidade para casos complexos
- ✅ Entendimento profundo do processo

**Desvantagens:**
- ⚠️ Mais propenso a erros
- ⚠️ Requer conhecimento avançado
- ⚠️ Mais demorado

### Etapa 1: Backup Manual

**No servidor ANTIGO:**

```bash
# 1. Criar diretório de backup
mkdir -p /tmp/migracao-coolify
cd /tmp/migracao-coolify

# 2. Backup do banco de dados
docker exec coolify-db pg_dump -U coolify -d coolify -F c -f /tmp/backup.dmp
docker cp coolify-db:/tmp/backup.dmp ./coolify-db.dmp
docker exec coolify-db rm /tmp/backup.dmp

# 3. Backup das SSH keys
cp -r /data/coolify/ssh/keys ./ssh-keys

# 4. Backup do .env
cp /data/coolify/source/.env ./coolify.env

# Extrair APP_KEY
grep "^APP_KEY=" ./coolify.env > app-key.txt

# 5. Backup do authorized_keys
cp /root/.ssh/authorized_keys ./authorized_keys.bak

# 6. Backup configurações Nginx (se houver)
[ -d /etc/nginx ] && cp -r /etc/nginx ./nginx-config

# 7. Listar volumes (para referência)
docker volume ls > volumes-list.txt

# 8. Compactar tudo
cd /tmp
tar -czf migracao-coolify-$(date +%Y%m%d_%H%M%S).tar.gz migracao-coolify/

# 9. Verificar tamanho
ls -lh migracao-coolify-*.tar.gz
```

### Etapa 2: Transferir Backup

**Opção A: Via SCP**
```bash
# Do servidor ANTIGO para o NOVO:
scp /tmp/migracao-coolify-*.tar.gz root@203.0.113.50:/tmp/
```

**Opção B: Via rsync**
```bash
rsync -avz --progress /tmp/migracao-coolify-*.tar.gz \
  root@203.0.113.50:/tmp/
```

**Opção C: Via S3 (se preferir)**
```bash
# Servidor ANTIGO: Upload
aws s3 cp /tmp/migracao-coolify-*.tar.gz \
  s3://meu-bucket/migracao/

# Servidor NOVO: Download
aws s3 cp s3://meu-bucket/migracao/migracao-coolify-*.tar.gz /tmp/
```

### Etapa 3: Preparar Servidor Novo

**No servidor NOVO:**

```bash
# 1. Instalar Coolify (se ainda não instalou)
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Aguardar instalação completa
# Verificar se está rodando
docker ps | grep coolify

# 2. Descompactar backup
cd /tmp
tar -xzf migracao-coolify-*.tar.gz
cd migracao-coolify
```

### Etapa 4: Restaurar Banco de Dados

**No servidor NOVO:**

```bash
# 1. Parar containers do Coolify (exceto DB)
docker ps --filter name=coolify --format '{{.Names}}' | \
  grep -v 'coolify-db' | xargs docker stop

# 2. Restaurar banco
cat coolify-db.dmp | docker exec -i coolify-db \
  pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify

# 3. Verificar restauração
docker exec coolify-db psql -U coolify -d coolify \
  -c "SELECT COUNT(*) FROM applications;"

# Deve mostrar o número de aplicações que você tinha
```

### Etapa 5: Restaurar Configurações

**No servidor NOVO:**

```bash
# 1. Restaurar SSH keys
rm -rf /data/coolify/ssh/keys/*
cp -r ssh-keys/* /data/coolify/ssh/keys/
chown -R 9999:9999 /data/coolify/ssh/keys

# 2. Restaurar authorized_keys
cat authorized_keys.bak >> /root/.ssh/authorized_keys

# 3. Atualizar APP_KEY no .env
cd /data/coolify/source
APP_KEY=$(grep "^APP_KEY=" /tmp/migracao-coolify/app-key.txt | cut -d '=' -f2-)

# Adicionar ao .env (sem substituir, apenas adicionar às chaves anteriores)
sed -i '/^APP_PREVIOUS_KEYS=/d' .env
echo "APP_PREVIOUS_KEYS=$APP_KEY" >> .env

# 4. Restaurar configurações Nginx (se houver)
if [ -d /tmp/migracao-coolify/nginx-config ]; then
  cp -r /tmp/migracao-coolify/nginx-config/* /etc/nginx/
  systemctl reload nginx
fi
```

### Etapa 6: Reiniciar Coolify

**No servidor NOVO:**

```bash
# 1. Executar script de instalação novamente
# (Ele vai detectar que já está instalado e reconfigurar)
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 2. Verificar se containers iniciaram
docker ps | grep coolify

# Deve mostrar 5+ containers rodando

# 3. Verificar logs
docker logs coolify
docker logs coolify-db

# Não deve ter erros críticos
```

---

## ☁️ Método 3: Migração via S3 (Intermediário)

**Vantagens:**
- ✅ Não precisa de conectividade direta entre servidores
- ✅ Backup fica seguro na nuvem
- ✅ Útil se servidores estão em provedores diferentes
- ✅ Pode fazer em etapas (backup agora, restaurar depois)

**Tempo:** 45min-3h (+ tempo de upload/download)

### Passo 1: Configurar Backup S3

**No servidor ANTIGO:**

```bash
# 1. Configurar VPS Guardian para S3
sudo nano /etc/vpsguardian/backup-s3.conf
```

**Conteúdo:**
```bash
# Provedor S3
S3_PROVIDER="backblaze"  # ou aws, wasabi
S3_BUCKET="migracao-coolify"
S3_PREFIX="backups"
S3_REGION="us-west-002"
S3_ENDPOINT="https://s3.us-west-002.backblazeb2.com"
S3_ACCESS_KEY="seu_access_key"
S3_SECRET_KEY="seu_secret_key"

# NÃO criptografar (facilita restauração)
ENCRYPT_BACKUP=false

# Lifecycle manual
CONFIGURE_LIFECYCLE=false
```

### Passo 2: Fazer Backup para S3

**No servidor ANTIGO:**

```bash
# 1. Executar backup para S3
sudo vps-guardian backup-s3 --config=/etc/vpsguardian/backup-s3.conf

# 2. Aguardar upload (depende da velocidade)
# Progresso será mostrado

# 3. Anotar nome do arquivo
# Exemplo: 20241209_153045.tar.gz

# 4. Verificar no S3
aws s3 ls s3://migracao-coolify/backups/ --endpoint-url=...
```

### Passo 3: Preparar Servidor Novo

**No servidor NOVO:**

```bash
# 1. Instalar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 2. Instalar VPS Guardian
cd /opt
git clone https://github.com/SEU-USUARIO/vpsguardian.git
cd vpsguardian
sudo ./instalar.sh

# 3. Instalar AWS CLI
apt install awscli -y

# 4. Configurar mesmas credenciais S3
sudo nano /etc/vpsguardian/backup-s3.conf
# (mesmo conteúdo do servidor antigo)
```

### Passo 4: Baixar e Restaurar

**No servidor NOVO:**

```bash
# 1. Download do S3
cd /tmp
aws s3 cp s3://migracao-coolify/backups/20241209_153045.tar.gz . \
  --endpoint-url=https://s3.us-west-002.backblazeb2.com

# 2. Descompactar
tar -xzf 20241209_153045.tar.gz
cd 20241209_153045

# 3. Parar Coolify (exceto DB)
docker ps --filter name=coolify --format '{{.Names}}' | \
  grep -v 'coolify-db' | xargs docker stop

# 4. Restaurar banco
cat coolify-db-*.dmp | docker exec -i coolify-db \
  pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify

# 5. Restaurar SSH keys
rm -rf /data/coolify/ssh/keys/*
cp -r ssh-keys/* /data/coolify/ssh/keys/
chown -R 9999:9999 /data/coolify/ssh/keys

# 6. Atualizar .env
cd /data/coolify/source
APP_KEY=$(cat /tmp/20241209_153045/app-key.txt | cut -d '=' -f2-)
sed -i '/^APP_PREVIOUS_KEYS=/d' .env
echo "APP_PREVIOUS_KEYS=$APP_KEY" >> .env

# 7. Restaurar authorized_keys
cat /tmp/20241209_153045/authorized_keys >> /root/.ssh/authorized_keys

# 8. Reiniciar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

---

## ✅ Pós-Migração

### 1. Validação Completa

```bash
# No servidor NOVO:
sudo /opt/vpsguardian/scripts-auxiliares/validar-pos-migracao.sh

# Ou via menu:
vps-guardian
# → 1 (Status)
# → 1 (Verificação Completa)
```

**Checklist manual:**
- [ ] Coolify web acessível (http://IP:8000)
- [ ] Todas as aplicações listadas
- [ ] Banco de dados acessível
- [ ] SSH keys presentes
- [ ] Deploy de teste funciona
- [ ] Webhooks funcionando
- [ ] Volumes montados
- [ ] Configurações preservadas
- [ ] SSL funcionando (se aplicável)

### 2. Testar Aplicações

```bash
# Para cada aplicação:
# 1. Acessar via browser
curl -I https://app1.seu-dominio.com

# 2. Verificar logs
# Via Coolify dashboard → Application → Logs

# 3. Testar funcionalidades críticas
# Login, cadastro, operações principais

# 4. Verificar banco de dados da app
# Se a app tem banco próprio, verificar se está acessível
```

### 3. Configurar Firewall

```bash
# No servidor NOVO:
vps-guardian
# → 5 (Configuração)
# → 3 (Firewall)

# Ou:
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh

# Escolher perfil (recomendado: HÍBRIDO)
```

### 4. Configurar Backups Automáticos

```bash
# No servidor NOVO:
vps-guardian
# → 5 (Configuração)
# → 1 (Cron)

# Configurar:
# - Backup diário às 2h: backup-coolify.sh
# - Backup semanal S3 às 3h: backup-coolify-s3.sh
# - Limpeza semanal às 4h: limpar-backups-antigos.sh
```

### 5. Atualizar Documentação

**Atualizar:**
- Novo IP do servidor
- Novos acessos SSH
- Novos registros DNS
- Inventário de aplicações
- Procedimentos de backup
- Contatos de emergência

### 6. Monitoramento (primeiros 7 dias)

```bash
# Diariamente:
# 1. Verificar saúde do servidor
vps-guardian status

# 2. Verificar logs de erro
docker logs coolify | grep -i error | tail -50

# 3. Verificar disco
df -h

# 4. Verificar memória
free -h

# 5. Verificar aplicações
# Via Coolify dashboard
```

---

## 🆘 Troubleshooting

### Problema 1: "Erro ao conectar no banco de dados"

**Sintoma:**
```
Error: Connection refused (postgresql)
```

**Solução:**
```bash
# 1. Verificar se container do DB está rodando
docker ps | grep coolify-db

# 2. Se não estiver, iniciar
docker start coolify-db

# 3. Verificar logs
docker logs coolify-db

# 4. Testar conexão
docker exec coolify-db psql -U coolify -d coolify -c "SELECT 1;"

# 5. Se ainda não funcionar, restaurar novamente
cat /tmp/backup.dmp | docker exec -i coolify-db \
  pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify
```

---

### Problema 2: "Aplicações não aparecem no dashboard"

**Sintoma:**
Dashboard vazio, mas banco tem dados

**Solução:**
```bash
# 1. Verificar se banco foi restaurado
docker exec coolify-db psql -U coolify -d coolify \
  -c "SELECT id, name FROM applications LIMIT 5;"

# Se não retornar nada, banco não foi restaurado

# 2. Restaurar banco novamente
docker ps --filter name=coolify --format '{{.Names}}' | \
  grep -v 'coolify-db' | xargs docker stop

cat /tmp/backup.dmp | docker exec -i coolify-db \
  pg_restore --verbose --clean --no-acl --no-owner -U coolify -d coolify

# 3. Reiniciar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 4. Limpar cache do browser (Ctrl+Shift+R)
```

---

### Problema 3: "SSH keys não funcionam"

**Sintoma:**
```
Permission denied (publickey)
```

**Solução:**
```bash
# 1. Verificar se keys foram copiadas
ls -lh /data/coolify/ssh/keys/

# 2. Verificar permissões
stat /data/coolify/ssh/keys/

# Deve ser: 9999:9999 (usuário do Coolify)

# 3. Corrigir permissões
chown -R 9999:9999 /data/coolify/ssh/keys
chmod 700 /data/coolify/ssh/keys
chmod 600 /data/coolify/ssh/keys/*

# 4. Reiniciar Coolify
docker restart coolify
```

---

### Problema 4: "Volumes não montados"

**Sintoma:**
Aplicações não têm dados persistentes

**Solução:**
```bash
# 1. Listar volumes esperados
cat /tmp/migracao-coolify/volumes-list.txt

# 2. Listar volumes atuais
docker volume ls

# 3. Se volumes estão faltando:
# Opção A: Copiar do servidor antigo
# No servidor ANTIGO:
docker run --rm -v NOME_VOLUME:/volume -v $(pwd):/backup \
  busybox tar czf /backup/volume-backup.tar.gz -C /volume .

scp volume-backup.tar.gz root@IP-NOVO:/tmp/

# No servidor NOVO:
docker volume create NOME_VOLUME
docker run --rm -v NOME_VOLUME:/volume -v /tmp:/backup \
  busybox tar xzf /backup/volume-backup.tar.gz -C /volume

# Opção B: Usar script de migração de volumes
sudo /opt/vpsguardian/migrar/migrar-volumes.sh
```

---

### Problema 5: "SSL/Certificados não funcionam"

**Sintoma:**
```
NET::ERR_CERT_INVALID
```

**Solução:**
```bash
# 1. Aguardar propagação DNS (se IP mudou)
dig seu-dominio.com +short
# Deve retornar o IP novo

# 2. Renovar certificados no Coolify
# Dashboard → Server → SSL → Renew All

# 3. Se não funcionar, deletar e recriar
# Dashboard → Application → Settings → SSL → Delete & Recreate

# 4. Verificar portas abertas
ufw status | grep -E '80|443'

# Deve mostrar:
# 80/tcp ALLOW Anywhere
# 443/tcp ALLOW Anywhere
```

---

### Problema 6: "APP_KEY inválida"

**Sintoma:**
```
Error: Invalid APP_KEY
```

**Solução:**
```bash
# 1. Verificar APP_KEY antiga
cat /tmp/migracao-coolify/app-key.txt

# 2. Verificar .env atual
grep "APP_KEY" /data/coolify/source/.env

# 3. Adicionar APP_KEY antiga como APP_PREVIOUS_KEYS
cd /data/coolify/source
OLD_KEY=$(cat /tmp/migracao-coolify/app-key.txt | cut -d '=' -f2-)

sed -i '/^APP_PREVIOUS_KEYS=/d' .env
echo "APP_PREVIOUS_KEYS=$OLD_KEY" >> .env

# 4. Reiniciar Coolify
docker restart coolify

# 5. Executar migration (se necessário)
docker exec coolify php artisan migrate --force
```

---

## 🔙 Rollback

Se algo der muito errado e precisar voltar para o servidor antigo:

### Cenário 1: Servidor antigo ainda está online

```bash
# No servidor ANTIGO:

# 1. Iniciar Coolify novamente
docker start $(docker ps -aq --filter name=coolify)

# 2. Verificar se voltou
docker ps | grep coolify

# 3. Acessar dashboard
# http://IP-ANTIGO:8000

# 4. Reverter DNS (se mudou)
# No provedor DNS: voltar A record para IP antigo

# 5. Avisar usuários que voltou ao normal
```

### Cenário 2: Servidor antigo foi destruído

```bash
# Você precisará do BACKUP!

# Se tiver backup S3:
# 1. Provisionar novo servidor
# 2. Seguir "Método 3: Migração via S3"
# 3. Restaurar do último backup

# Se tiver apenas backup local:
# Esperamos que tenha copiado para outro lugar!
# Se não... não é possível recuperar 😢

# Por isso SEMPRE:
# - Faça backup antes de destruir servidor antigo
# - Mantenha backup em múltiplos locais
# - Teste restauração ANTES de destruir antigo
```

---

## 📋 Checklist Final

### Antes de Destruir Servidor Antigo

- [ ] Migração validada completamente
- [ ] Todas as aplicações funcionando
- [ ] DNS atualizado e propagado
- [ ] Backup do servidor antigo em local seguro
- [ ] Novo servidor rodando por 7+ dias sem problemas
- [ ] Monitoramento configurado
- [ ] Backups automáticos configurados
- [ ] Documentação atualizada
- [ ] Time avisado sobre novo servidor
- [ ] Credenciais atualizadas (senhas, keys, etc)

### Após 7 Dias

- [ ] Sem erros críticos nos logs
- [ ] Performance aceitável
- [ ] Backups funcionando
- [ ] Aplicações estáveis
- [ ] SSL funcionando
- [ ] Webhooks funcionando
- [ ] Deploys funcionando

**Só depois de tudo OK por 7 dias:**
- [ ] Fazer snapshot do servidor novo
- [ ] Cancelar/destruir servidor antigo
- [ ] Deletar backups temporários (mas manter alguns históricos!)

---

## 🎯 Dicas Profissionais

### 1. Reduza TTL DNS antes da migração
```
# 48h antes: TTL = 300 (5 minutos)
# Facilita mudança rápida de IP
```

### 2. Use screen/tmux para migração longa
```bash
# Iniciar sessão screen
screen -S migracao

# Se desconectar, reconectar com:
screen -r migracao
```

### 3. Documente tudo
```bash
# Criar log de migração
script -a migracao-$(date +%Y%m%d).log

# Tudo que você fizer será gravado
```

### 4. Faça em horário de baixo uso
```
# Menos impacto para usuários
# Mais fácil identificar problemas
```

### 5. Tenha plano B e plano C
```
Plano A: Migração automatizada
Plano B: Migração manual
Plano C: Rollback para servidor antigo
```

### 6. Teste antes em ambiente de staging
```
# Se possível, faça migração de teste primeiro
# Identifique problemas sem afetar produção
```

---

## 📞 Suporte

- **Logs:** `/var/log/vpsguardian/`
- **Documentação:** `/opt/vpsguardian/docs/`
- **Validação:** `sudo /opt/vpsguardian/scripts-auxiliares/validar-pos-migracao.sh`
- **Verificação de Saúde:** `vps-guardian status`

---

## 🎓 Resumo Rápido

**Migração Automatizada (Recomendado):**
```bash
# Servidor NOVO: Instalar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# Servidor ANTIGO: Migrar
vps-guardian
# → 4 (Migração) → 1 (Migrar Coolify Completo)

# Servidor NOVO: Validar
vps-guardian status

# Atualizar DNS se necessário
```

**Tempo total:** 30min-2h
**Downtime:** 30min-2h
**Dificuldade:** ⭐⭐ (Fácil/Médio)

---

**🚀 VPS Guardian - Migração Segura e Confiável**
