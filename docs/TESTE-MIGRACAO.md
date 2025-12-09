# Guia Completo de Teste de Migração

## Objetivo
Garantir que a migração do Coolify e volumes Docker funcione com 100% de sucesso antes de aplicar na VPS principal.

## Infraestrutura de Teste

### VPS Principal (Origem)
- IP: [SEU_IP_PRINCIPAL]
- Coolify instalado e configurado
- Aplicações rodando

### VPS de Teste (Destino)
- IP: [SEU_IP_TESTE]
- Ubuntu/Debian limpo
- Acesso SSH configurado

---

## Fase 1: Preparação da VPS Principal (Origem)

### 1.1 Instalação do VPS Guardian na VPS Principal

```bash
cd /opt
git clone https://github.com/SEU_USUARIO/vpsguardian.git
cd vpsguardian
chmod +x instalador.sh
./instalador.sh
```

**Validações:**
- [ ] VPS Guardian instalado com sucesso
- [ ] Comando `vps-guardian` disponível no PATH
- [ ] Menu principal abre corretamente

### 1.2 Criar Backup do Coolify

```bash
vps-guardian backup
# Ou manualmente:
cd /opt/vpsguardian
./backup/backup-coolify.sh
```

**Validações:**
- [ ] Backup criado em `/root/coolify-backups/`
- [ ] Arquivo `.tar.gz` gerado com sucesso
- [ ] Tamanho do backup é razoável (não 0 bytes)
- [ ] Backup contém:
  - [ ] Dump do PostgreSQL (`.dmp`)
  - [ ] SSH keys (`ssh-keys/`)
  - [ ] Arquivo `.env`
  - [ ] `authorized_keys` (se existir)

**Verificar Backup:**
```bash
ls -lh /root/coolify-backups/
tar -tzf /root/coolify-backups/coolify-*.tar.gz | head -20
```

### 1.3 Criar Backup de Volumes Docker (Opcional)

Se você tem volumes Docker adicionais além do Coolify:

```bash
# Listar volumes
docker volume ls

# Fazer backup de volume específico
./backup/backup-volume.sh NOME_DO_VOLUME
```

**Validações:**
- [ ] Backups de volumes em `/root/volume-backups/`
- [ ] Cada volume tem seu `.tar.gz`

---

## Fase 2: Preparação da VPS de Teste (Destino)

### 2.1 Configurar Acesso SSH

Na **VPS Principal**, configure acesso SSH para a VPS de Teste:

```bash
# Se não tiver chave SSH, criar uma
ssh-keygen -t rsa -b 4096 -C "migracao-teste"

# Copiar chave para VPS de teste
ssh-copy-id -p 22 root@[IP_VPS_TESTE]

# Testar conexão
ssh root@[IP_VPS_TESTE] "echo 'Conexão OK'"
```

**Validações:**
- [ ] SSH conecta sem pedir senha
- [ ] Chave SSH funcionando
- [ ] Conexão estável

### 2.2 Garantir Requisitos na VPS de Teste

Na **VPS de Teste**, garantir que tem:

```bash
# Atualizar sistema
apt update && apt upgrade -y

# Instalar dependências
apt install curl wget git docker.io -y

# Verificar Docker
docker --version
```

**Validações:**
- [ ] Sistema atualizado
- [ ] Docker instalado e funcionando
- [ ] Espaço em disco suficiente (mínimo 10GB livres)

---

## Fase 3: Teste de Migração do Coolify

### 3.1 Executar Migração

Na **VPS Principal**:

```bash
cd /opt/vpsguardian
./migrar/migrar-coolify.sh
```

**Informações que serão solicitadas:**
- IP da nova VPS: `[IP_VPS_TESTE]`
- Usuário SSH: `root`
- Porta SSH: `22`
- Selecionar backup mais recente

**Acompanhar:**
- [ ] Script conecta via SSH com sucesso
- [ ] Coolify é instalado na VPS de teste
- [ ] Backup é transferido
- [ ] Banco de dados é restaurado
- [ ] SSH keys são copiadas
- [ ] `.env` é atualizado
- [ ] Containers são iniciados

### 3.2 Validação Pós-Migração

#### Na VPS de Teste, verificar:

```bash
# 1. Containers rodando
docker ps --filter name=coolify

# Deve mostrar pelo menos:
# - coolify-db
# - coolify-proxy
# - coolify (aplicação principal)

# 2. Verificar logs
docker logs coolify --tail 50
docker logs coolify-db --tail 50

# 3. Testar acesso ao Coolify
curl -I http://localhost:8000
# Deve retornar HTTP 200 ou redirect
```

