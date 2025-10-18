# 📂 Guia de Estrutura e Instalação

Escolha a melhor estrutura de instalação para seu caso de uso.

---

## 🎯 Qual Estrutura Escolher?

### Opção 1: Estrutura Padrão (⭐ RECOMENDADA)

**Use quando:**
- ✅ Servidor em produção
- ✅ Quer seguir boas práticas Linux
- ✅ Ambiente corporativo/profissional
- ✅ Múltiplos administradores

**Instalação:**
```bash
sudo ./instalar.sh
```

---

### Opção 2: Estrutura Simplificada (Root)

**Use quando:**
- ✅ Servidor de desenvolvimento/teste
- ✅ Preferência por simplicidade
- ✅ Ambiente pessoal/hobby
- ✅ Administrador único

**Instalação:**
```bash
sudo ./instalar-root.sh
```

---

## 📊 Comparação Detalhada

### Estrutura Padrão vs Simplificada

| Aspecto | Padrão (`/opt/`) | Simplificada (`/root/`) |
|---------|------------------|-------------------------|
| **Scripts** | `/opt/manutencao/` | `/root/manutencao/scripts/` |
| **Logs** | `/var/log/manutencao/` | `/root/manutencao/logs/` |
| **Backups** | `/root/coolify-backups/` | `/root/manutencao/backups/` |
| **Comandos** | `/usr/local/bin/` | Links simbólicos |
| **Organização** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Padrão Linux** | ✅ Sim | ❌ Não |
| **Simplicidade** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Backup fácil** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 📂 Estrutura Padrão (Recomendada)

### Árvore de Diretórios

```
/opt/manutencao/                    ← Scripts executáveis
├── backup-coolify.sh
├── manutencao-completa.sh
├── alerta-disco.sh
├── migrar-coolify.sh
├── migrar-volumes.sh
├── transferir-backups.sh
├── test-sistema.sh
└── config.env.exemplo

/usr/local/bin/                     ← Comandos globais
├── backup-volume
├── backup-volume-interativo
├── restaurar-volume
├── restaurar-volume-interativo
└── status-completo

/var/log/manutencao/                ← Logs (padrão Linux)
├── manutencao.log
├── backup-coolify.log
└── cron.log

/root/coolify-backups/              ← Backups Coolify
├── 20251018_020000.tar.gz
└── 20251019_020000.tar.gz

/root/volume-backups/               ← Backups volumes
├── wordpress_data-20251018.tar.gz
└── postgres_data-20251018.tar.gz
```

### Vantagens

✅ **Segue FHS (Filesystem Hierarchy Standard)**
- Scripts em `/opt/` (aplicações opcionais)
- Logs em `/var/log/` (arquivos variáveis)
- Comandos em `/usr/local/bin/` (binários locais)

✅ **Organização Profissional**
- Separação clara: código vs dados
- Fácil de entender por outros admins
- Padrão da indústria

✅ **Facilita Backup do Sistema**
- Backups excluem `/opt/` (só código)
- Incluem `/root/` (dados importantes)

✅ **Comandos Acessíveis**
- `status-completo` funciona de qualquer lugar
- `backup-volume` no PATH

### Como Usar

```bash
# Instalar
sudo ./instalar.sh

# Executar scripts
sudo /opt/manutencao/backup-coolify.sh
sudo /opt/manutencao/manutencao-completa.sh

# Usar comandos globais
status-completo
backup-volume-interativo

# Ver logs
tail -f /var/log/manutencao/backup-coolify.log

# Ver backups
ls -lh /root/coolify-backups/
```

### Configurar Cron

```bash
sudo crontab -e
```

```cron
# Backup - Domingo 02:00
0 2 * * 0 /opt/manutencao/backup-coolify.sh >> /var/log/manutencao/cron.log 2>&1

# Manutenção - Segunda 03:00
0 3 * * 1 /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron.log 2>&1

# Alerta - Todo dia 09:00
0 9 * * * /opt/manutencao/alerta-disco.sh >> /var/log/manutencao/cron.log 2>&1
```

---

## 📁 Estrutura Simplificada (Root)

### Árvore de Diretórios

