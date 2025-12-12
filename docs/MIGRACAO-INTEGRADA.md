# Migração Integrada: Coolify + Volumes/Apps

## 🎯 Visão Geral

Após migrar o Coolify com sucesso, o sistema agora oferece automaticamente a opção de migrar os volumes das aplicações (apps) no mesmo fluxo, sem precisar reconfigurar servidor, SSH ou outras credenciais.

## 🚀 Como Funciona

### Fluxo Integrado

```
1. Migração do Coolify
   ↓
2. ✅ Coolify migrado com sucesso
   ↓
3. 🔔 Pergunta: "Deseja migrar volumes dos apps agora?"
   ↓
4a. [SIM] → Inicia migração de volumes automaticamente
    • Reutiliza conexão SSH do Coolify
    • Usa mesmas credenciais (IP, usuário, porta)
    • Não precisa reconfigurar nada
   ↓
5. ✅ Migração completa (Coolify + Apps)

4b. [NÃO] → Finaliza migração
    • Coolify migrado
    • Volumes podem ser migrados depois manualmente
```

## ✨ Vantagens da Integração

### 1. Experiência Fluida
- **Sem reconfiguração**: Não precisa informar IP, usuário, porta novamente
- **Conexão reutilizada**: Usa a mesma conexão SSH já estabelecida
- **Fluxo contínuo**: Tudo em uma única execução

### 2. Eficiência
- **Menos tempo**: Não precisa autenticar SSH duas vezes
- **Menos erros**: Credenciais já validadas na migração do Coolify
- **Automação**: Variáveis passadas automaticamente entre scripts

### 3. Flexibilidade
- **Opcional**: Pode escolher migrar volumes depois
- **Seletivo**: Escolhe quais volumes migrar
- **Seguro**: Pode cancelar a qualquer momento

## 📋 Uso Passo a Passo

### 1. Iniciar Migração do Coolify

```bash
cd /opt/vpsguardian/migrar
./migrar-coolify.sh
```

### 2. Aguardar Conclusão do Coolify

O script irá:
- Migrar banco de dados
- Migrar volumes do Coolify
- Transferir configurações
- Verificar saúde dos containers

### 3. Responder à Pergunta

Após sucesso, você verá:

```
╔══════════════════════════════════════════════════════╗
║         MIGRATE APPLICATION VOLUMES?                 ║
╚══════════════════════════════════════════════════════╝

  Coolify has been migrated successfully!
  Do you want to migrate your application volumes/data now?

  This will:
    • List all Docker volumes on the current server
    • Let you select which volumes to migrate
    • Transfer and restore them on 192.168.1.100

  Migrate application volumes? (yes/no): _
```

### 4. Se Escolher "yes"

O sistema irá:

1. **Listar volumes disponíveis**
   ```
   Available volume backups:
     [0] my-app-data-backup-20231210.tar.gz
     [1] postgres-data-backup-20231210.tar.gz
     [2] redis-data-backup-20231210.tar.gz
   ```

2. **Solicitar seleção**
   ```
   Select volumes to migrate:
     - Enter numbers separated by spaces (e.g., 0 2)
     - Enter 'all' to migrate all volumes
     - Enter 'none' to cancel
   Selection: _
   ```

3. **Executar migração**
   - Transfere volumes selecionados
   - Restaura no servidor destino
   - Valida integridade

4. **Exibir resultado**
   ```
   ✅ Successfully migrated: 3 volumes
   📍 Remote server: 192.168.1.100
   ```

### 5. Se Escolher "no"

```
Volume migration skipped.

You can migrate volumes later by running:
/opt/vpsguardian/migrar/migrar-volumes.sh
```

## 🔧 Detalhes Técnicos

### Variáveis Exportadas

O `migrar-coolify.sh` exporta automaticamente:

```bash
export NEW_SERVER_IP          # IP do servidor destino
export NEW_SERVER_USER        # Usuário SSH (ex: root)
export NEW_SERVER_PORT        # Porta SSH (ex: 22)
export SSH_PRIVATE_KEY_PATH   # Caminho da chave SSH
export CONTROL_SOCKET         # Socket da conexão SSH persistente
```

### Reutilização de Conexão SSH

O `migrar-volumes.sh` verifica:

1. **Conexão existente?**
   ```bash
   if [ -n "$CONTROL_SOCKET" ] && [ -S "$CONTROL_SOCKET" ]; then
       # Verifica se ainda está ativa
       ssh -S "$CONTROL_SOCKET" -O check "$NEW_SERVER_USER@$NEW_SERVER_IP"
   ```

2. **Se ativa:** Reutiliza
   ```
   ✓ Reusing existing SSH connection from Coolify migration.
   ```

3. **Se não ativa:** Cria nova
   ```
   ⚠ Existing SSH connection is not active, creating new one...
   ```

### Cleanup Inteligente

O `migrar-volumes.sh` preserva a conexão SSH do pai:

```bash
cleanup_and_exit() {
    # Só fecha conexão se foi criada por este script
    if [ "$SSH_REUSED" != "true" ]; then
        ssh -S "$CONTROL_SOCKET" -O exit ...
    else
        # Mantém para o script pai
    fi
}
```

## 📊 Exemplo Completo

### Cenário: Migrar Coolify + 3 Apps

```bash
# 1. Iniciar migração
$ ./migrar-coolify.sh

# 2. Informar destino (apenas uma vez)
Enter the NEW server IP: 192.168.1.100
SSH user (default: root): root
SSH port (default: 22): 22

# 3. Aguardar migração do Coolify
[... migração em andamento ...]

# 4. Coolify migrado com sucesso
🎉 Coolify has been migrated successfully!

# 5. Pergunta aparece
Migrate application volumes? (yes/no): yes

# 6. Sistema reutiliza conexão
✓ Reusing existing SSH connection from Coolify migration.

# 7. Selecionar volumes
Available volume backups:
  [0] app1-data-backup.tar.gz
  [1] app2-data-backup.tar.gz
  [2] app3-data-backup.tar.gz

Selection: all

# 8. Migração executa
Transferring backup: app1-data-backup.tar.gz... ✓
Transferring backup: app2-data-backup.tar.gz... ✓
Transferring backup: app3-data-backup.tar.gz... ✓

# 9. Conclusão
✅ Successfully migrated: 3 volumes
✅ Coolify + All Apps migrated successfully!
```

**Tempo total:** ~15-30 minutos (dependendo do tamanho)
**Configurações manuais:** Apenas 1 vez (no início)

## 🎯 Quando Usar Cada Opção

### ✅ Escolher "yes" quando:
- Quer migrar tudo de uma vez
- Tem todos os backups prontos
- Está em janela de manutenção
- Tempo não é crítico (volumes grandes)

### ❌ Escolher "no" quando:
- Precisa validar Coolify primeiro
- Vai migrar volumes em outro horário
- Backups de volumes não estão prontos
- Quer controle mais fino sobre o processo

## 📚 Documentação Relacionada

- **Migração de Volumes:** `docs/MIGRACAO-VOLUMES.md`
- **Quick Start Volumes:** `docs/QUICK-START-VOLUMES.md`
- **Teste de Migração:** `TESTE-MIGRACAO.md`

## 🔍 Troubleshooting

### Pergunta não aparece

**Causa:** Script terminou com erro antes

**Solução:** Verifique logs de migração do Coolify

---

### Erro: "Volume migration script not found"

**Causa:** Arquivo `migrar-volumes.sh` não existe

**Solução:**
```bash
ls -la /opt/vpsguardian/migrar/migrar-volumes.sh
chmod +x /opt/vpsguardian/migrar/migrar-volumes.sh
```

---

### Erro: "Existing SSH connection is not active"

**Causa:** Conexão SSH do Coolify foi fechada

**Solução:** Sistema cria nova automaticamente, nenhuma ação necessária

---

### Volumes não aparecem na lista

**Causa:** Backups não foram criados antes

**Solução:**
```bash
# Criar backups primeiro
cd /opt/vpsguardian
./migrar/backup-volumes.sh --all

# Depois executar migração novamente
./migrar/migrar-volumes.sh
```

---

### Quer cancelar durante migração de volumes

**Solução:** Pressione `Ctrl+C`
- Coolify já está migrado (seguro)
- Volumes parcialmente migrados serão mantidos
- Pode continuar manualmente depois

---

## 🎓 Boas Práticas

### 1. Preparação
```bash
# Antes de migrar, crie backups de volumes
./migrar/backup-volumes.sh --all

# Verifique se backups foram criados
ls -lh /root/volume-backups/
```

### 2. Durante Migração
- Não feche o terminal durante o processo
- Monitore logs em caso de erro
- Mantenha conexão de rede estável

### 3. Após Migração
```bash
# Validar Coolify
curl http://NOVO_IP:8000

# Validar volumes migrados
ssh root@NOVO_IP "docker volume ls"

# Testar aplicações
ssh root@NOVO_IP "docker ps -a"
```

### 4. Migração Gradual (Recomendado)
```bash
# Dia 1: Migrar Coolify (escolher "no" para volumes)
./migrar-coolify.sh

# Validar Coolify funcionando

# Dia 2: Migrar volumes críticos
./migrar-volumes.sh
# Selecionar apenas apps críticos

# Dia 3: Migrar volumes restantes
./migrar-volumes.sh
# Selecionar apps não-críticos
```

## 🚀 Próximos Passos

Após migração completa:

1. **Atualizar DNS** para apontar para novo servidor
2. **Testar todas as aplicações** via Coolify
3. **Configurar backups** no novo servidor
4. **Monitorar** por 24-48h antes de desligar servidor antigo
5. **Documentar** qualquer customização específica

---

**Última atualização:** 2025-12-11
**Versão:** 1.0