**Validações:**
- [ ] Pelo menos 3 containers rodando
- [ ] Coolify-db está saudável
- [ ] Coolify responde na porta 8000
- [ ] Sem erros críticos nos logs

#### Acessar Interface Web:

```bash
# Abrir no navegador:
http://[IP_VPS_TESTE]:8000
```

**Validações:**
- [ ] Interface do Coolify carrega
- [ ] Login funciona (mesmas credenciais da VPS principal)
- [ ] Dashboard mostra aplicações migradas
- [ ] Projetos estão listados
- [ ] Configurações preservadas

### 3.3 Verificar Dados Migrados

No Coolify (VPS de Teste):

**Validações:**
- [ ] Todas as aplicações aparecem no dashboard
- [ ] Configurações de domínios preservadas
- [ ] Variáveis de ambiente preservadas
- [ ] SSH keys estão disponíveis
- [ ] Histórico de deploys visível (se aplicável)

---

## Fase 4: Teste de Migração de Volumes (Se Aplicável)

Se você fez backup de volumes adicionais:

### 4.1 Migrar Volumes

Na **VPS Principal**:

```bash
cd /opt/vpsguardian
./migrar/migrar-volumes.sh
```

**Selecionar:**
- IP: `[IP_VPS_TESTE]`
- Selecionar volumes para migrar (ou 'all')

### 4.2 Validar Volumes na VPS de Teste

```bash
# Listar volumes
docker volume ls

# Verificar conteúdo de um volume
docker run --rm -v NOME_VOLUME:/volume busybox ls -lah /volume

# Contar arquivos restaurados
docker run --rm -v NOME_VOLUME:/volume busybox find /volume -type f | wc -l
```

**Validações:**
- [ ] Volumes criados na VPS de teste
- [ ] Arquivos restaurados corretamente
- [ ] Número de arquivos bate com origem

---

## Fase 5: Teste de Recuperação

### 5.1 Simular Falha e Recuperação

Este teste valida que você consegue recuperar um backup rapidamente.

**Cenário:** Simular que perdeu a VPS de teste e precisa restaurar.

```bash
# Na VPS de TESTE, destruir o Coolify
cd /data/coolify/source
docker compose down
docker volume rm coolify-db

# Agora, tentar restaurar novamente
# Na VPS PRINCIPAL, executar novamente:
cd /opt/vpsguardian
./migrar/migrar-coolify.sh
```

**Validações:**
- [ ] Script detecta que Coolify não está rodando
- [ ] Instala Coolify novamente
- [ ] Restaura todos os dados
- [ ] Coolify volta a funcionar normalmente

### 5.2 Teste de Backup Incremental

Na **VPS de Teste**, fazer uma mudança e criar novo backup:

```bash
# 1. Fazer uma mudança no Coolify
# (criar um novo projeto, por exemplo)

# 2. Criar backup local na VPS de teste
cd /opt/vpsguardian
./backup/backup-coolify.sh

# 3. Verificar que novo backup foi criado
ls -lh /root/coolify-backups/
```

**Validações:**
- [ ] Novo backup criado
- [ ] Backup contém as mudanças recentes
- [ ] Tamanho do backup é consistente

---

## Fase 6: Teste de Configuração de Firewall

Agora que a migração funciona, testar configurações de segurança:

### 6.1 Configurar Firewall na VPS de Teste

```bash
vps-guardian firewall
```

**Validações:**
- [ ] UFW instalado e ativado
- [ ] Portas necessárias abertas (22, 80, 443, 8000)
- [ ] Coolify continua acessível
- [ ] SSH não é bloqueado

### 6.2 Testar Conectividade

```bash
# Da VPS PRINCIPAL, testar portas na VPS de TESTE
nc -zv [IP_VPS_TESTE] 22    # SSH
nc -zv [IP_VPS_TESTE] 80    # HTTP
nc -zv [IP_VPS_TESTE] 443   # HTTPS
nc -zv [IP_VPS_TESTE] 8000  # Coolify

# Testar acesso HTTP
curl -I http://[IP_VPS_TESTE]:8000
```

**Validações:**
- [ ] Todas as portas essenciais abertas
- [ ] Coolify acessível via HTTP
- [ ] SSH continua funcionando

---

## Fase 7: Teste de Updates Automáticos

### 7.1 Configurar Updates na VPS de Teste

```bash
vps-guardian updates
```

**Validações:**
- [ ] `unattended-upgrades` instalado
- [ ] Configuração aplicada
- [ ] Logs de updates disponíveis

