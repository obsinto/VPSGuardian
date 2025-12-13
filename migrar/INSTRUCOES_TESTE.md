# 🧪 Instruções de Teste - Script Corrigido

## 📌 O Que Foi Corrigido

### Bug Crítico #1: APP_KEY nunca era encontrado
**Problema:** O script removia `$TEMP_EXTRACT_DIR` (linha 1094) ANTES de tentar ler a APP_KEY (linha 1125)

**Solução:** Movida a extração de APP_KEY para logo após a extração do backup (linhas 352-439)

---

## 🎯 Como Testar

### Teste 1: Validar Extração de APP_KEY (SEM executar migração)

```bash
cd /home/deyvid/Repositories/manutencao_backup_vps/migrar

# Tornar o script de teste executável
chmod +x test-app-key-logic.sh

# Executar teste com um backup real
./test-app-key-logic.sh /var/backups/vpsguardian/coolify/coolify-backup-XXXXXXXX.tar.gz
```

**Resultado Esperado:**
```
✅ RECOMENDAÇÃO: Usar Método Proposto (Busca Inteligente)
   É mais resiliente e funciona com diferentes estruturas de backup
```

---

### Teste 2: Simulação Dry-Run (Modo Seguro)

Antes de executar a migração real, você pode verificar se o script está lendo corretamente as chaves:

```bash
# Adicione estas linhas logo após a seção "Construir a String Final"
# Por volta da linha 1160 do script

# DEBUG: Mostrar o que será migrado
log_section "DEBUG: Preview da Migração"
echo "APP_PREVIOUS_KEYS que será aplicado no servidor novo:"
echo "$KEYS_TO_MIGRATE" | tr ',' '\n' | nl
echo ""
read -p "Continuar com a migração? (s/N): " CONTINUE
[[ ! "$CONTINUE" =~ ^[Ss]$ ]] && cleanup_and_exit 0
```

---

### Teste 3: Migração Real (Ambiente de Teste)

**⚠️ ATENÇÃO:** Faça primeiro em um servidor de TESTE, não em produção!

```bash
# Opção 1: Modo Interativo (Recomendado para primeira vez)
cd /home/deyvid/Repositories/manutencao_backup_vps/migrar
./migrar-coolify.sh

# Opção 2: Modo Automático (usando config file)
# Crie um arquivo de configuração:
cat > /tmp/migration-config.conf << 'EOF'
NEW_SERVER_IP="192.168.1.100"
NEW_SERVER_USER="root"
NEW_SERVER_PORT="22"
SSH_PRIVATE_KEY_PATH="/root/.ssh/id_rsa"
BACKUP_FILE="/var/backups/vpsguardian/coolify/coolify-backup-latest.tar.gz"
EOF

./migrar-coolify.sh --config=/tmp/migration-config.conf --auto
```

---

## 🔍 Pontos de Verificação Durante a Migração

### Checkpoint 1: Extração de Chaves (logo no início)
```
=== EXTRACTING BACKUP ===
🔍 Localizando chaves de criptografia no backup...

✅ Arquivo .env encontrado no backup!
   Localização: data/coolify/source/.env

✅ APP_KEY encontrado no backup
   Preview: base64:XXXXXXXXXXXX...

✅ APP_PREVIOUS_KEYS encontrado (2 chaves antigas)
```

**✅ PASS:** Se você ver as mensagens acima
**❌ FAIL:** Se aparecer "⚠️ Arquivo .env não encontrado" → Execute o test-app-key-logic.sh primeiro

---

### Checkpoint 2: Aplicação da Rotação
```
=== UPDATE APP_KEYS (Rotation) ===
⚠️ Aplicando rotação de chaves de criptografia...

📊 Estado das chaves:
  ✅ APP_KEY do backup: base64:XXXXXXXXXXXX...
  ✅ APP_PREVIOUS_KEYS: 2 chaves antigas

🔑 String de chaves para migração preparada.
```

**✅ PASS:** Se você ver "String de chaves preparada"
**❌ FAIL:** Se aparecer "❌ APP_KEY não encontrado" → ABORTE a migração

---

### Checkpoint 3: Transferência de Chaves SSH
```
=== TRANSFER SSH KEYS ===
✅ Chaves SSH disponíveis para transferência!
   Origem: /data/coolify/ssh/keys
   Total: 8 arquivos

✅ Comando SCP executado com sucesso!
✅ Permissões configuradas (9999:9999, 600)
✅ Chaves SSH transferidas com sucesso!
   Arquivos no servidor remoto: 8
```

