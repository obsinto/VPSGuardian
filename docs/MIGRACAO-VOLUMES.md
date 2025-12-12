# Migração de Volumes Docker

## Visão Geral

O VPS Guardian oferece um conjunto completo de ferramentas para migrar volumes Docker entre servidores de forma segura e eficiente.

## Scripts Disponíveis

### 1. `backup-volumes.sh` - Backup de Volumes

Cria backups comprimidos de volumes Docker.

**Uso:**
```bash
# Modo interativo
./migrar/backup-volumes.sh

# Backup de volume específico
./migrar/backup-volumes.sh --volume=meu-volume

# Backup de todos os volumes
./migrar/backup-volumes.sh --all

# Especificar diretório de saída
./migrar/backup-volumes.sh --all --output=/backup/volumes
```

**Características:**
- Backups comprimidos em `.tar.gz`
- Timestamp automático nos arquivos
- Symlink para backup mais recente
- Modo interativo com seleção de volumes
- Estimativa de tamanho dos volumes

**Saída padrão:** `./volume-backup/`

---

### 2. `transfer-volumes.sh` - Transferência de Backups

Transfere backups de volumes para servidor remoto via SSH/SCP.

**Uso:**
```bash
# Modo interativo
./migrar/transfer-volumes.sh

# Com arquivo de configuração
./migrar/transfer-volumes.sh --config=config.conf

# Modo automático (sem prompts)
./migrar/transfer-volumes.sh --config=config.conf --auto
```

**Arquivo de Configuração (config.conf):**
```bash
SSH_IP="192.168.1.100"
SSH_USER="root"
SSH_PORT="22"
SSH_KEY="/root/.ssh/id_rsa"
SOURCE_PATH="./volume-backup"
DESTINATION_PATH="/root/backups/volume-backup"
```

**Características:**
- Retry automático (3 tentativas)
- Verificação de conexão SSH
- Criação automática de diretórios remotos
- Progresso detalhado da transferência
- Resumo de transferências bem-sucedidas/falhas

---

### 3. `restore-volumes.sh` - Restauração de Volumes

Restaura volumes Docker a partir de backups.

**Uso:**
```bash
# Modo interativo
./migrar/restore-volumes.sh

# Restaurar volume específico
./migrar/restore-volumes.sh --volume=meu-volume --backup=./volume-backup/meu-volume-backup-20231210.tar.gz

# Restaurar todos os backups
./migrar/restore-volumes.sh --all --dir=./volume-backup
```

**Características:**
- Criação automática de volumes se não existirem
- Limpeza completa do volume antes da restauração
- Verificação de integridade do backup
- Modo interativo com seleção de backups
- Exibe informações de data e tamanho dos backups

**⚠️ ATENÇÃO:** A restauração sobrescreve completamente o conteúdo do volume!

---

### 4. `migrar-volumes.sh` - Migração Completa (Recomendado)

Script all-in-one que combina backup, transferência e restauração em um único fluxo.

**Uso:**
```bash
# Modo interativo
./migrar/migrar-volumes.sh
```

**Fluxo do Script:**

1. **Seleção de Backups**
   - Lista todos os backups disponíveis em `/root/volume-backups`
   - Permite seleção individual ou todos os volumes
   - Exibe informações de tamanho e data

2. **Configuração SSH**
   - Solicita IP do servidor de destino
   - Configura usuário e porta SSH
   - Testa conexão antes de iniciar

3. **Transferência e Restauração**
   - Transfere backups via SCP
   - Cria volumes no servidor remoto
   - Restaura dados automaticamente
   - Limpa backups temporários

4. **Verificação**
   - Conta arquivos restaurados em cada volume
   - Exibe relatório detalhado
   - Fornece comandos para validação manual

**Características:**
- Conexão SSH persistente (multiplex)
- Verificação de Docker no servidor remoto
- Logs detalhados em `volume-migration-logs/`
- Cleanup automático ao finalizar
- Resumo completo da migração

---

## Fluxos de Uso

### Fluxo 1: Migração Rápida (Recomendado)

Se você já tem backups criados:

```bash
# Execute o script de migração completa
cd /opt/vpsguardian
./migrar/migrar-volumes.sh
```

### Fluxo 2: Migração Manual em 3 Etapas

Para maior controle sobre o processo:

```bash
# 1. Criar backups
./migrar/backup-volumes.sh --all

# 2. Transferir para servidor remoto
./migrar/transfer-volumes.sh --config=minha-config.conf

# 3. No servidor remoto, restaurar volumes
./migrar/restore-volumes.sh --all
```

### Fluxo 3: Migração Seletiva

Para migrar apenas alguns volumes específicos:

```bash
# 1. Backup seletivo (modo interativo)
./migrar/backup-volumes.sh
# Selecione os volumes desejados

# 2. Transferir backups
./migrar/transfer-volumes.sh

# 3. No servidor remoto, restaurar
./migrar/restore-volumes.sh
# Selecione os backups para restaurar
```

---

## Pré-requisitos