```
/root/manutencao/                   ← Tudo em um lugar
├── scripts/
│   ├── backup/
│   │   ├── backup-coolify.sh
│   │   ├── backup-volume.sh
│   │   ├── backup-volume-interativo.sh
│   │   ├── restaurar-volume.sh
│   │   └── restaurar-volume-interativo.sh
│   ├── manutencao/
│   │   ├── manutencao-completa.sh
│   │   └── alerta-disco.sh
│   ├── migrar/
│   │   ├── migrar-coolify.sh
│   │   ├── migrar-volumes.sh
│   │   └── transferir-backups.sh
│   └── auxiliares/
│       ├── status-completo.sh
│       └── test-sistema.sh
├── backups/
│   ├── coolify/
│   │   ├── 20251018_020000.tar.gz
│   │   └── 20251019_020000.tar.gz
│   └── volumes/
│       ├── wordpress_data-*.tar.gz
│       └── postgres_data-*.tar.gz
├── logs/
│   ├── manutencao.log
│   ├── backup-coolify.log
│   └── cron.log
└── config/
    ├── config.env
    └── crontab-exemplo.txt
```

### Vantagens

✅ **Simplicidade Extrema**
- Tudo em um único diretório
- Fácil de entender
- Fácil de navegar

✅ **Backup Trivial**
```bash
# Backup de tudo
tar -czf manutencao-backup.tar.gz /root/manutencao/
```

✅ **Portabilidade**
- Copie `/root/manutencao/` para outro servidor
- Tudo funciona imediatamente

### Desvantagens

⚠️ **Não Segue Padrão Linux**
- Logs não em `/var/log/`
- Scripts não em `/opt/`

⚠️ **Comandos Não Globais**
- Precisa usar caminho completo
- Ou criar links manualmente

### Como Usar

```bash
# Instalar
sudo ./instalar-root.sh

# Executar scripts (precisa estar no diretório)
cd /root/manutencao/scripts/backup
./backup-coolify.sh

cd /root/manutencao/scripts/manutencao
./manutencao-completa.sh

# Ou usar caminho completo
/root/manutencao/scripts/backup/backup-coolify.sh

# Comandos globais (via links simbólicos)
status-completo
backup-volume-interativo

# Ver logs
tail -f /root/manutencao/logs/backup-coolify.log

# Ver backups
ls -lh /root/manutencao/backups/coolify/
```

### Configurar Cron

```bash
sudo crontab -e
```

```cron
# Backup - Domingo 02:00
0 2 * * 0 /root/manutencao/scripts/backup/backup-coolify.sh >> /root/manutencao/logs/cron.log 2>&1

# Manutenção - Segunda 03:00
0 3 * * 1 /root/manutencao/scripts/manutencao/manutencao-completa.sh >> /root/manutencao/logs/cron.log 2>&1

# Alerta - Todo dia 09:00
0 9 * * * /root/manutencao/scripts/manutencao/alerta-disco.sh >> /root/manutencao/logs/cron.log 2>&1
```

---

## 🔄 Migração Entre Estruturas

### De Simplificada → Padrão

```bash
# Copiar scripts
sudo cp -r /root/manutencao/scripts/* /opt/manutencao/

# Mover backups (se quiser)
sudo mv /root/manutencao/backups/coolify/* /root/coolify-backups/
sudo mv /root/manutencao/backups/volumes/* /root/volume-backups/

# Mover logs
sudo mv /root/manutencao/logs/* /var/log/manutencao/

# Atualizar cron
sudo crontab -e
# Mudar caminhos de /root/manutencao/ para /opt/manutencao/
```

### De Padrão → Simplificada

```bash
# Criar estrutura
mkdir -p /root/manutencao/{scripts,backups/coolify,backups/volumes,logs}

# Copiar scripts
sudo cp /opt/manutencao/* /root/manutencao/scripts/

# Mover backups
sudo mv /root/coolify-backups/* /root/manutencao/backups/coolify/
sudo mv /root/volume-backups/* /root/manutencao/backups/volumes/

# Mover logs
sudo mv /var/log/manutencao/* /root/manutencao/logs/
```

---

## 💡 Recomendação Final

### Para Produção: Use Estrutura Padrão

```bash
sudo ./instalar.sh
```

**Por quê?**
- ✅ Profissional
- ✅ Escalável
- ✅ Fácil manutenção por equipe
- ✅ Segue boas práticas

### Para Dev/Teste: Use Estrutura Simplificada

```bash
sudo ./instalar-root.sh
```

**Por quê?**
- ✅ Rápido de configurar
- ✅ Fácil de entender
- ✅ Backup simples
- ✅ Portável

---

## ❓ FAQ

**P: Posso mudar depois?**
R: Sim! Veja seção "Migração Entre Estruturas"

**P: Qual usa menos espaço?**
R: Ambas usam o mesmo espaço (são os mesmos arquivos)

**P: Qual é mais segura?**
R: Ambas são igualmente seguras (tudo em `/root/`)

**P: Preciso escolher agora?**
R: Não, você pode testar ambas em VPS de teste

**P: Posso usar outra estrutura?**
R: Sim, mas estas são as mais recomendadas

---

**Escolha a estrutura que melhor se adequa ao seu caso de uso! 🚀**
