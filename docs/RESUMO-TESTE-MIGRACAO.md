# 📋 Resumo: Como Testar a Migração

## 🎯 Objetivo
Você tem uma **VPS principal** com Coolify rodando e alugou uma **VPS de teste** para validar a migração antes de aplicar na produção.

---

## ⚡ Processo em 3 Comandos

### Na VPS Principal:

```bash
# 1. Instalar sistema
cd /opt && git clone <seu-repo> manutencao_backup_vps
cd manutencao_backup_vps && ./instalador.sh

# 2. Criar backup
vps-guardian backup

# 3. Migrar para VPS de teste
./migrar/migrar-coolify.sh
```

Pronto! Em ~10-15 minutos seu Coolify estará rodando na VPS de teste.

---

## 📝 Passo a Passo Detalhado

### 1. Preparar VPS Principal (5 min)

```bash
# Conectar na VPS principal
ssh root@SEU_IP_PRINCIPAL

# Instalar VPS Guardian
cd /opt
git clone https://github.com/SEU_USUARIO/manutencao_backup_vps.git
cd manutencao_backup_vps
./instalador.sh

# Confirmar instalação
vps-guardian --version
```

### 2. Validar Ambiente (2 min)

```bash
# Validação automática
./scripts-auxiliares/validar-pre-migracao.sh

# Deve mostrar:
# ✅ Sistema operacional OK
# ✅ Docker rodando
# ✅ Coolify ativo
# ✅ Banco de dados OK
```

### 3. Criar Backup (2-5 min)

```bash
# Via comando global
vps-guardian backup

# OU manualmente
cd /opt/manutencao_backup_vps
./backup/backup-coolify.sh

# Verificar
ls -lh /root/coolify-backups/
```

### 4. Preparar VPS de Teste (5 min)

```bash
# Da VPS PRINCIPAL, configurar SSH para VPS de TESTE

# Criar chave SSH (se não tiver)
ssh-keygen -t rsa -b 4096

# Copiar chave para VPS de teste
ssh-copy-id root@IP_VPS_TESTE

# Testar conexão
ssh root@IP_VPS_TESTE "echo 'SSH OK'"
```

### 5. Executar Migração (10-15 min)

```bash
# Na VPS PRINCIPAL
cd /opt/manutencao_backup_vps
./migrar/migrar-coolify.sh

# Quando solicitado:
# IP: [Digite IP da VPS de teste]
# User: root
# Port: 22
# Backup: [Selecione o mais recente]
# Confirmar: yes
```

**O que acontece:**
```
[ Migration Agent ] [ INFO ] Target server: X.X.X.X
[ Migration Agent ] [ SUCCESS ] SSH connection successful
[ Migration Agent ] [ INFO ] Installing Coolify on new server...
[ Migration Agent ] [ SUCCESS ] Coolify installed successfully
[ Migration Agent ] [ INFO ] Transferring files to new server...
[ Migration Agent ] [ SUCCESS ] Database dump transferred
[ Migration Agent ] [ SUCCESS ] SSH keys transferred
[ Migration Agent ] [ INFO ] Restoring Coolify database...
[ Migration Agent ] [ SUCCESS ] Database restore completed
[ Migration Agent ] [ INFO ] Running final Coolify install...
[ Migration Agent ] [ SUCCESS ] Coolify installation completed
[ Migration Agent ] [ SUCCESS ] ========== MIGRATION COMPLETE ==========
```

### 6. Validar Sucesso (2 min)

```bash
# Validação automática remota
./scripts-auxiliares/validar-pos-migracao.sh --remote IP_VPS_TESTE

# Deve mostrar:
# ✅ Coolify instalado
# ✅ Containers rodando (3+)
# ✅ Banco de dados OK
# ✅ HTTP responde na porta 8000
```

### 7. Testar Interface Web (2 min)

```
Abrir navegador:
http://IP_VPS_TESTE:8000

✅ Página carrega
✅ Fazer login (mesmas credenciais)
✅ Ver aplicações no dashboard
✅ Verificar configurações
```

---

## 🔄 Checklist Interativo (Recomendado)

Para um guia passo a passo completo com acompanhamento:

```bash
cd /opt/manutencao_backup_vps
./scripts-auxiliares/checklist-migracao.sh

# Selecionar: [1] Migração completa
```

O checklist irá:
- ✅ Guiar você por cada etapa
- ✅ Validar automaticamente quando possível
- ✅ Marcar progresso
- ✅ Gerar relatório final

