# 📁 Estrutura do Projeto

Visão geral completa da organização dos arquivos e diretórios.

---

## 🗂️ Árvore de Diretórios

```
manutencao_backup_vps/
│
├── 📄 README.md                           # Documentação principal do projeto
├── 📄 INSTALACAO-RAPIDA.md                # Guia de instalação rápida (5 min)
├── 📄 ESTRUTURA.md                        # Este arquivo
├── 📄 Manutenção e Segurança de VPS...    # Documento original de referência
│
├── 📦 backup/                             # Scripts de backup
│   ├── backup-coolify.sh                  # Backup completo do Coolify
│   ├── backup-volume.sh                   # Backup de volumes individuais
│   └── restaurar-volume.sh                # Restauração de volumes
│
├── 🔧 manutencao/                         # Scripts de manutenção
│   ├── manutencao-completa.sh             # Manutenção automatizada
│   └── alerta-disco.sh                    # Alerta de espaço em disco
│
├── 🛠️ scripts-auxiliares/                 # Utilitários
│   ├── status-completo.sh                 # Dashboard de status
│   └── test-sistema.sh                    # Teste de todo o sistema
│
├── ⚙️ config/                              # Arquivos de configuração
│   ├── config.env                         # Configuração centralizada
│   └── crontab-exemplo.txt                # Exemplo de cron
│
└── 📚 docs/                                # Documentação detalhada
    ├── GUIA-BACKUP.md                     # Guia completo de backup
    └── GUIA-MANUTENCAO.md                 # Guia completo de manutenção
```

---

## 📦 Categoria: Backup

### `backup/backup-coolify.sh`
**Função:** Script principal de backup do Coolify

**O que faz:**
- ✅ Backup do banco de dados PostgreSQL
- ✅ Backup das SSH keys
- ✅ Backup do arquivo .env e APP_KEY
- ✅ Backup do authorized_keys
- ✅ Backup das configurações do Nginx
- ✅ Compactação automática
- ✅ Limpeza de backups antigos (retenção configurável)
- ✅ Notificações via email/webhook

**Instalação no servidor:**
```bash
sudo cp backup/backup-coolify.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/backup-coolify.sh
```

**Uso:**
```bash
sudo /opt/manutencao/backup-coolify.sh
```

---

### `backup/backup-volume.sh`
**Função:** Backup de volumes Docker individuais

**O que faz:**
- ✅ Backup de um volume Docker específico
- ✅ Compactação automática
- ✅ Validação de existência do volume

**Instalação no servidor:**
```bash
sudo cp backup/backup-volume.sh /usr/local/bin/backup-volume
sudo chmod +x /usr/local/bin/backup-volume
```

**Uso:**
```bash
sudo backup-volume nome_do_volume
```

---

### `backup/restaurar-volume.sh`
**Função:** Restauração de volumes Docker

**O que faz:**
- ✅ Cria volume se não existir
- ✅ Restaura dados do backup
- ✅ Validação do arquivo de backup

**Instalação no servidor:**
```bash
sudo cp backup/restaurar-volume.sh /usr/local/bin/restaurar-volume
sudo chmod +x /usr/local/bin/restaurar-volume
```

**Uso:**
```bash
sudo restaurar-volume backup.tar.gz nome_do_volume
```

---

## 🔧 Categoria: Manutenção

### `manutencao/manutencao-completa.sh`
**Função:** Manutenção preventiva automatizada

**O que faz:**
- ✅ Updates de segurança (via unattended-upgrades)
- ✅ Limpeza de Docker (containers, imagens, cache)
- ✅ Remoção de pacotes órfãos
- ✅ Remoção de kernels antigos
- ✅ Limpeza e rotação de logs
- ✅ Alertas de espaço em disco
- ✅ Verificação de necessidade de reboot
- ✅ Relatórios detalhados

**Instalação no servidor:**
```bash
sudo cp manutencao/manutencao-completa.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/manutencao-completa.sh
```

**Uso:**
```bash
sudo /opt/manutencao/manutencao-completa.sh
```

---

### `manutencao/alerta-disco.sh`
**Função:** Alerta de espaço em disco

**O que faz:**
- ✅ Verifica uso de disco
- ✅ Envia alerta se > 80% (configurável)

**Instalação no servidor:**
```bash
sudo cp manutencao/alerta-disco.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/alerta-disco.sh
```

**Uso:**
```bash
sudo /opt/manutencao/alerta-disco.sh
```

---

## 🛠️ Categoria: Scripts Auxiliares

### `scripts-auxiliares/status-completo.sh`
**Função:** Dashboard de status do sistema

**O que mostra:**
- 💾 Uso de disco
- 🧠 Uso de memória
- 🐳 Status do Docker
- 🔄 Status do Coolify
- 📦 Última manutenção
- 💾 Último backup
- 📊 Updates pendentes
- ⏰ Próximas execuções agendadas

