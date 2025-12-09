# Retenção de Backups

Estratégias para gerenciar espaço em disco e custos de armazenamento.

---

## Configuração Global

Arquivo: `/opt/vpsguardian/config/default.conf`

```bash
BACKUP_RETENTION_STRATEGY="simple"  # simple, count ou gfs
BACKUP_RETENTION_DAYS="30"          # Para simple (deletar >30 dias)
BACKUP_RETENTION_COUNT="10"         # Para count (manter últimos 10)
LOCAL_BACKUP_RETENTION_DAYS="7"     # Manter dias localmente após upload S3
```

---

## 3 Estratégias de Retenção

### 1. SIMPLE (Por Idade)
Deleta backups mais antigos que X dias. Mantém todos dentro do período.

```bash
BACKUP_RETENTION_STRATEGY="simple"
BACKUP_RETENTION_DAYS="30"

# Comando
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30
```

**Resultado:** 30 backups mantidos (~6GB para 200MB cada)

---

### 2. COUNT (Por Quantidade)
Mantém últimos X backups, independente da idade.

```bash
BACKUP_RETENTION_STRATEGY="count"
BACKUP_RETENTION_COUNT="10"

# Comando
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=count --count=10
```

**Resultado:** 10 backups mantidos (~2GB para 200MB cada)

---

### 3. GFS (Grandfather-Father-Son)
- **Diários:** últimos 7 dias (todos)
- **Semanais:** últimas 4 semanas (1/semana)
- **Mensais:** últimos 12 meses (1/mês)

```bash
BACKUP_RETENTION_STRATEGY="gfs"

# Comando
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=gfs
```

**Resultado:** 23 backups mantidos (~4.6GB para 200MB cada)

---

## Comparação de Estratégias

| Critério | Simple | Count | GFS |
|----------|--------|-------|-----|
| Facilidade | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Previsibilidade | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Economia | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Longo prazo | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Compliance | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## Uso Prático

### Modo Interativo
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh
```

### Modo Automático
```bash
# Simple (30 dias)
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --auto

# Count (últimos 10)
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=count --count=10 --auto

# GFS
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=gfs --auto
```

### Dry-Run (Simular)
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --dry-run
```

### Outro Diretório
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --dir=/var/backups/vpsguardian/volumes --days=15
```

---

## Automação com Cron

```bash
sudo crontab -e
```

```bash
# Limpeza semanal (simple) - segunda às 3h
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --auto >> /var/log/vpsguardian/cleanup.log 2>&1

# Limpeza diária (count) - todos os dias às 4h
0 4 * * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=count --count=10 --auto

# Limpeza mensal (GFS) - dia 1 de cada mês às 5h
0 5 1 * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=gfs --auto

# Múltiplos diretórios
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --dir=/var/backups/vpsguardian/coolify --days=30 --auto
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --dir=/var/backups/vpsguardian/volumes --days=15 --auto
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --dir=/var/backups/vpsguardian/databases --days=7 --auto
```

---

## Recomendações por Cenário

### Produção Crítica
```bash
BACKUP_RETENTION_STRATEGY="gfs"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
0 5 1 * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=gfs --auto
```
**Resultado:** 23 backups, histórico 12 meses, recovery granular

### Produção Normal
```bash
BACKUP_RETENTION_STRATEGY="simple"
BACKUP_RETENTION_DAYS="30"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --auto
```
**Resultado:** 30 backups, balanceamento custo/histórico

### Desenvolvimento/Staging
```bash
BACKUP_RETENTION_STRATEGY="count"
BACKUP_RETENTION_COUNT="7"

# Cron:
0 2 * * * vps-guardian backup --auto
0 3 * * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=count --count=7 --auto
```
**Resultado:** 7 backups, economia máxima

### Homelab/Pessoal
```bash
LOCAL_BACKUP_RETENTION_DAYS="7"
S3_LIFECYCLE_DAYS="90"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
```
**Resultado:** 7 dias local, 90 dias no S3, custo mínimo

---

## Calculadora de Espaço

Backup diário de 200MB:

| Estratégia | Backups | Espaço | Custo S3/mês* |
|------------|---------|--------|---------------|
| Simple (7d) | 7 | 1.4GB | $0.007 |
| Simple (30d) | 30 | 6GB | $0.03 |
| Simple (90d) | 90 | 18GB | $0.09 |
| Count (10) | 10 | 2GB | $0.01 |
| GFS (1 ano) | 23 | 4.6GB | $0.023 |

\* Backblaze B2 ($0.005/GB/mês)

---

## Troubleshooting

### Nenhum backup encontrado
```bash
# Verificar diretório
ls -lh /var/backups/vpsguardian/coolify/

# Verificar padrão
find /var/backups/vpsguardian/coolify/ -name "*.tar.gz*"
```

### Permission denied
```bash
# Use sudo
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30
```

### Backups não sendo deletados
**Causa 1:** Modo dry-run ativo
```bash
# Remover --dry-run
/opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --auto
```

**Causa 2:** Backups dentro do período de retenção
```bash
# Verificar idade
find /var/backups/vpsguardian/coolify/ -name "*.tar.gz*" -mtime +30 -ls
```

### GFS deletando backups importantes
A estratégia GFS mantém domingos (semanais) e dia 1 (mensais). Se seus backups não seguem essa convenção, use **simple** ou **count**.

---

## Checklist de Setup

- [ ] Definir estratégia de retenção (simple/count/gfs)
- [ ] Configurar `config/default.conf`
- [ ] Testar limpeza com `--dry-run`
- [ ] Criar cron job para limpeza automática
- [ ] Monitorar espaço em disco (`df -h`)
- [ ] Verificar custos S3 mensalmente
- [ ] Testar restauração a cada 6 meses
- [ ] Revisar estratégia anualmente

---

**VPS Guardian - Gestão Inteligente de Backups**
