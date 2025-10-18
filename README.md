# 🚀 Sistema de Manutenção e Backup para VPS com Docker e Coolify

Sistema completo e automatizado de manutenção preventiva e backup para servidores VPS rodando Docker e Coolify.

---

## 📦 O que este sistema faz?

### Sistema de Backup
✅ Backup completo do Coolify (banco de dados PostgreSQL, SSH keys, configurações)
✅ Backup automático semanal com retenção configurável (padrão: 30 dias)
✅ Compactação automática para economizar espaço
✅ Backup de volumes Docker individuais
✅ Suporte para backup off-site (S3, servidor remoto, Dropbox, etc)
✅ Notificações via email, Discord ou Slack
✅ Documentação completa de restauração incluída em cada backup

### Sistema de Manutenção
✅ Updates de segurança automáticos (via unattended-upgrades)
✅ Limpeza semanal de Docker (containers, imagens, cache)
✅ Remoção automática de pacotes e kernels antigos
✅ Limpeza e rotação de logs
✅ Alertas de espaço em disco
✅ Monitoramento contínuo com dashboard de status
✅ Logs detalhados de todas as operações

### Sistema de Migração ⭐ NOVO!
✅ Migração completa do Coolify para novo servidor
✅ Migração de volumes Docker usando backups existentes
✅ Transferência automática de backups para servidor remoto
✅ Suporte para autenticação SSH (chave ou senha)
✅ Verificação automática pós-migração
✅ Logs detalhados de todo o processo

---

## 📂 Estrutura do Repositório

```
manutencao_backup_vps/
├── backup/
│   ├── backup-coolify.sh              # Script principal de backup
│   ├── backup-volume.sh                # Backup de volumes (modo simples)
│   ├── backup-volume-interativo.sh     # Backup de volumes (modo interativo)
│   ├── restaurar-volume.sh             # Restauração de volumes (modo simples)
│   └── restaurar-volume-interativo.sh  # Restauração de volumes (modo interativo)
├── manutencao/
│   ├── manutencao-completa.sh      # Script de manutenção automatizada
│   └── alerta-disco.sh             # Alerta de espaço em disco
├── scripts-auxiliares/
│   ├── status-completo.sh          # Dashboard de status do sistema
│   └── test-sistema.sh             # Teste de todo o sistema
├── migrar/
│   ├── migrar-coolify.sh           # Migração do Coolify para novo servidor
│   ├── migrar-volumes.sh           # Migração de volumes Docker
│   └── transferir-backups.sh       # Transferência de backups para servidor remoto
├── config/
│   ├── config.env                  # Configuração centralizada (opcional)
│   └── crontab-exemplo.txt         # Exemplo de configuração do cron
├── docs/
│   ├── GUIA-BACKUP.md              # Guia completo de backup
│   ├── GUIA-MANUTENCAO.md          # Guia completo de manutenção
│   └── GUIA-MIGRACAO.md            # Guia completo de migração
└── README.md                       # Este arquivo
```

---

## 🚀 Instalação Rápida

### Pré-requisitos

- Ubuntu 20.04/22.04/24.04 LTS ou Debian 11/12
- Docker instalado
- Coolify instalado e rodando
- Acesso root via SSH

### Instalação Completa (5 minutos)