---

## Fase 8: Limpeza e Documentação

### 8.1 Documentar Resultados

Criar arquivo com resultados dos testes:

```bash
cat > /root/teste-migracao-$(date +%Y%m%d).txt <<EOF
=== TESTE DE MIGRAÇÃO ===
Data: $(date)

VPS PRINCIPAL (Origem):
- IP: [SEU_IP_PRINCIPAL]
- Coolify Version: $(docker inspect coolify --format='{{.Config.Image}}')
- Aplicações: $(docker ps --filter name=coolify -q | wc -l) containers

VPS TESTE (Destino):
- IP: [SEU_IP_TESTE]
- Migração: SUCESSO
- Tempo de migração: [X minutos]
- Coolify funcionando: SIM
- Dados preservados: SIM

Backups Criados:
$(ls -lh /root/coolify-backups/ | tail -5)

Próximos Passos:
- Aplicar na VPS principal quando necessário
- Manter backups regulares
- Monitorar logs
EOF
```

### 8.2 Limpar VPS de Teste (Opcional)

Se quiser resetar a VPS de teste para novo teste:

```bash
# Na VPS de TESTE
cd /data/coolify/source
docker compose down
docker system prune -a --volumes -f
rm -rf /data/coolify
rm -rf /root/coolify-backups
rm -rf /root/volume-backups
```

---

## Checklist Final de Validação

Antes de considerar o teste completo, verificar:

### Migração do Coolify
- [ ] Backup criado com sucesso na VPS principal
- [ ] SSH configurado entre VPS principal e VPS teste
- [ ] Migração executada sem erros
- [ ] Coolify rodando na VPS de teste
- [ ] Login funcionando com credenciais originais
- [ ] Aplicações listadas no dashboard
- [ ] Configurações preservadas

### Dados e Volumes
- [ ] Banco de dados restaurado completamente
- [ ] SSH keys copiadas corretamente
- [ ] `.env` atualizado com novo IP
- [ ] Volumes Docker migrados (se aplicável)

### Segurança
- [ ] Firewall configurado e testado
- [ ] Portas essenciais abertas
- [ ] SSH não bloqueado
- [ ] Updates automáticos configurados

### Recuperação
- [ ] Testado cenário de recuperação de desastre
- [ ] Backup incremental funcionando
- [ ] Processo de restore validado

### Documentação
- [ ] Logs de migração salvos
- [ ] Resultados documentados
- [ ] Próximos passos definidos

---

## Troubleshooting Comum

### Problema: SSH não conecta durante migração

**Solução:**
```bash
# Verificar chave SSH
ssh-add -l

# Adicionar chave manualmente
ssh-add /root/.ssh/id_rsa

# Testar conexão
ssh -v root@[IP_VPS_TESTE]
```

### Problema: Coolify não inicia após migração

**Solução:**
```bash
# Verificar logs
docker logs coolify
docker logs coolify-db

# Verificar se banco está saudável
docker exec coolify-db pg_isready -U coolify

# Reiniciar containers
cd /data/coolify/source
docker compose restart
```

### Problema: Banco de dados não restaura

**Solução:**
```bash
# Verificar dump
cat /root/coolify-backup/db-dump.dmp | head -20

# Restaurar manualmente
docker exec -i coolify-db pg_restore \
  --verbose --clean --no-acl --no-owner \
  -U coolify -d coolify < /root/coolify-backup/db-dump.dmp
```

### Problema: APP_KEY não preservado

**Solução:**
```bash
# Extrair APP_KEY do backup
tar -xzf /root/coolify-backups/coolify-*.tar.gz -O .env | grep APP_KEY

# Atualizar manualmente
echo "APP_PREVIOUS_KEYS=SEU_APP_KEY_AQUI" >> /data/coolify/source/.env

# Reiniciar
cd /data/coolify/source
docker compose restart
```

---

## Próximos Passos Após Teste Bem-Sucedido

1. **Manter VPS de teste** por algumas semanas para testes adicionais
2. **Configurar backups automáticos** na VPS principal:
   ```bash
   vps-guardian cron
   ```
3. **Documentar processo** para equipe
4. **Planejar migração** da VPS principal quando necessário
5. **Configurar monitoramento** de backups

---

## Contato e Suporte

- Logs de migração: `/opt/vpsguardian/migration-logs/`
- Logs do Coolify: `docker logs coolify`
- Status do sistema: `vps-guardian status`

**Em caso de dúvidas:**
- Consultar README.md
- Verificar logs detalhados
- Testar em ambiente isolado primeiro
