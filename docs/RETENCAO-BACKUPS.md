# 🗑️ Guia Completo - Retenção e Limpeza de Backups

Estratégias inteligentes para gerenciar espaço em disco e custos de armazenamento.

---

## 🎯 Por Que Limpar Backups Antigos?

### Problemas de NÃO limpar:
- ❌ Disco cheio (servidor para de funcionar)
- ❌ Custos elevados de armazenamento S3
- ❌ Backups desorganizados (difícil encontrar o correto)
- ❌ Performance degradada (I/O em disco cheio)

### Benefícios de limpar:
- ✅ Espaço em disco liberado
- ✅ Custos de S3 reduzidos (até 90%)
- ✅ Backups organizados e fáceis de encontrar
- ✅ Compliance (manter apenas dados necessários)

---

## 🔧 Configuração Global

### Arquivo: `/opt/vpsguardian/config/default.conf`

```bash
# Retenção de backups principais (Coolify completo)
BACKUP_RETENTION_DAYS="30"  # Deletar backups locais >30 dias

# Retenção de backups locais após upload para S3
LOCAL_BACKUP_RETENTION_DAYS="7"  # Manter apenas 7 dias localmente

# Retenção por quantidade (alternativa)
BACKUP_RETENTION_COUNT="10"  # Manter últimos 10 backups (0 = desabilitado)

# Estratégia de retenção
BACKUP_RETENTION_STRATEGY="simple"  # simple, count ou gfs
```

---

## 📊 3 Estratégias de Retenção

### 1️⃣ SIMPLE (Simples por Idade)

**Como funciona:**
- Deleta backups mais antigos que X dias
- Mantém todos os backups dentro do período

**Quando usar:**
- Setup simples
- Backups irregulares
- Não precisa de granularidade

**Exemplo:**
```bash
# Configuração
BACKUP_RETENTION_STRATEGY="simple"
BACKUP_RETENTION_DAYS="30"

# Resultado:
# ✓ Mantém: últimos 30 dias (todos)
# ✗ Deleta: >30 dias
```

**Comando:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=simple --days=30
```

**Cenário prático:**
```
Backup diário:
  Dia 1-30: 30 backups mantidos ✓
  Dia 31+: Deletados ✗

Disco usado: ~6GB (30 backups × 200MB)
```

---

### 2️⃣ COUNT (Por Quantidade)

**Como funciona:**
- Mantém últimos X backups
- Deleta o restante (independente da idade)

**Quando usar:**
- Espaço em disco limitado
- Backups regulares (diários/semanais)
- Quer controle exato de quantidade

**Exemplo:**
```bash
# Configuração
BACKUP_RETENTION_STRATEGY="count"
BACKUP_RETENTION_COUNT="10"

# Resultado:
# ✓ Mantém: últimos 10 backups (mais recentes)
# ✗ Deleta: todo o resto
```

**Comando:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=count --count=10
```

**Cenário prático:**
```
Backup diário:
  10 backups mais recentes: Mantidos ✓
  Backups 11+: Deletados ✗

Disco usado: ~2GB (10 backups × 200MB)
```

---

### 3️⃣ GFS (Grandfather-Father-Son)

**Como funciona:**
- **Diários (Son):** últimos 7 dias - TODOS os backups
- **Semanais (Father):** últimas 4 semanas - 1 backup por semana (domingo)
- **Mensais (Grandfather):** últimos 12 meses - 1 backup por mês (dia 1)

**Quando usar:**
- Compliance e auditoria
- Recuperação de longo prazo
- Balanceamento entre espaço e histórico

**Exemplo:**
```bash
# Configuração
BACKUP_RETENTION_STRATEGY="gfs"

# Resultado:
# ✓ Diários: 7 backups (1 por dia)
# ✓ Semanais: 4 backups (1 por semana)
# ✓ Mensais: 12 backups (1 por mês)
# ✗ Deleta: todo o resto
```

**Comando:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=gfs
```

**Cenário prático:**
```
Backup diário há 1 ano:
  Últimos 7 dias: 7 backups ✓
  Últimas 4 semanas: 4 backups ✓ (domingos)
  Últimos 12 meses: 12 backups ✓ (dia 1)

  Total mantido: 23 backups
  Disco usado: ~4.6GB (23 backups × 200MB)