```bash
# 1. Clonar repositório
git clone https://github.com/SEU_USUARIO/manutencao_backup_vps.git
cd manutencao_backup_vps

# 2. Instalar dependências
sudo apt update
sudo apt install unattended-upgrades apt-listchanges -y

# 3. Criar estrutura de diretórios
sudo mkdir -p /opt/manutencao /var/log/manutencao /root/coolify-backups

# 4. Copiar scripts de backup
sudo cp backup/backup-coolify.sh /opt/manutencao/
sudo cp backup/backup-volume.sh /usr/local/bin/backup-volume
sudo cp backup/backup-volume-interativo.sh /usr/local/bin/backup-volume-interativo
sudo cp backup/restaurar-volume.sh /usr/local/bin/restaurar-volume
sudo cp backup/restaurar-volume-interativo.sh /usr/local/bin/restaurar-volume-interativo
sudo chmod +x /opt/manutencao/backup-coolify.sh
sudo chmod +x /usr/local/bin/backup-volume*
sudo chmod +x /usr/local/bin/restaurar-volume*

# 5. Copiar scripts de manutenção
sudo cp manutencao/manutencao-completa.sh /opt/manutencao/
sudo cp manutencao/alerta-disco.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/*.sh

# 6. Copiar scripts auxiliares
sudo cp scripts-auxiliares/status-completo.sh /usr/local/bin/status-completo
sudo cp scripts-auxiliares/test-sistema.sh /opt/manutencao/
sudo chmod +x /usr/local/bin/status-completo
sudo chmod +x /opt/manutencao/test-sistema.sh

# 7. Configurar unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# 8. Configurar cron
sudo crontab -e
# Cole o conteúdo de config/crontab-exemplo.txt

# 9. Testar instalação
sudo /opt/manutencao/backup-coolify.sh
sudo /opt/manutencao/manutencao-completa.sh
status-completo
sudo /opt/manutencao/test-sistema.sh
```

---

## 📅 Calendário de Execução Automática

| Dia | Horário | Script | Ação |
|-----|---------|--------|------|
| **Domingo** | 02:00 | `backup-coolify.sh` | Backup completo do Coolify |
| **Segunda** | 03:00 | `manutencao-completa.sh` | Manutenção preventiva |
| **Todo dia** | 09:00 | `alerta-disco.sh` | Verificação de espaço em disco |
| **Dia 1** | 04:00 | Rotação de logs | Arquiva logs antigos |
| **Diário** | Automático | `unattended-upgrades` | Updates de segurança |

---

## 📚 Documentação

### Guias Completos

- [**GUIA-BACKUP.md**](docs/GUIA-BACKUP.md) - Instalação, configuração e uso do sistema de backup
- [**GUIA-MANUTENCAO.md**](docs/GUIA-MANUTENCAO.md) - Instalação, configuração e uso do sistema de manutenção

### Comandos Essenciais

#### Backup
```bash
# Executar backup manual
sudo /opt/manutencao/backup-coolify.sh

# Ver backups existentes
ls -lh /root/coolify-backups/

# Ver log de backup
tail -50 /var/log/manutencao/backup-coolify.log

# Backup de volume específico (modo simples)
sudo backup-volume nome_do_volume

# Backup de volume específico (modo interativo)
sudo backup-volume-interativo
```

#### Manutenção
```bash
# Executar manutenção manual
sudo /opt/manutencao/manutencao-completa.sh

# Ver status completo
status-completo

# Ver logs
tail -50 /var/log/manutencao/manutencao.log

# Testar sistema
sudo /opt/manutencao/test-sistema.sh
```

---

## ⚙️ Configuração

### Notificações

Edite os scripts em `/opt/manutencao/` e configure:

**Email:**
```bash
EMAIL="seu-email@exemplo.com"
```

**Discord:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/SEU_WEBHOOK"
```

**Slack:**
```bash
WEBHOOK_URL="https://hooks.slack.com/services/SEU_WEBHOOK"
```

### Ajustar Retenção de Backups

No arquivo `/opt/manutencao/backup-coolify.sh`:
```bash
RETENTION_DAYS=30  # Alterar para quantidade desejada de dias
```

### Configurar Backup Off-site

Veja o [GUIA-BACKUP.md](docs/GUIA-BACKUP.md#backup-off-site) para instruções detalhadas de:
- Sincronização com servidor remoto via rsync/scp
- Upload para AWS S3
- Sincronização com Dropbox/Google Drive via rclone

---

## 🔄 Restauração de Backup

### Restauração Completa (resumo)

```bash
# 1. No novo servidor, instalar Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

# 2. Transferir e extrair backup
scp servidor-antigo:/root/coolify-backups/BACKUP.tar.gz .
tar -xzf BACKUP.tar.gz
cd PASTA_EXTRAIDA

