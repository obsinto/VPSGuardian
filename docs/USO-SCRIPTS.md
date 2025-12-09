# 📚 Guia de Uso dos Scripts - VPS Guardian

Documentação completa e objetiva de como usar cada script do VPS Guardian.

---

## 📋 Índice

- [🔵 Backup](#-backup)
  - [backup-coolify.sh](#backup-coolifysh)
  - [backup-databases.sh](#backup-databasessh)
  - [backup-destinos.sh](#backup-destinossh)
  - [backup-volume.sh](#backup-volumesh)
  - [restaurar-coolify-remoto.sh](#restaurar-coolify-remotosh)
  - [restaurar-volume-interativo.sh](#restaurar-volume-interativosh)
- [🔄 Migração](#-migração)
  - [migrar-coolify.sh](#migrar-coolifysh)
  - [migrar-volumes.sh](#migrar-volumessh)
  - [transferir-backups.sh](#transferir-backupssh)
- [🔧 Manutenção](#-manutenção)
  - [manutencao-completa.sh](#manutencao-completash)
  - [configurar-updates-automaticos.sh](#configurar-updates-automaticossh)
  - [firewall-perfil-padrao.sh](#firewall-perfil-padraosh)
  - [verificar-saude-completa.sh](#verificar-saude-completash)
- [🛠️ Auxiliares](#️-auxiliares)
  - [checklist-migracao.sh](#checklist-migracaosh)
  - [configurar-cron.sh](#configurar-cronsh)
  - [validar-pre-migracao.sh](#validar-pre-migracaosh)
  - [validar-pos-migracao.sh](#validar-pos-migracaosh)

---

## 🔵 Backup

### backup-coolify.sh

**Faz backup completo do Coolify incluindo banco de dados, SSH keys e configurações.**

**Uso:**
```bash
sudo /opt/vpsguardian/backup/backup-coolify.sh
```

**O que faz:**
1. ✅ Backup do banco de dados PostgreSQL (formato custom dump)
2. ✅ Backup das SSH keys do Coolify
3. ✅ Backup do arquivo `.env` e extração do `APP_KEY`
4. ✅ Backup das configurações do Nginx (se existir)
5. ✅ Backup do `authorized_keys` do root
6. ✅ Lista de todos os volumes Docker
7. ✅ Informações do sistema (SO, Docker version, recursos)
8. ✅ Compacta tudo em `.tar.gz`
9. ✅ Remove backups antigos (>30 dias por padrão)

**Output:**
```
/var/backups/vpsguardian/coolify/20241209_153045.tar.gz
```

**Logs:**
```bash
tail -f /var/log/vpsguardian/backup-coolify.log
```

**Personalizar retenção:**
Edite `config/default.conf`:
```bash
BACKUP_RETENTION_DAYS="30"  # Alterar para 60, 90, etc.
```

**Notificações (opcional):**
Edite o script e configure:
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/..."  # Discord/Slack
EMAIL="admin@example.com"  # Email
```

---

### backup-databases.sh

**Faz backup de bancos de dados individuais (PostgreSQL e MySQL).**

**Uso:**
```bash
sudo /opt/vpsguardian/backup/backup-databases.sh
```

**Interativo:**
- Lista todos os containers com banco de dados
- Permite selecionar quais fazer backup
- Suporta PostgreSQL e MySQL/MariaDB

**Exemplo:**
```
Containers de banco de dados encontrados:
  [1] coolify-db (PostgreSQL)
  [2] app-mysql (MySQL)
  [3] wordpress-db (MySQL)

Selecione os números (ex: 1 2 3):
```

**Output:**
```
/var/backups/vpsguardian/databases/coolify-db-20241209_153200.sql.gz
/var/backups/vpsguardian/databases/app-mysql-20241209_153201.sql.gz
```

---

### backup-destinos.sh

**Copia backups para destinos remotos (rsync/scp).**

**Uso:**
```bash
sudo /opt/vpsguardian/backup/backup-destinos.sh
```

**Pré-requisitos:**
- Configurar SSH keys sem senha
- Editar destinos no script

**Configuração:**
Edite o script e configure seus destinos:
```bash
DESTINOS=(
  "user@192.168.1.100:/backups/vps1/"
  "user@backup-server.com:/mnt/backups/"
  "user@cloud.example.com:/storage/backups/"
)
```

**Funcionalidades:**
- 🔄 Sincroniza via rsync (incremental)
- 🔒 Suporta SSH
- ✅ Verifica espaço disponível no destino
- 📊 Relatório de sincronização

---

### backup-volume.sh

**Backup interativo de volumes Docker específicos.**

**Uso:**
```bash
sudo /opt/vpsguardian/backup/backup-volume.sh
```

**Funcionalidades:**
1. Lista todos os volumes Docker disponíveis
2. Permite selecionar múltiplos volumes
3. Cria backup compactado de cada volume
4. Preserva permissões e timestamps

**Exemplo:**
```
Volumes Docker disponíveis:
  [1] app-data (500MB)
  [2] postgres-data (2GB)
  [3] redis-data (100MB)

Selecione volumes para backup (ex: 1 3): 1 2
```

**Output:**
```
/var/backups/vpsguardian/volumes/app-data-20241209.tar.gz
/var/backups/vpsguardian/volumes/postgres-data-20241209.tar.gz
```

**⚠️ Atenção:** Volumes grandes podem demorar e consumir muito espaço!

---

### restaurar-coolify-remoto.sh

**Restaura backup do Coolify em um servidor remoto totalmente automatizado.**

**Uso:**
```bash
sudo /opt/vpsguardian/backup/restaurar-coolify-remoto.sh
```

**Passo a passo interativo:**
1. 🌐 Solicita IP do servidor de destino
2. 👤 Solicita usuário SSH e porta
3. ✅ Testa conexão SSH
4. 📦 Lista backups disponíveis
5. ✅ Confirma operação
6. 🚀 Instala Coolify no destino (se necessário)
7. 📤 Transfere backup
8. 🗄️ Restaura banco de dados
9. 🔑 Restaura SSH keys
10. ⚙️ Restaura configurações
11. 🔄 Reinicia Coolify
12. ✅ Valida instalação

**Exemplo:**
```bash
IP do novo servidor: 192.168.1.50
Usuário SSH (padrão: root): root
Porta SSH (padrão: 22): 22

Backups disponíveis:
  [0] 20241209_120000.tar.gz - 2024-12-09 12:00:00 (850MB)
  [1] 20241208_120000.tar.gz - 2024-12-08 12:00:00 (820MB)

Selecione o número do backup: 0
```

**Pré-requisitos:**
- ✅ SSH configurado com chave (sem senha)
- ✅ Root access no servidor de destino
- ✅ Backup do Coolify disponível localmente

**Tempo estimado:** 10-20 minutos (depende do tamanho do backup)

---

### restaurar-volume-interativo.sh

**Restaura volumes Docker de backups de forma interativa.**

**Uso:**
```bash
sudo /opt/vpsguardian/backup/restaurar-volume-interativo.sh
```

**Funcionalidades:**
1. Lista backups de volumes disponíveis
2. Permite selecionar qual restaurar
3. Permite escolher nome do volume de destino
4. Restaura com permissões originais

**⚠️ Cuidado:** Restaurar um volume existente irá sobrescrever os dados!

**Exemplo:**
```
Backups de volumes disponíveis:
  [1] app-data-20241209.tar.gz (500MB)
  [2] postgres-data-20241209.tar.gz (2GB)

Selecione backup: 1
Nome do volume de destino (Enter para criar novo): app-data-restored
```

---

## 🔄 Migração

### migrar-coolify.sh

**Script completo e automatizado para migrar Coolify para novo servidor.**

**Uso:**
```bash
sudo /opt/vpsguardian/migrar/migrar-coolify.sh
```

**O que faz (TOTALMENTE AUTOMATIZADO):**
1. 🎯 Solicita dados do servidor de destino
2. 📦 Lista backups disponíveis
3. ✅ Valida APP_KEY e versão do Coolify
4. 🔑 Configura SSH com chave
5. 🚀 Instala Coolify no destino
6. 📤 Transfere backup completo
7. 🗄️ Restaura banco de dados
8. 🔑 Copia SSH keys
9. 📝 Atualiza `authorized_keys`
10. ⚙️ Configura APP_KEY no `.env`
11. 🔄 Executa install script final
12. ✅ Verifica containers rodando
13. 📊 Gera relatório completo

**Pré-requisitos:**
- ✅ Backup do Coolify criado (`backup-coolify.sh`)
- ✅ Servidor de destino com Ubuntu/Debian fresh
- ✅ SSH key configurada sem senha
- ✅ Root access em ambos servidores

**Exemplo completo:**
```bash
sudo ./migrar-coolify.sh

# Preencher:
IP do novo servidor: 192.168.1.50
Usuário SSH: root
Porta SSH: 22

# Selecionar backup
Backup [0]: 20241209_120000.tar.gz

# Confirmar migração
Proceed with migration? (yes/no): yes

# Aguardar 10-15 minutos
# Ao final, acessar: http://192.168.1.50:8000
```

**Logs gerados:**
```
/var/log/vpsguardian/migration-20241209_153045/
├── migration-agent.log
├── db-restore.log
├── coolify-install.log
├── coolify-final-install.log
└── docker-status.txt
```

**Próximos passos após migração:**
1. ✅ Acessar http://NOVO-IP:8000
2. ✅ Verificar todas aplicações estão listadas
3. ✅ Testar login e funcionalidades
4. ✅ Atualizar DNS para novo IP
5. ✅ Manter servidor antigo online por 24-48h

---

### migrar-volumes.sh

**Migra volumes Docker específicos para outro servidor.**

**Uso:**
```bash
sudo /opt/vpsguardian/migrar/migrar-volumes.sh
```

**Interativo:**
1. Lista volumes do servidor atual
2. Solicita servidor de destino
3. Permite selecionar volumes para migrar
4. Transfere via SSH
5. Recria volumes no destino

**Exemplo:**
```
Volumes disponíveis:
  [1] app-data
  [2] redis-data

IP destino: 192.168.1.50
Selecione volumes: 1 2
```

---

### transferir-backups.sh

**Transfere backups para servidor remoto via SSH.**

**Uso:**
```bash
sudo /opt/vpsguardian/migrar/transferir-backups.sh
```

**Funcionalidades:**
- 📤 Upload via SCP/rsync
- ✅ Verifica integridade (checksums)
- 🔄 Sincronização incremental
- 📊 Relatório de transferência

---

## 🔧 Manutenção

### manutencao-completa.sh

**Executa manutenção completa do servidor (limpeza, updates, verificações).**

**Uso:**
```bash
sudo /opt/vpsguardian/manutencao/manutencao-completa.sh
```

**O que faz:**
1. 🧹 Limpa logs antigos
2. 🗑️ Remove containers Docker parados
3. 🗑️ Remove imagens Docker órfãs
4. 🗑️ Remove volumes Docker não utilizados
5. 🗑️ Limpa cache do APT
6. 📦 Atualiza lista de pacotes
7. ⚠️ Lista pacotes com updates disponíveis
8. 🔍 Verifica espaço em disco
9. 🔍 Verifica uso de memória
10. 📊 Gera relatório completo

**Seguro:** NÃO instala updates automaticamente, apenas lista.

**Agendar mensalmente:**
```bash
# Executar dia 1 de cada mês às 4h
0 4 1 * * /opt/vpsguardian/manutencao/manutencao-completa.sh
```

---

### configurar-updates-automaticos.sh

**Configura updates de segurança automáticos com `unattended-upgrades`.**

**Uso:**
```bash
sudo /opt/vpsguardian/manutencao/configurar-updates-automaticos.sh
```

**Funcionalidades:**
1. ✅ Instala `unattended-upgrades`
2. ⚙️ Configura apenas updates de segurança
3. 📧 Configura email para notificações (opcional)
4. 🔄 Configura auto-reboot se necessário
5. ✅ Valida configuração

**Seguro:** Apenas updates de segurança críticos são instalados.

---

### firewall-perfil-padrao.sh

**Configura firewall UFW com perfil seguro padrão.**

**Uso:**
```bash
sudo /opt/vpsguardian/manutencao/firewall-perfil-padrao.sh
```

**Perfil criado:**
```
✅ SSH (22) - Permitido
✅ HTTP (80) - Permitido
✅ HTTPS (443) - Permitido
✅ Coolify (8000) - Permitido
✅ Docker (2375, 2376) - Bloqueado
❌ Todo resto - Bloqueado (padrão deny)
```

**⚠️ ATENÇÃO:** Certifique-se que SSH está funcionando antes de ativar!

**Verificar status:**
```bash
sudo ufw status verbose
```

---

### verificar-saude-completa.sh

**Verifica saúde completa do servidor (Docker, Coolify, recursos, rede).**

**Uso:**
```bash
sudo /opt/vpsguardian/manutencao/verificar-saude-completa.sh
```

**Verificações:**
- 🐳 Docker instalado e rodando
- 🔵 Coolify instalado e containers rodando
- 🗄️ Banco de dados Coolify acessível
- 💾 Espaço em disco disponível (>10%)
- 💾 Uso de memória (<90%)
- 🔌 Conectividade de rede
- 🌐 DNS funcionando
- 🔒 Firewall ativo

**Output:**
```
✅ Docker: OK
✅ Coolify: OK (5 containers rodando)
✅ Database: OK
✅ Disk: 45% usado (OK)
⚠️ Memory: 92% usado (AVISO)
✅ Network: OK
✅ DNS: OK
❌ Firewall: Inativo (CRÍTICO)

Score: 85/100 - BOM
```

**Agendar verificação diária:**
```bash
0 8 * * * /opt/vpsguardian/manutencao/verificar-saude-completa.sh
```

---

## 🛠️ Auxiliares

### checklist-migracao.sh

**Checklist interativo para validar migração passo a passo.**

**Uso:**
```bash
/opt/vpsguardian/scripts-auxiliares/checklist-migracao.sh
```

**Modos:**
1. **Pré-migração:** Valida servidor de origem
2. **Pós-migração:** Valida servidor de destino
3. **Checklist completo:** Guia interativo com 25+ itens

**Exemplo:**
```
VPS Guardian - Checklist de Migração

[1] Pré-migração (validar origem)
[2] Pós-migração (validar destino)
[3] Checklist interativo completo

Selecione: 3

✅ [1/25] Backup do Coolify criado?
✅ [2/25] SSH configurado no destino?
⬜ [3/25] Coolify instalado no destino?
...
```

---

### configurar-cron.sh

**Configura cron jobs para backups automáticos.**

**Uso:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/configurar-cron.sh
```

**Interativo:**
- Lista scripts disponíveis
- Permite escolher frequência (diária, semanal, mensal)
- Permite escolher horário
- Adiciona ao crontab automaticamente

**Exemplo:**
```
Scripts disponíveis:
  [1] backup-coolify.sh
  [2] backup-databases.sh
  [3] manutencao-completa.sh

Selecione script: 1
Frequência [diaria/semanal/mensal]: diaria
Horário (HH:MM): 02:00

✅ Cron job adicionado:
0 2 * * * /opt/vpsguardian/backup/backup-coolify.sh
```

---

### validar-pre-migracao.sh

**Valida servidor de origem ANTES de migrar.**

**Uso:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/validar-pre-migracao.sh
```

**30+ verificações automáticas:**
- ✅ Docker funcionando
- ✅ Coolify rodando
- ✅ Banco de dados acessível
- ✅ Backups criados recentemente
- ✅ SSH keys configuradas
- ✅ Espaço suficiente
- ✅ Conectividade de rede

**Output:**
```
========== VALIDAÇÃO PRÉ-MIGRAÇÃO ==========

SISTEMA:
✅ Docker instalado e rodando
✅ Coolify instalado (versão: 4.0.0)
✅ 5/5 containers rodando

BACKUPS:
✅ Backup mais recente: 2h atrás
✅ Tamanho do backup: 850MB

SSH:
✅ SSH key encontrada: /root/.ssh/id_rsa
✅ authorized_keys configurado

RECURSOS:
✅ Espaço em disco: 45% usado (OK)
✅ Memória disponível: 2GB

SCORE: 100% - PRONTO PARA MIGRAR! ✅
```

---

### validar-pos-migracao.sh

**Valida servidor de destino APÓS migração.**

**Uso Local:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/validar-pos-migracao.sh
```

**Uso Remoto:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/validar-pos-migracao.sh --remote 192.168.1.50
```

**40+ verificações automáticas:**
- ✅ Coolify instalado no destino
- ✅ Containers rodando
- ✅ Banco de dados com dados migrados
- ✅ SSH keys restauradas
- ✅ `.env` configurado corretamente
- ✅ APP_KEY presente
- ✅ Aplicações funcionando
- ✅ Logs sem erros críticos

**Output:**
```
========== VALIDAÇÃO PÓS-MIGRAÇÃO ==========

COOLIFY:
✅ Coolify instalado
✅ 5/5 containers rodando
✅ Acessível em http://192.168.1.50:8000

BANCO DE DADOS:
✅ PostgreSQL respondendo
✅ 15 aplicações migradas
✅ Usuários migrados: 3

CONFIGURAÇÕES:
✅ APP_KEY configurado
✅ SSH keys restauradas (12 keys)
✅ authorized_keys atualizado

APLICAÇÕES:
✅ 15/15 aplicações listadas
⚠️ 2 aplicações offline (verificar manualmente)

SCORE: 95% - MIGRAÇÃO BEM-SUCEDIDA! ✅
```

---

## 📞 Suporte

**Problemas ou dúvidas?**
1. Verifique os logs em `/var/log/vpsguardian/`
2. Execute `verificar-saude-completa.sh`
3. Consulte [INSTALACAO.md](./INSTALACAO.md#-troubleshooting)
4. Abra issue no GitHub

---

**🎉 Agora você sabe usar todos os scripts do VPS Guardian!**