```

**Linha do tempo GFS:**
```
Hoje ──────────────────────────────────────────────────── 1 ano atrás
     │                │                │                 │
     └─ 7 dias ───┐   └─ 4 semanas ─┐ └─ 12 meses ─────┐
                  │                  │                   │
     Diários      │   Semanais       │    Mensais        │
     (todos)      │   (domingos)     │    (dia 1)        │
     ▓▓▓▓▓▓▓      │   ░░░░░░░░░░░    │    ░░░░░░░░░░░   │
```

---

## 🚀 Como Usar

### Modo Interativo

```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh
```

### Modo Automático (Cron)

```bash
# Estratégia simple (30 dias)
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=simple --days=30 --auto

# Estratégia count (últimos 10)
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=count --count=10 --auto

# Estratégia GFS
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=gfs --auto
```

### Dry-Run (Simular)

```bash
# Simula sem deletar (mostra o que seria feito)
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=simple --days=30 --dry-run
```

### Limpar Outro Diretório

```bash
# Limpar backups de volumes
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --dir=/var/backups/vpsguardian/volumes --days=15

# Limpar backups de databases
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --dir=/var/backups/vpsguardian/databases --days=7
```

---

## ⏰ Automatizar com Cron

### Exemplo 1: Limpeza Semanal (Simple)

```bash
sudo crontab -e
```

```bash
# Limpar backups >30 dias (toda segunda às 3h)
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=simple --days=30 --auto >> /var/log/vpsguardian/cleanup.log 2>&1
```

### Exemplo 2: Limpeza Diária (Count)

```bash
# Manter apenas últimos 10 backups (todo dia às 4h)
0 4 * * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=count --count=10 --auto
```

### Exemplo 3: Limpeza Mensal (GFS)

```bash
# Aplicar GFS (dia 1 de cada mês, às 5h)
0 5 1 * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --strategy=gfs --auto
```

### Exemplo 4: Múltiplos Diretórios

```bash
# Limpar backups Coolify (30 dias)
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --dir=/var/backups/vpsguardian/coolify --days=30 --auto

# Limpar volumes (15 dias)
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --dir=/var/backups/vpsguardian/volumes --days=15 --auto

# Limpar databases (7 dias)
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh \
  --dir=/var/backups/vpsguardian/databases --days=7 --auto
```

---

## 💡 Recomendações por Cenário

### Produção Crítica

```bash
# Estratégia: GFS
# Backups: Diários
# Retenção: 7 diários + 4 semanais + 12 mensais

BACKUP_RETENTION_STRATEGY="gfs"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto  # Backup diário
0 5 1 * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=gfs --auto
```

**Resultado:**
- Recuperação granular (últimos 7 dias)
- Histórico de longo prazo (12 meses)
- Custo otimizado (~23 backups)

---

### Produção Normal

```bash
# Estratégia: Simple
# Backups: Diários
# Retenção: 30 dias

BACKUP_RETENTION_STRATEGY="simple"
BACKUP_RETENTION_DAYS="30"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
0 3 * * 1 /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --auto
```

**Resultado:**
- Balanceamento entre histórico e custo
- ~30 backups mantidos
- Simples de gerenciar

---

### Desenvolvimento/Staging

```bash
# Estratégia: Count
# Backups: Diários
# Retenção: Últimos 7 backups

BACKUP_RETENTION_STRATEGY="count"
BACKUP_RETENTION_COUNT="7"

# Cron:
0 2 * * * vps-guardian backup --auto  # Backup local apenas
0 3 * * * /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=count --count=7 --auto
```

**Resultado:**
- Mínimo espaço usado (~7 backups)
- Última semana disponível
- Economia máxima

---

### Homelab/Pessoal

```bash
# Estratégia: Simple (7 dias local) + S3 (90 dias)
# Backups: Diários

LOCAL_BACKUP_RETENTION_DAYS="7"
S3_LIFECYCLE_DAYS="90"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
# (limpeza local automática após upload)
```

**Resultado:**
- 7 dias locais (recovery rápido)
- 90 dias no S3 (segurança)
- Custo S3: ~$0.09/mês

---

## 📊 Comparação de Estratégias

| Critério | Simple | Count | GFS |
|----------|--------|-------|-----|
| **Facilidade** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Previsibilidade** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Economia de espaço** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Longo prazo** | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Compliance** | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Granularidade** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🧮 Calculadora de Espaço

### Exemplo: Backup diário de 200MB

| Estratégia | Backups Mantidos | Espaço Usado | Custo S3/mês* |
|------------|------------------|--------------|---------------|
| Simple (7 dias) | 7 | 1.4 GB | $0.007 |
| Simple (30 dias) | 30 | 6 GB | $0.03 |
| Simple (90 dias) | 90 | 18 GB | $0.09 |
| Count (10) | 10 | 2 GB | $0.01 |
| GFS (1 ano) | 23 | 4.6 GB | $0.023 |

\* Backblaze B2 ($0.005/GB/mês)

---

## 🆘 Troubleshooting

### Erro: "Nenhum backup encontrado"

**Causa:** Diretório vazio ou padrão de arquivo errado

**Solução:**
```bash
# Verificar diretório
ls -lh /var/backups/vpsguardian/coolify/