# 3. Seguir instruções
cat backup-info.txt

# Instruções completas no GUIA-BACKUP.md
```

**Documentação completa:** [GUIA-BACKUP.md - Restauração](docs/GUIA-BACKUP.md#restauração-de-backups)

---

## 🛡️ Segurança

### Recomendações

✅ **Teste backups regularmente** - Faça teste de restauração a cada 3 meses
✅ **Backup off-site obrigatório** - Nunca dependa apenas de backups locais
✅ **Criptografia** - Considere criptografar backups sensíveis
✅ **Firewall** - Configure UFW para proteger o servidor
✅ **Fail2ban** - Proteja SSH contra ataques de força bruta
✅ **Updates automáticos** - Mantenha sempre ativo

### Instalação de Segurança Adicional (opcional)

```bash
# Firewall
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 🔧 Troubleshooting

### Problemas Comuns

**Backup não está sendo criado**
```bash
# Verificar se Coolify está rodando
docker ps | grep coolify

# Ver erros
tail -100 /var/log/manutencao/backup-coolify.log
```

**Manutenção não roda automaticamente**
```bash
# Verificar crontab
sudo crontab -l

# Ver logs do cron
grep CRON /var/log/syslog | tail -20
```

**Espaço em disco cheio**
```bash
# Ver o que ocupa espaço
sudo du -sh /* | sort -h
sudo ncdu /

# Limpeza manual agressiva do Docker
docker system prune -a --volumes
```

Mais detalhes nos guias específicos.

---

## 📊 Monitoramento

### Dashboard de Status

```bash
status-completo
```

Mostra:
- Uso de disco e memória
- Status do Docker e Coolify
- Última manutenção executada
- Último backup criado
- Updates pendentes
- Próximas execuções agendadas

---

## ✅ Checklist Pós-Instalação

- [ ] Todos os scripts copiados e com permissão de execução
- [ ] Cron configurado corretamente
- [ ] Unattended-upgrades instalado e ativo
- [ ] Backup manual executado com sucesso
- [ ] Manutenção manual executada com sucesso
- [ ] Teste do sistema passou (test-sistema.sh)
- [ ] Notificações configuradas e testadas
- [ ] Backup off-site configurado
- [ ] Teste de restauração de backup realizado
- [ ] Documentação salva em local seguro

---

## 🎯 Próximos Passos

### Após Instalação

**Semana 1:**
- Monitore logs diariamente
- Verifique se backups estão sendo criados
- Ajuste horários se necessário

**Mês 1:**
- Teste restauração de um backup
- Configure backup off-site
- Implemente criptografia de backups (se necessário)

**Trimestre 1:**
- Teste restauração completa em servidor de teste
- Revise e otimize retenção de backups
- Documente lições aprendidas

---

## 📚 Recursos Adicionais

- [Documentação oficial do Coolify](https://coolify.io/docs)
- [Unattended Upgrades - Debian Wiki](https://wiki.debian.org/UnattendedUpgrades)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [PostgreSQL Backup & Recovery](https://www.postgresql.org/docs/current/backup.html)

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:

- Reportar bugs
- Sugerir melhorias
- Enviar pull requests
- Compartilhar sua experiência

---

## 📄 Licença

Este projeto é baseado nas diretrizes do documento "Manutenção e Segurança de VPS com Docker e Coolify" e nas boas práticas da comunidade DevOps.

---

## 🙏 Créditos

- Setup minimalista original por [@hyperknot](https://x.com/hyperknot)
- [Coolify Team](https://coolify.io) - Plataforma incrível
- Comunidade open-source

---

## 📞 Suporte

- **Coolify Discord**: https://discord.gg/coolify
- **Documentação Coolify**: https://coolify.io/docs
- **GitHub Issues**: Para reportar problemas com estes scripts

---

**🎉 Pronto! Seu VPS agora está protegido com backup e manutenção automatizados.**

**Boa sorte e deploy feliz! 🚀**