**Instalação no servidor:**
```bash
sudo cp scripts-auxiliares/status-completo.sh /usr/local/bin/status-completo
sudo chmod +x /usr/local/bin/status-completo
```

**Uso:**
```bash
status-completo
```

---

### `scripts-auxiliares/test-sistema.sh`
**Função:** Teste completo do sistema

**O que testa:**
- ✅ Scripts instalados corretamente
- ✅ Diretórios criados
- ✅ Cron configurado
- ✅ Unattended-upgrades instalado
- ✅ Coolify rodando
- ✅ Backups existentes
- ✅ Espaço em disco
- ✅ Logs recentes

**Instalação no servidor:**
```bash
sudo cp scripts-auxiliares/test-sistema.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/test-sistema.sh
```

**Uso:**
```bash
sudo /opt/manutencao/test-sistema.sh
```

---

## ⚙️ Categoria: Configuração

### `config/config.env`
**Função:** Configuração centralizada (opcional)

**Contém:**
- Email e webhooks para notificações
- Configurações de backup (retenção, compressão)
- Configurações de backup remoto (servidor, S3)
- Limites de disco e kernels
- Paths do Coolify
- URLs de healthchecks

**Uso:**
```bash
# No início dos scripts:
source /opt/manutencao/config.env
```

---

### `config/crontab-exemplo.txt`
**Função:** Exemplo de configuração do cron

**Contém:**
- Agendamento de backup (domingo 02:00)
- Agendamento de manutenção (segunda 03:00)
- Agendamento de alerta (diário 09:00)
- Rotação de logs (dia 1 do mês 04:00)

**Uso:**
```bash
sudo crontab -e
# Copiar conteúdo do arquivo
```

---

## 📚 Categoria: Documentação

### `docs/GUIA-BACKUP.md`
**Conteúdo:**
- Instalação completa do sistema de backup
- Configuração de notificações
- Uso diário (comandos essenciais)
- Restauração de backups (passo a passo)
- Backup off-site (S3, servidor remoto, rclone)
- Troubleshooting
- Checklist de boas práticas

---

### `docs/GUIA-MANUTENCAO.md`
**Conteúdo:**
- Instalação completa do sistema de manutenção
- Configuração de unattended-upgrades
- Uso diário (comandos essenciais)
- Monitoramento e dashboard
- Troubleshooting
- Checklist de boas práticas

---

## 📄 Documentação Principal

### `README.md`
**Conteúdo:**
- Visão geral do projeto
- O que o sistema faz
- Instalação rápida
- Calendário de execução automática
- Comandos essenciais
- Configuração básica
- Checklist pós-instalação
- Recursos adicionais

---

### `INSTALACAO-RAPIDA.md`
**Conteúdo:**
- Passo a passo de instalação (5 minutos)
- Comandos prontos para copiar e colar
- Verificação final
- Próximos passos

---

## 🎯 Fluxo de Instalação no Servidor

```
┌─────────────────────────────────────────────┐
│  1. Clonar repositório                      │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  2. Instalar dependências                   │
│     apt install unattended-upgrades         │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  3. Criar diretórios                        │
│     /opt/manutencao                         │
│     /var/log/manutencao                     │
│     /root/coolify-backups                   │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  4. Copiar scripts                          │
│     backup/* → /opt/manutencao/             │
│     manutencao/* → /opt/manutencao/         │
│     scripts-auxiliares/* → /usr/local/bin/  │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  5. Configurar cron                         │
│     Usar config/crontab-exemplo.txt         │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  6. Testar tudo                             │
│     backup-coolify.sh                       │
│     manutencao-completa.sh                  │
│     test-sistema.sh                         │
└─────────────────────────────────────────────┘
```

---

## 📊 Resumo Estatístico

| Categoria | Quantidade |
|-----------|------------|
| Scripts de backup | 3 |
| Scripts de manutenção | 2 |
| Scripts auxiliares | 2 |
| Arquivos de configuração | 2 |
| Guias de documentação | 2 |
| Arquivos de README | 3 |
| **Total de arquivos** | **14** |

---

## 🔄 Calendário de Automação

```
┌─────────────┬─────────┬────────────────────────────┐
│ Frequência  │ Horário │ Ação                       │
├─────────────┼─────────┼────────────────────────────┤
│ Domingo     │ 02:00   │ backup-coolify.sh          │
│ Segunda     │ 03:00   │ manutencao-completa.sh     │
│ Todo dia    │ 09:00   │ alerta-disco.sh            │
│ Dia 1       │ 04:00   │ Rotação de logs            │
│ Diário      │ Auto    │ unattended-upgrades        │
└─────────────┴─────────┴────────────────────────────┘
```

---

**📌 Nota:** Esta estrutura foi criada seguindo as diretrizes do documento "Manutenção e Segurança de VPS com Docker e Coolify.md"