# Verificar padrão de arquivos
find /var/backups/vpsguardian/coolify/ -name "*.tar.gz*"
```

---

### Erro: "Permission denied"

**Causa:** Script precisa de sudo

**Solução:**
```bash
sudo /opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30
```

---

### Backups não sendo deletados

**Causa 1:** Modo dry-run ativo

**Solução:**
```bash
# Remover --dry-run
/opt/vpsguardian/scripts-auxiliares/limpar-backups-antigos.sh --strategy=simple --days=30 --auto
```

**Causa 2:** Backups dentro do período de retenção

**Solução:**
```bash
# Verificar idade dos backups
find /var/backups/vpsguardian/coolify/ -name "*.tar.gz*" -mtime +30 -ls

# Se nenhum resultado = todos os backups têm <30 dias
```

---

### GFS deletando backups importantes

**Causa:** Backups não seguem convenção de domingo/dia 1

**Solução:**
A estratégia GFS mantém:
- Domingos para semanais
- Dia 1 do mês para mensais

Se seus backups não seguem essa convenção, use **simple** ou **count**.

---

## 📚 Exemplos Práticos

### Exemplo 1: Servidor com Disco Pequeno (50GB)

**Problema:** Disco enche rapidamente

**Solução:**
```bash
# Backup local: manter apenas últimos 3
BACKUP_RETENTION_COUNT="3"
BACKUP_RETENTION_STRATEGY="count"

# S3: 90 dias
LIFECYCLE_DAYS="90"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
0 3 * * * limpar-backups-antigos.sh --strategy=count --count=3 --auto
```

**Resultado:**
- Local: ~600MB (3 backups)
- S3: 18GB (90 backups)
- Recovery local rápido
- Histórico no S3

---

### Exemplo 2: Compliance (Manter 7 Anos)

**Problema:** Precisa manter backups por 7 anos

**Solução:**
```bash
# Local: GFS otimizado
BACKUP_RETENTION_STRATEGY="gfs"

# S3: 7 anos (2555 dias)
LIFECYCLE_DAYS="2555"

# Cron:
0 2 * * * vps-guardian backup-s3 --auto
0 5 1 * * limpar-backups-antigos.sh --strategy=gfs --auto
```

**Resultado:**
- Diários: 7 dias
- Semanais: 4 semanas
- Mensais: 84 meses (7 anos)
- Total: ~95 backups
- Custo S3: ~$0.95/mês

---

### Exemplo 3: Economia Máxima

**Problema:** Minimizar custos de armazenamento

**Solução:**
```bash
# Local: apenas 1 backup (último)
BACKUP_RETENTION_COUNT="1"

# S3: 30 dias
LIFECYCLE_DAYS="30"

# Cron:
0 2 * * 0 vps-guardian backup-s3 --auto  # Semanal (domingo)
0 3 * * 1 limpar-backups-antigos.sh --strategy=count --count=1 --auto
```

**Resultado:**
- Backup semanal
- Local: 1 backup (~200MB)
- S3: 4 backups (~800MB)
- Custo S3: $0.004/mês (~R$ 0,02/mês)

---

## 🎯 Checklist de Setup

- [ ] Definir estratégia de retenção (simple/count/gfs)
- [ ] Configurar `config/default.conf`
- [ ] Testar limpeza com `--dry-run` primeiro
- [ ] Criar cron job para limpeza automática
- [ ] Monitorar espaço em disco (`df -h`)
- [ ] Verificar custos S3 mensalmente
- [ ] Testar restauração periodicamente (cada 6 meses)
- [ ] Documentar política de retenção (compliance)
- [ ] Revisar estratégia anualmente

---

**🗑️ VPS Guardian - Gestão Inteligente de Backups**
