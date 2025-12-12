# Scripts de Migração

## 📦 Migração de Volumes Docker

### Uso Rápido

```bash
# Migração completa (recomendado)
./migrar-volumes.sh

# Ou em 3 etapas:
./backup-volumes.sh --all
./transfer-volumes.sh --config=server.conf
./restore-volumes.sh --all
```

### Scripts Disponíveis

| Script | Descrição | Uso |
|--------|-----------|-----|
| `backup-volumes.sh` | Backup de volumes Docker | `./backup-volumes.sh --all` |
| `transfer-volumes.sh` | Transferir backups via SSH | `./transfer-volumes.sh` |
| `restore-volumes.sh` | Restaurar volumes de backups | `./restore-volumes.sh` |
| `migrar-volumes.sh` | Migração completa (all-in-one) | `./migrar-volumes.sh` |

### Documentação

- **Guia Completo:** `../docs/MIGRACAO-VOLUMES.md`
- **Quick Start:** `../docs/QUICK-START-VOLUMES.md`

---

## 🔧 Migração Coolify

### Uso

```bash
./migrar-coolify.sh
```

**O que faz:**
- Backup completo do Coolify
- Transferência para novo servidor
- Restauração automática
- Validação pós-migração

### Documentação

Ver documentação específica de migração Coolify.

---

## 📚 Mais Informações

Execute com `--help` para ver opções:

```bash
./backup-volumes.sh --help
./transfer-volumes.sh --help
./restore-volumes.sh --help
```

---

## ⚡ Acesso pelo Menu Principal

```bash
vps-guardian
# → 3. Migração
# → Escolha a opção desejada
```
