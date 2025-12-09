# Guia Rápido: Teste de Migração

## 🎯 Objetivo
Testar a migração do Coolify da VPS Principal para VPS de Teste com **100% de confiança**.

---

## 🚀 Quick Start - 5 Passos

### Passo 1: Instalar na VPS Principal

```bash
# Na VPS PRINCIPAL
cd /opt
git clone https://github.com/SEU_USUARIO/vpsguardian.git
cd vpsguardian
./instalador.sh
```

### Passo 2: Validar Ambiente (Pré-Migração)

```bash
# Na VPS PRINCIPAL
vps-guardian
# Opção: Executar scripts auxiliares → Validar pré-migração

# OU manualmente:
cd /opt/vpsguardian
./scripts-auxiliares/validar-pre-migracao.sh
```

**Resultado esperado:** ✅ Todas as validações passam ou apenas warnings menores

### Passo 3: Criar Backup

```bash
# Na VPS PRINCIPAL
vps-guardian backup

# OU manualmente:
cd /opt/vpsguardian
./backup/backup-coolify.sh
```

**Verificar:**
```bash
ls -lh /root/coolify-backups/
# Deve mostrar arquivo .tar.gz com tamanho razoável
```

### Passo 4: Configurar SSH para VPS de Teste

```bash
# Na VPS PRINCIPAL
ssh-keygen -t rsa -b 4096 -C "teste-migracao"
ssh-copy-id root@[IP_VPS_TESTE]

# Testar
ssh root@[IP_VPS_TESTE] "echo 'SSH OK'"
```

### Passo 5: Executar Migração

```bash
# Na VPS PRINCIPAL
cd /opt/vpsguardian
./migrar/migrar-coolify.sh

# Quando solicitado:
# - IP: [IP_VPS_TESTE]
# - Usuário: root
# - Porta: 22
# - Selecionar backup mais recente
```

**Aguardar:** Script irá:
1. ✅ Conectar via SSH
2. ✅ Instalar Coolify na VPS de teste
3. ✅ Transferir backup
4. ✅ Restaurar banco de dados
5. ✅ Copiar SSH keys
6. ✅ Atualizar configurações
7. ✅ Iniciar containers

---

## 🔍 Validação Pós-Migração

### Opção 1: Validação Automática

```bash
# Na VPS PRINCIPAL
cd /opt/vpsguardian
./scripts-auxiliares/validar-pos-migracao.sh --remote [IP_VPS_TESTE]
```

### Opção 2: Validação Manual

```bash
# Conectar na VPS de TESTE
ssh root@[IP_VPS_TESTE]

# Verificar containers
docker ps --filter name=coolify

# Deve mostrar:
# - coolify
# - coolify-db
# - coolify-proxy

# Verificar logs
docker logs coolify --tail 50
docker logs coolify-db --tail 50

# Testar HTTP
curl -I http://localhost:8000
```

### Opção 3: Validação via Browser

```
http://[IP_VPS_TESTE]:8000
```

**Validar:**
- ✅ Interface carrega
- ✅ Login funciona (mesmas credenciais)
- ✅ Aplicações aparecem no dashboard
- ✅ Configurações preservadas

---

## 📋 Checklist Interativo (Recomendado)

Para acompanhar todo o processo passo a passo:

```bash
# Na VPS PRINCIPAL
cd /opt/vpsguardian
./scripts-auxiliares/checklist-migracao.sh

# Selecionar:
# [1] Migração completa (recomendado para primeira vez)
```

O checklist irá guiar você por cada etapa e marcar o progresso.

---

## ⚡ Comandos Essenciais

### Na VPS Principal

```bash
# Ver status
vps-guardian status

# Criar backup
vps-guardian backup

# Listar backups
ls -lh /root/coolify-backups/

# Executar migração
cd /opt/vpsguardian
./migrar/migrar-coolify.sh
```

### Na VPS de Teste (após migração)

```bash
# Ver containers
docker ps --filter name=coolify

# Ver logs
docker logs coolify
docker logs coolify-db

# Reiniciar Coolify
cd /data/coolify/source
docker compose restart

# Verificar banco
docker exec coolify-db pg_isready -U coolify

# Ver porta
netstat -tlnp | grep 8000
```

---

## 🔧 Troubleshooting Rápido

### Problema: SSH não conecta

```bash
# Verificar chave
ssh-add -l

# Adicionar chave
ssh-add ~/.ssh/id_rsa

# Testar com verbose
ssh -v root@[IP_VPS_TESTE]
```

### Problema: Coolify não inicia

```bash
# Na VPS de TESTE
docker logs coolify --tail 100
docker logs coolify-db --tail 100

# Reiniciar
cd /data/coolify/source
docker compose down
docker compose up -d
```

### Problema: Banco não restaura

```bash
# Verificar se banco está rodando
docker ps --filter name=coolify-db

# Testar conexão
docker exec coolify-db pg_isready -U coolify

# Ver logs do banco
docker logs coolify-db --tail 100
```

### Problema: Interface não carrega

```bash
# Verificar porta
curl -I http://localhost:8000

# Verificar proxy
docker logs coolify-proxy

# Reiniciar apenas aplicação
docker restart coolify
```

---

## 📊 Fluxo Completo Resumido

```
VPS PRINCIPAL                          VPS DE TESTE
─────────────                          ────────────

1. Instalar VPS Guardian
2. Validar ambiente (pré)
3. Criar backup
4. Configurar SSH
                    ─────────────────────────────────>
5. Executar migração                  6. Receber migração
                                      7. Instalar Coolify
                                      8. Restaurar dados
                                      9. Iniciar containers
                    <─────────────────────────────────
10. Validar (pós)
11. Testar interface                  ✅ Coolify funcionando!
```

---

## ✅ Critérios de Sucesso

A migração é considerada **100% bem-sucedida** quando:

- [ ] Script de migração executa sem erros
- [ ] Todos os containers do Coolify estão rodando
- [ ] Banco de dados está operacional
- [ ] Interface web acessível
- [ ] Login funciona com credenciais originais
- [ ] Aplicações aparecem no dashboard
- [ ] Configurações preservadas
- [ ] SSH keys copiadas
- [ ] Validação pós-migração passa sem erros críticos

---

## 📚 Documentação Completa

Para mais detalhes, consultar:
- `docs/TESTE-MIGRACAO.md` - Guia completo e detalhado
- `README.md` - Documentação geral do projeto

---

## 🆘 Suporte

**Logs importantes:**
- Pré-migração: `/tmp/pre-migration-validation-*.log`
- Migração: `/opt/vpsguardian/migration-logs/`
- Pós-migração: `/tmp/post-migration-validation-*.log`
- Coolify: `docker logs coolify`
- Banco: `docker logs coolify-db`

**Em caso de problemas:**
1. Revisar logs
2. Executar validações
3. Consultar troubleshooting
4. Testar em ambiente isolado

---

## 🎉 Próximos Passos Após Sucesso

1. ✅ Manter VPS de teste ativa por alguns dias
2. ✅ Testar todas as funcionalidades do Coolify
3. ✅ Configurar backups automáticos na VPS principal
4. ✅ Documentar o processo para sua equipe
5. ✅ Planejar migração da VPS principal quando necessário

---

**Tempo estimado do teste completo:** 30-60 minutos

**Boa sorte com sua migração! 🚀**