---

## ✅ Critérios de Sucesso

A migração está 100% bem-sucedida quando:

1. ✅ Script de migração termina sem erros
2. ✅ Pelo menos 3 containers rodando na VPS de teste:
   - `coolify`
   - `coolify-db`
   - `coolify-proxy`
3. ✅ Interface web acessível: `http://IP_VPS_TESTE:8000`
4. ✅ Login funciona com credenciais originais
5. ✅ Dashboard mostra todas as aplicações
6. ✅ Configurações e variáveis de ambiente preservadas
7. ✅ Validação pós-migração passa sem erros críticos

---

## 🚨 Troubleshooting Rápido

### Problema: SSH não conecta

```bash
# Verificar chave
ssh-add -l

# Adicionar chave
ssh-add ~/.ssh/id_rsa

# Testar conexão
ssh -v root@IP_VPS_TESTE
```

### Problema: Coolify não inicia

```bash
# Conectar na VPS de teste
ssh root@IP_VPS_TESTE

# Ver containers
docker ps -a --filter name=coolify

# Ver logs
docker logs coolify
docker logs coolify-db

# Reiniciar
cd /data/coolify/source
docker compose restart
```

### Problema: Interface não carrega

```bash
# Na VPS de TESTE
curl -I http://localhost:8000

# Se não responder, reiniciar
docker restart coolify coolify-proxy
```

### Problema: Banco não restaurou

```bash
# Na VPS de TESTE
docker exec coolify-db pg_isready -U coolify

# Ver logs do banco
docker logs coolify-db --tail 100
```

---

## 📊 Tempo Estimado

| Etapa | Tempo |
|-------|-------|
| Instalar VPS Guardian | 2-3 min |
| Validação pré-migração | 1-2 min |
| Criar backup | 2-5 min |
| Configurar SSH | 2-3 min |
| Executar migração | 10-15 min |
| Validação pós-migração | 2-3 min |
| Teste interface web | 2-3 min |
| **TOTAL** | **25-35 min** |

---

## 📚 Documentação Adicional

### Guias Completos:
- **[Guia Detalhado de Teste](TESTE-MIGRACAO.md)** - 8 fases completas de validação
- **[Guia Rápido](GUIA-RAPIDO-MIGRACAO.md)** - Quick start em 5 passos
- **[README Principal](../README.md)** - Documentação geral do sistema

### Scripts Disponíveis:
- `validar-pre-migracao.sh` - Valida ambiente antes de migrar
- `validar-pos-migracao.sh` - Valida sucesso da migração
- `checklist-migracao.sh` - Checklist interativo completo
- `migrar-coolify.sh` - Script principal de migração
- `migrar-volumes.sh` - Migração de volumes individuais

---

## 🎉 Após Sucesso

1. ✅ Manter VPS de teste rodando por 24-48h
2. ✅ Testar todas as funcionalidades do Coolify
3. ✅ Fazer deploy de teste de uma aplicação
4. ✅ Verificar logs periodicamente
5. ✅ Documentar observações
6. ✅ Quando confortável, aplicar na VPS principal

---

## 💡 Dicas Importantes

1. **Sempre valide antes de migrar**
   ```bash
   ./scripts-auxiliares/validar-pre-migracao.sh
   ```

2. **Use o checklist interativo na primeira vez**
   ```bash
   ./scripts-auxiliares/checklist-migracao.sh
   ```

3. **Mantenha backups regulares**
   ```bash
   vps-guardian backup  # Diariamente
   ```

4. **Teste recuperação de desastre**
   - Destrua containers na VPS de teste
   - Execute migração novamente
   - Valide que tudo volta a funcionar

5. **Monitore logs**
   ```bash
   docker logs coolify --follow
   ```

---

## 🆘 Suporte

### Logs Importantes:
```bash
# Logs de migração
ls -lh /opt/manutencao_backup_vps/migration-logs/

# Logs de validação
ls -lh /tmp/*migration-validation*.log

# Logs do Coolify
docker logs coolify
docker logs coolify-db
```

### Verificações Rápidas:
```bash
# Status geral
docker ps --filter name=coolify

# Status do banco
docker exec coolify-db pg_isready -U coolify

# Testar HTTP
curl -I http://localhost:8000

# Ver uso de recursos
docker stats --no-stream
```

---

**Boa sorte com seu teste de migração! 🚀**

Se tudo correr bem (e deve correr!), você terá a confiança necessária para aplicar o processo na sua VPS principal quando necessário.
