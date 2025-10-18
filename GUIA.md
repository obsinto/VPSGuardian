# 📖 Guia Completo - Sistema de Manutenção e Backup VPS

Guia objetivo de todas as funcionalidades, separadas por tópicos, com instruções de uso e riscos explícitos.

---

## 📋 Índice

1. [Instalação](#1-instalação)
2. [Configuração de Cron Automático](#2-configuração-de-cron-automático)
3. [Backup de Bancos de Dados](#3-backup-de-bancos-de-dados) 🆕
4. [Backup do Coolify](#4-backup-do-coolify)
5. [Backup de Volumes Docker](#5-backup-de-volumes-docker)
6. [Backup Multi-destino](#6-backup-multi-destino)
7. [Restauração de Volumes](#7-restauração-de-volumes)
8. [Restauração do Coolify](#8-restauração-do-coolify)
9. [Manutenção Automatizada](#9-manutenção-automatizada)
10. [Updates Automáticos](#10-updates-automáticos)
11. [Migração de Servidor](#11-migração-de-servidor)
12. [Monitoramento](#12-monitoramento)

---

## 1. Instalação

### O que faz
Instala todos os scripts na estrutura padrão do Linux (FHS).

### Estrutura criada
- Scripts: `/opt/manutencao/`
- Logs: `/var/log/manutencao/`
- Backups Coolify: `/root/coolify-backups/`
- Backups Volumes: `/root/volume-backups/`
- Comandos globais: `/usr/local/bin/`

### Como usar
```bash
sudo ./instalar.sh
```

### Riscos
⚠️ **BAIXO** - Apenas copia arquivos, não modifica configurações do sistema.

---

## 2. Configuração de Cron Automático

### O que faz
Configura automaticamente todas as tarefas agendadas (cron jobs) do sistema:
- Backup semanal do Coolify
- Manutenção preventiva semanal
- Alerta de espaço em disco diário
- Rotação de logs mensal
- Upload automático de backups (opcional)

### Como usar
```bash
# Durante instalação (opção automática)
sudo ./instalar.sh
# Escolha "y" quando perguntado sobre cron

# Ou configurar manualmente depois
sudo /opt/manutencao/configurar-cron.sh
```

### Configurações interativas
O script pergunta:
1. **Dia e horário do backup do Coolify** (padrão: Domingo 02:00)
2. **Dia e horário da manutenção** (padrão: Segunda 03:00)
3. **Horário do alerta de disco** (padrão: Diário 09:00)
4. **Upload automático?** (opcional)
   - Destino: Self-hosted, Google Drive, S3 ou todos
   - Delay após backup (padrão: 1 hora)

### Features importantes
✅ Faz backup do crontab atual automaticamente
✅ Remove entradas antigas antes de adicionar novas
✅ Mostra próximas execuções calculadas
✅ Cria logs separados para cada tarefa
✅ Validação de scripts antes de configurar

### Riscos
⚠️ **MÉDIO** - Modifica crontab do root, pode sobrescrever configurações existentes.

**Recomendações:**
1. **Revise o crontab atual antes:** `sudo crontab -l`
2. **Backup é criado automaticamente** em `/root/crontab.backup.TIMESTAMP`
3. **Ajuste horários** para não conflitar com outras tarefas
4. **Evite horários de pico** de uso do servidor

### Comandos úteis
```bash
# Ver cron jobs configurados
sudo crontab -l

# Editar manualmente
sudo crontab -e

# Ver logs de execução
tail -f /var/log/manutencao/cron-backup.log
tail -f /var/log/manutencao/cron-manutencao.log
tail -f /var/log/manutencao/cron-alerta.log

# Restaurar backup do crontab
sudo crontab /root/crontab.backup.TIMESTAMP
```

---

## 3. Backup do Coolify

### O que faz
Cria backup completo do Coolify incluindo:
- Banco de dados PostgreSQL
- SSH keys (`/data/coolify/ssh/keys/`)
- Arquivo `.env` com configurações
- `authorized_keys` do servidor
- Configurações do Nginx (se existir)

### Onde salva
`/root/coolify-backups/YYYYMMDD_HHMMSS.tar.gz`

### Retenção
Mantém backups por 30 dias (configurável).

### Como usar
```bash
# Executar manualmente
sudo /opt/manutencao/backup-coolify.sh

# Ver backups existentes
ls -lh /root/coolify-backups/

# Ver log
tail -f /var/log/manutencao/backup-coolify.log
```

### Configurar notificações
```bash
sudo nano /opt/manutencao/backup-coolify.sh
# Edite as variáveis:
# EMAIL="seu-email@exemplo.com"
# WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

### Automatizar (cron)
```bash
sudo crontab -e
# Adicione:
0 2 * * 0 /opt/manutencao/backup-coolify.sh >> /var/log/manutencao/cron.log 2>&1
```

### Riscos
⚠️ **BAIXO** - Apenas lê dados, não modifica nada.

⚠️ **ATENÇÃO**: Backups contêm dados sensíveis (senhas, keys). Proteja o acesso ao servidor.

---

## 4. Backup de Volumes Docker

### O que faz
Cria backup de um volume Docker específico em formato `.tar.gz`.

### Onde salva
`/root/volume-backups/NOME_VOLUME-YYYYMMDD_HHMMSS.tar.gz`

### Como usar

**Modo simples:**
```bash
sudo backup-volume nome_do_volume
```

**Modo interativo:**
```bash
sudo backup-volume-interativo
# O script perguntará:
# - Nome do volume
# - Diretório de destino (padrão: /root/volume-backups)
# - Mostrará lista de backups existentes
```

### Listar volumes disponíveis
```bash
docker volume ls
```

### Riscos
⚠️ **MÉDIO** - Requer parar containers que usam o volume antes do backup para garantir consistência.

**Recomendação:** Pare o container antes:
```bash
docker stop nome_container
sudo backup-volume-interativo
docker start nome_container
```

---

## 5. Backup Multi-destino

### O que faz
Envia um backup existente para múltiplos destinos:
- **Self-hosted**: Servidor remoto via SSH/SCP
- **Google Drive**: Via rclone
- **AWS S3**: Via AWS CLI

### Pré-requisitos por destino

**Self-hosted:**
```bash
# Configurar SSH sem senha
ssh-keygen -t rsa -b 4096
ssh-copy-id root@IP_SERVIDOR_REMOTO
```

**Google Drive:**
```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Configurar (seguir wizard)
rclone config
# Escolher: Google Drive, nome: gdrive
```

**AWS S3:**
```bash
# Instalar AWS CLI
sudo apt install awscli -y

# Configurar
aws configure
# Informar: Access Key, Secret Key, Region

# Criar bucket
aws s3 mb s3://nome-bucket-backups
```

### Como usar
```bash
# Enviar backup para destinos
sudo /opt/manutencao/backup-destinos.sh /root/coolify-backups/BACKUP.tar.gz

# O script perguntará qual destino:
# [1] Self-hosted
# [2] Google Drive
# [3] AWS S3
# [4] Todos
```

### Custos
- **Self-hosted**: Custo do servidor remoto
- **Google Drive**: 15GB grátis, depois ~$2/mês por 100GB
- **AWS S3**: ~$0.023/GB/mês

### Riscos
⚠️ **BAIXO** - Apenas copia arquivos.

⚠️ **ATENÇÃO**:
- Backups em cloud podem ter custos
- Verifique se o provedor atende requisitos de privacidade/LGPD
- Configure lifecycle policies no S3 para evitar custos crescentes

---

## 6. Restauração de Volumes

### O que faz
Restaura um backup de volume Docker, localmente ou em servidor remoto.

### Como usar

**Restauração LOCAL:**
```bash
sudo restaurar-volume-interativo

# O script irá:
# 1. Perguntar nome do volume de destino
# 2. Listar backups disponíveis
# 3. Criar volume se não existir
# 4. Perguntar confirmação
# 5. Restaurar backup
# 6. Verificar arquivos restaurados
```

**Restauração REMOTA (da máquina antiga para nova):**
```bash
sudo restaurar-volume-interativo --remote 192.168.1.100

# O script irá:
# 1. Conectar via SSH no servidor remoto
# 2. Perguntar nome do volume
# 3. Criar volume no servidor remoto se necessário
# 4. Transferir backup via SCP
# 5. Restaurar remotamente
# 6. Limpar temporários
```

### Riscos
⚠️ **ALTO** - Sobrescreve dados do volume existente!

**Recomendações de segurança:**
1. **SEMPRE** pare containers antes:
   ```bash
   docker stop nome_container
   ```

2. Verifique se é o volume correto:
   ```bash
   docker volume ls
   docker run --rm -v VOLUME:/volume busybox ls -lah /volume
   ```

3. Faça backup do volume atual antes de sobrescrever (se contém dados importantes)

4. Após restauração, verifique os dados:
   ```bash
   docker run --rm -v VOLUME:/volume busybox ls -lah /volume
   ```

5. Inicie o container:
   ```bash
   docker start nome_container
   ```

---

## 7. Restauração do Coolify

### O que faz
Restaura backup completo do Coolify em um novo servidor, **totalmente remoto** da máquina antiga.

Restaura:
- Banco de dados PostgreSQL
- SSH keys
- Arquivo `.env`
- `authorized_keys` (opcional)

### Pré-requisitos
- Servidor novo com SSH habilitado
- Backup do Coolify disponível na máquina antiga

### Como usar
```bash
# Da máquina ANTIGA:
sudo /opt/manutencao/restaurar-coolify-remoto.sh

# O script irá perguntar:
# - IP do novo servidor
# - Usuário SSH (padrão: root)
# - Porta SSH (padrão: 22)
# - Qual backup usar (lista disponíveis)
# - Se quer restaurar authorized_keys

# Tempo estimado: 5-10 minutos
```

### O que o script faz automaticamente
1. Testa conexão SSH
2. Instala Coolify no novo servidor (se não estiver)
3. Transfere backup via SCP
4. Para Coolify temporariamente
5. Restaura banco de dados
6. Restaura SSH keys
7. Restaura configurações
8. Reinicia Coolify
9. Verifica se está funcionando

### Riscos
⚠️ **MUITO ALTO** - Sobrescreve completamente o Coolify no servidor de destino!

**Recomendações críticas:**

1. **Teste em servidor de desenvolvimento primeiro!**

2. **NUNCA execute em servidor de produção ativo** - Dados serão sobrescritos

3. Use em servidor novo/limpo para migração

4. **Mantenha servidor antigo ONLINE por 24-48h** após migração para rollback se necessário

5. Após restauração:
   - Acesse http://IP_NOVO:8000
   - Verifique todas as aplicações
   - Teste login
   - Verifique SSH keys funcionando

6. Atualize DNS apenas após confirmar que tudo funciona

---

## 8. Manutenção Automatizada

### O que faz
Executa manutenção preventiva completa:
- Atualiza lista de pacotes
- Limpa Docker (containers parados, imagens não usadas, build cache)
- Remove pacotes órfãos
- Remove kernels antigos (mantém apenas 2 últimos)
- Limpa logs antigos (>90 dias)
- Relatório de espaço recuperado

### Como usar
```bash
# Executar manualmente
sudo /opt/manutencao/manutencao-completa.sh

# Ver log
tail -f /var/log/manutencao/manutencao.log
```

### Automatizar (cron)
```bash
sudo crontab -e
# Adicione:
0 3 * * 1 /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron.log 2>&1
```

### Riscos
⚠️ **MÉDIO** - Remove recursos não utilizados.

**Atenções:**

1. **Limpeza de Docker** remove:
   - Containers parados
   - Imagens sem tag
   - Build cache
   - **NÃO remove volumes** (dados preservados)

2. **Kernels antigos** são removidos automaticamente (mantém 2 últimos)
   - Se usar kernel antigo por algum motivo, não execute este script

3. **Logs antigos** (>90 dias) são excluídos
   - Se precisa de logs antigos para auditoria, ajuste o período no script

**Recomendação:** Execute fora de horário de pico (madrugada).

---

## 9. Updates Automáticos

### O que faz
Configura `unattended-upgrades` para instalar automaticamente:
- Updates de segurança
- Updates regulares (opcional)
- Remove kernels antigos
- Remove dependências não usadas
- Reinicia automaticamente (opcional)
- Envia notificações por email (opcional)

### Como usar
```bash
sudo /opt/manutencao/configurar-updates-automaticos.sh

# O script perguntará:
# - Incluir updates regulares? (y/N)
# - Reiniciar automaticamente? (y/N)
# - Horário de reinício (padrão: 03:00)
# - Email para notificações
```

### Package Blacklist
Pacotes que NUNCA serão atualizados automaticamente (edite se necessário):
```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

# Exemplos já incluídos (comentados):
# "docker-ce";       // Docker Engine
# "docker-ce-cli";   // Docker CLI
# "containerd.io";   // Containerd
# "postgresql-*";    // PostgreSQL
```

### Verificar status
```bash
# Ver status do serviço
sudo systemctl status unattended-upgrades

# Ver log de updates
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log

# Executar update manualmente (dry-run)
sudo unattended-upgrade --dry-run --debug
```

### Riscos
⚠️ **ALTO** - Atualiza sistema automaticamente, pode causar incompatibilidades.

**Riscos específicos:**

1. **Updates regulares (além de segurança):**
   - Podem quebrar compatibilidade
   - **Recomendação:** Deixe DESABILITADO em produção

2. **Reinício automático:**
   - Causa downtime
   - **Recomendação:** Configure para madrugada (03:00) ou deixe DESABILITADO

3. **Docker/Coolify:**
   - Atualizar Docker pode quebrar Coolify
   - **Recomendação:** Adicione Docker no Package Blacklist

4. **PostgreSQL:**
   - Atualizar pode quebrar compatibilidade com Coolify
   - **Recomendação:** Adicione PostgreSQL no Package Blacklist

**Configuração recomendada para produção:**
- ✅ Updates de segurança: HABILITADO
- ❌ Updates regulares: DESABILITADO
- ❌ Reinício automático: DESABILITADO (ou configure para madrugada)
- ✅ Blacklist: Docker, PostgreSQL

---

## 10. Migração de Servidor

### 10.1 Migração do Coolify

**Ver:** [Restauração do Coolify](#7-restauração-do-coolify)

### 10.2 Migração de Volumes

#### O que faz
Migra múltiplos volumes Docker de uma vez usando backups existentes.

#### Como usar
```bash
sudo /opt/manutencao/migrar-volumes.sh

# O script irá:
# 1. Listar backups de volumes disponíveis
# 2. Permitir selecionar quais migrar (ou "all")
# 3. Transferir e restaurar cada um
```

#### Riscos
⚠️ **ALTO** - Mesmo risco da restauração de volumes.

Ver riscos em: [Restauração de Volumes](#5-restauração-de-volumes)

### 9.3 Transferência de Backups

#### O que faz
Apenas transfere backups do Coolify para servidor remoto (não restaura).

#### Quando usar
- Backup off-site
- Preparação para migração manual
- Cópia de segurança

#### Como usar
```bash
sudo /opt/manutencao/transferir-backups.sh

# Informar: IP, usuário, porta, diretório de destino
```

#### Riscos
⚠️ **BAIXO** - Apenas copia arquivos.

---

## 11. Monitoramento

### 11.1 Dashboard de Status

#### O que mostra
- Uso de disco e memória
- Status do Docker
- Status do Coolify
- Última manutenção executada
- Último backup criado
- Updates pendentes
- Próximas execuções do cron

#### Como usar
```bash
status-completo
```

#### Riscos
⚠️ **NENHUM** - Apenas lê informações.

### 11.2 Alertas de Disco

#### O que faz
Verifica uso de disco e alerta se >80%.

#### Como usar
```bash
# Executar manualmente
sudo /opt/manutencao/alerta-disco.sh

# Automatizar (cron)
sudo crontab -e
# Adicione:
0 9 * * * /opt/manutencao/alerta-disco.sh >> /var/log/manutencao/cron.log 2>&1
```

#### Configurar notificações
```bash
sudo nano /opt/manutencao/alerta-disco.sh
# Edite: EMAIL ou WEBHOOK_URL
```

#### Riscos
⚠️ **NENHUM** - Apenas lê informações e notifica.

### 11.3 Teste do Sistema

#### O que faz
Testa todas as funcionalidades instaladas:
- Scripts existem e têm permissão de execução
- Diretórios existem
- Comandos globais funcionam
- Docker está rodando
- Coolify está rodando

#### Como usar
```bash
sudo /opt/manutencao/test-sistema.sh
```

#### Riscos
⚠️ **NENHUM** - Apenas testa, não modifica nada.

---

## 📊 Resumo de Riscos por Funcionalidade

| Funcionalidade | Risco | Requer parar containers? | Pode causar downtime? |
|----------------|-------|--------------------------|----------------------|
| Instalação | Baixo | Não | Não |
| Configuração Cron | Médio | Não | Não |
| Backup Coolify | Baixo | Não | Não |
| Backup Volume | Médio | Sim (recomendado) | Não |
| Backup Multi-destino | Baixo | Não | Não |
| Restauração Volume | Alto | **SIM** | Sim (durante restauração) |
| Restauração Coolify | Muito Alto | **SIM** | Sim (5-10 minutos) |
| Manutenção | Médio | Não | Não |
| Updates Automáticos | Alto | Não | Pode (se reiniciar) |
| Migração | Alto | **SIM** | Sim |
| Monitoramento | Nenhum | Não | Não |

---

## 🔒 Melhores Práticas de Segurança

1. **Backups:**
   - Mantenha 3 cópias (local + 2 off-site)
   - Teste restauração mensalmente
   - Proteja acesso aos backups (contêm senhas)

2. **Updates:**
   - Apenas segurança em produção
   - Adicione Docker/PostgreSQL no blacklist
   - Desabilite reinício automático ou configure para madrugada

3. **Restauração:**
   - **SEMPRE** teste em ambiente de dev primeiro
   - Pare containers antes
   - Mantenha servidor antigo online após migração

4. **Monitoramento:**
   - Configure alertas de disco
   - Revise logs semanalmente
   - Execute status-completo diariamente

5. **Acesso:**
   - Use chaves SSH (não senhas)
   - Restrinja acesso root
   - Configure firewall (ufw)

---

## 📞 Troubleshooting

### Backup falha
```bash
# Verificar se Coolify está rodando
docker ps | grep coolify

# Ver erros
tail -100 /var/log/manutencao/backup-coolify.log

# Verificar espaço em disco
df -h
```

### Restauração falha
```bash
# Verificar se volume existe
docker volume ls

# Verificar se container está parado
docker ps | grep nome_container

# Ver log detalhado do script
```

### Updates automáticos não funcionam
```bash
# Verificar serviço
sudo systemctl status unattended-upgrades

# Ver log
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log

# Testar manualmente
sudo unattended-upgrade --dry-run --debug
```

### Migração falha
```bash
# Verificar conexão SSH
ssh root@IP_NOVO exit

# Verificar espaço em disco no servidor novo
ssh root@IP_NOVO "df -h"

# Ver logs do script
tail -100 migration-logs/migration-*.log
```

---

**🎯 Fim do Guia**

Para mais informações, consulte o README.md ou os comentários dentro de cada script.