**✅ PASS:** Se os números de arquivos baterem
**❌ FAIL:** Se "Arquivos no servidor remoto: 0" → Chaves não foram transferidas

---

## 🐛 Troubleshooting

### Problema: "APP_KEY não encontrado no backup"

**Causa:** O backup pode estar em formato diferente ou corrompido

**Solução:**
```bash
# 1. Verificar estrutura do backup
tar -tzf /path/to/backup.tar.gz | grep .env

# 2. Extrair manualmente e verificar
mkdir /tmp/test-backup
tar -xzf /path/to/backup.tar.gz -C /tmp/test-backup
find /tmp/test-backup -name ".env" -type f

# 3. Se encontrou, ver o conteúdo
cat /tmp/test-backup/.../path/to/.env | grep APP_KEY
```

---

### Problema: "SCP executou mas NENHUM arquivo foi transferido"

**Causa:** Permissões ou caminho incorreto

**Solução:**
```bash
# No servidor NOVO, verificar:
ssh root@NEW_SERVER_IP "ls -la /data/coolify/ssh/keys"

# Se não existir, criar manualmente:
ssh root@NEW_SERVER_IP "mkdir -p /data/coolify/ssh/keys && chown -R 9999:9999 /data/coolify/ssh/keys"
```

---

### Problema: "The MAC is invalid" após migração

**Causa:** APP_KEY não foi aplicada corretamente

**Solução:**
```bash
# No servidor NOVO, verificar:
ssh root@NEW_SERVER_IP "grep APP_PREVIOUS_KEYS /data/coolify/source/.env"

# Deve mostrar algo como:
# APP_PREVIOUS_KEYS=base64:OLD_KEY,base64:OLDER_KEY

# Se estiver vazio ou errado, aplicar manualmente:
ssh root@NEW_SERVER_IP "bash -s" << 'EOF'
  ENV_FILE="/data/coolify/source/.env"
  sed -i '/^APP_PREVIOUS_KEYS=/d' "$ENV_FILE"
  echo "APP_PREVIOUS_KEYS=SUA_KEY_AQUI,OUTRAS_KEYS" >> "$ENV_FILE"
  docker restart coolify
EOF
```

---

## 📊 Logs para Análise

Todos os logs são salvos em: `/var/log/vpsguardian/migration-YYYYMMDD_HHMMSS/`

```bash
# Ver log principal
tail -f /var/log/vpsguardian/migration-*/migration-agent.log

# Ver log de restore do banco
cat /var/log/vpsguardian/migration-*/db-restore.log | grep -i error

# Ver log de instalação do Coolify
cat /var/log/vpsguardian/migration-*/coolify-final-install.log
```

---

## ✅ Checklist Pós-Migração

Após a migração completar, verificar:

- [ ] Coolify está rodando: `docker ps | grep coolify`
- [ ] Status healthy: `docker inspect -f '{{.State.Health.Status}}' coolify`
- [ ] Login funciona: `http://NEW_SERVER_IP:8000`
- [ ] Projetos aparecem na dashboard
- [ ] Deployments funcionam
- [ ] Chaves SSH funcionam: Settings > SSH Keys
- [ ] Certificados SSL estão ativos (se aplicável)

---

## 🔄 Rollback (Se algo der errado)

Se a migração falhar, você tem 2 opções:

### Opção 1: Manter servidor antigo funcionando
```bash
# Simplesmente não aponte o DNS para o novo servidor
# Continue usando o servidor antigo normalmente
```

### Opção 2: Refazer a migração
```bash
# No servidor NOVO, limpar tudo:
ssh root@NEW_SERVER_IP "
  docker stop \$(docker ps -aq)
  docker rm \$(docker ps -aq)
  docker volume prune -f
  rm -rf /data/coolify
"

# Executar migração novamente:
./migrar-coolify.sh
```

---

## 📞 Suporte

Se encontrar problemas:

1. **Verificar logs:** `/var/log/vpsguardian/migration-*/`
2. **Executar teste:** `./test-app-key-logic.sh BACKUP_FILE`
3. **Verificar análise:** `cat ANALISE_VERSOES.md`

---

## 🎓 Referências

- **Análise Técnica:** `ANALISE_VERSOES.md`
- **Script de Teste:** `test-app-key-logic.sh`
- **Backup do Script Original:** `migrar-coolify.sh.backup-*`
- **Documentação Coolify:** https://coolify.io/docs

---

**Última atualização:** 2025-12-12
**Versão do Script:** 3.1 (Correção APP_KEY)