### Servidor Origem
- Docker instalado e em execução
- Backups de volumes criados em `/root/volume-backups`
- Acesso root ou sudo

### Servidor Destino
- Docker instalado e em execução
- Acesso SSH configurado
- Chave SSH sem senha (recomendado)
- Espaço em disco suficiente

### Conectividade
- Acesso SSH entre servidores
- Portas necessárias abertas (SSH: 22 ou customizada)
- Latência de rede aceitável (para grandes volumes)

---

## Validação Pós-Migração

Após migrar volumes, valide no servidor de destino:

```bash
# 1. Listar volumes criados
docker volume ls

# 2. Verificar conteúdo de um volume
docker run --rm -v NOME_VOLUME:/volume busybox ls -lah /volume

# 3. Verificar tamanho do volume
docker run --rm -v NOME_VOLUME:/volume busybox du -sh /volume

# 4. Contar arquivos no volume
docker run --rm -v NOME_VOLUME:/volume busybox find /volume -type f | wc -l
```

---

## Troubleshooting

### Erro: "No volume backups found"
**Solução:** Execute primeiro `backup-volumes.sh` para criar backups.

### Erro: "SSH connection failed"
**Solução:**
- Verifique se a chave SSH está correta
- Teste manualmente: `ssh -i /root/.ssh/id_rsa root@IP`
- Verifique firewall no servidor destino

### Erro: "Docker is not installed on remote server"
**Solução:** Instale Docker no servidor de destino antes de migrar.

### Backup muito lento
**Solução:**
- Volumes grandes levam tempo
- Execute em horários de baixo uso
- Considere compressão reduzida (modifique script)

### Restauração falha
**Solução:**
- Verifique se o backup está íntegro: `tar -tzf backup.tar.gz`
- Verifique espaço em disco no servidor destino
- Verifique logs em `volume-migration-logs/`

---

## Boas Práticas

1. **Sempre faça backup antes de migrar**
   ```bash
   ./migrar/backup-volumes.sh --all
   ```

2. **Teste em volumes não-críticos primeiro**
   - Migre um volume de teste
   - Valide completamente
   - Depois migre volumes de produção

3. **Pare containers antes de backup**
   ```bash
   docker stop nome-container
   ./migrar/backup-volumes.sh --volume=volume-container
   docker start nome-container
   ```

4. **Verifique espaço em disco**
   ```bash
   # Origem
   df -h /root/volume-backups

   # Destino
   ssh root@IP "df -h /var/lib/docker/volumes"
   ```

5. **Monitore logs durante migração**
   ```bash
   tail -f volume-migration-logs/volume-migration-*.log
   ```

6. **Mantenha backups por segurança**
   - Não delete backups imediatamente
   - Valide completamente antes de limpar

---

## Exemplo Completo

### Cenário: Migrar volumes do servidor A para B

**Servidor A (origem):**
```bash
# 1. Listar volumes existentes
docker volume ls

# 2. Criar backups de todos os volumes
cd /opt/vpsguardian
./migrar/backup-volumes.sh --all

# 3. Verificar backups criados
ls -lh /root/volume-backups/

# 4. Executar migração
./migrar/migrar-volumes.sh
# Informar IP do servidor B: 192.168.1.100
# Selecionar volumes: all
# Confirmar: yes
```

**Servidor B (destino):**
```bash
# Após migração, validar volumes
docker volume ls

# Verificar conteúdo
docker run --rm -v meu-volume:/volume busybox ls -la /volume

# Iniciar containers que usam os volumes
docker-compose up -d
```

---

## Segurança

- Use chaves SSH ao invés de senhas
- Configure firewall para permitir apenas IPs conhecidos
- Use túnel SSH se necessário: `ssh -L 2222:destino:22 jump-server`
- Backups podem conter dados sensíveis - proteja adequadamente
- Considere criptografar backups antes de transferir

---

## Integração com Menu Principal

Acesse via menu principal:

```bash
vps-guardian
# Selecione: 3 → Migração
# Depois: 2 → Migrar Volumes Docker
```

---

## Logs e Debugging

Todos os scripts geram logs detalhados:

**backup-volumes.sh:** `/var/log/vpsguardian/backup-volumes.log`
**transfer-volumes.sh:** `/var/log/vpsguardian/transfer-volumes.log`
**restore-volumes.sh:** `/var/log/vpsguardian/restore-volumes.log`
**migrar-volumes.sh:** `./volume-migration-logs/volume-migration-TIMESTAMP.log`

Para debug:
```bash
# Verificar últimas linhas do log
tail -50 /var/log/vpsguardian/backup-volumes.log

# Buscar erros
grep -i error /var/log/vpsguardian/*.log

# Monitorar em tempo real
tail -f volume-migration-logs/volume-migration-*.log
```

---

## Próximos Passos

Após migrar volumes com sucesso:

1. Valide aplicações no novo servidor
2. Atualize DNS se necessário
3. Configure monitoramento
4. Agende backups regulares
5. Documente a nova infraestrutura
