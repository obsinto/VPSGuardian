# 🔧 Guia de Uso - Sistema de Manutenção

Guia completo para instalação, configuração e uso do sistema de manutenção automatizada do VPS.

---

## 📋 Índice

1. [Instalação](#instalação)
2. [Configuração](#configuração)
3. [Uso Diário](#uso-diário)
4. [Monitoramento](#monitoramento)
5. [Troubleshooting](#troubleshooting)

---

## 🚀 Instalação

### Passo 1: Instalar Dependências

```bash
# Instalar unattended-upgrades
sudo apt update
sudo apt install unattended-upgrades apt-listchanges -y

# Configurar unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Passo 2: Criar Estrutura de Diretórios

```bash
# Criar diretórios necessários
sudo mkdir -p /opt/manutencao
sudo mkdir -p /var/log/manutencao
```

### Passo 3: Copiar Scripts

```bash
# Copiar scripts de manutenção
sudo cp manutencao/manutencao-completa.sh /opt/manutencao/
sudo cp manutencao/alerta-disco.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/*.sh

# Copiar script de status
sudo cp scripts-auxiliares/status-completo.sh /usr/local/bin/status-completo
sudo chmod +x /usr/local/bin/status-completo

# Copiar script de teste
sudo cp scripts-auxiliares/test-sistema.sh /opt/manutencao/
sudo chmod +x /opt/manutencao/test-sistema.sh
```

### Passo 4: Configurar Unattended Upgrades

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

**Cole a configuração:**

```bash
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Verbose "true";
```

**Configure frequência:**

```bash
sudo nano /etc/apt/apt.conf.d/20auto-upgrades
```

```bash
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
```

### Passo 5: Configurar Cron

```bash
# Editar crontab
sudo crontab -e

# Adicionar linhas
0 3 * * 1 /opt/manutencao/manutencao-completa.sh >> /var/log/manutencao/cron.log 2>&1
0 9 * * * /opt/manutencao/alerta-disco.sh >> /var/log/manutencao/cron.log 2>&1
```

### Passo 6: Testar Instalação

```bash
# Executar manutenção manualmente
sudo /opt/manutencao/manutencao-completa.sh

# Ver log
tail -100 /var/log/manutencao/manutencao.log

# Executar teste do sistema
sudo /opt/manutencao/test-sistema.sh
```

---

## ⚙️ Configuração

### Configurar Notificações

Edite `/opt/manutencao/manutencao-completa.sh`:

```bash
sudo nano /opt/manutencao/manutencao-completa.sh
```

**Para email:**
```bash
EMAIL="seu-email@exemplo.com"
```

**Para Discord/Slack:**
```bash
WEBHOOK_URL="https://discord.com/api/webhooks/SEU_WEBHOOK"
```

### Ajustar Limite de Disco

```bash
DISCO_LIMITE=85  # Alterar para o valor desejado (%)
```

### Configurar Kernels a Manter

```bash
MANTER_KERNELS=2  # Quantos kernels manter instalados
```

### Habilitar Remoção Automática de Volumes Docker

⚠️ **CUIDADO**: Isso pode remover dados permanentemente!

No script `manutencao-completa.sh`, descomente a linha:

```bash
# docker volume prune -f >> "$LOG_FILE" 2>&1
```

### Habilitar Reboot Automático

Para permitir reboot automático após updates que exigem reinicialização:

```bash
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

Altere:
```bash
Unattended-Upgrade::Automatic-Reboot "true";
```

---

## 📅 Uso Diário

### Comandos Essenciais

#### Ver status completo do sistema
```bash
status-completo
```

#### Executar manutenção manual
```bash
sudo /opt/manutencao/manutencao-completa.sh
```

#### Ver logs de manutenção
```bash
# Últimas 50 linhas
tail -50 /var/log/manutencao/manutencao.log

# Seguir log em tempo real
tail -f /var/log/manutencao/manutencao.log

# Ver log completo
less /var/log/manutencao/manutencao.log
```

#### Verificar espaço em disco
```bash
df -h
```

#### Ver uso de espaço do Docker
```bash
docker system df
docker system df -v  # Detalhado
```

#### Listar kernels instalados
```bash
dpkg --list | grep linux-image
```

#### Ver updates pendentes
```bash
apt list --upgradable
```

#### Verificar se reboot é necessário
```bash
ls /var/run/reboot-required
cat /var/run/reboot-required.pkgs
```

---

## 📊 Monitoramento

### Ver Logs do Cron

```bash
# Ver últimas execuções
tail -50 /var/log/manutencao/cron.log

# Ver execuções de manutenção
grep "manutencao-completa" /var/log/manutencao/cron.log
```

### Verificar Próximas Execuções

```bash
# Ver crontab configurado
sudo crontab -l

# Ver última execução de cada job
grep CRON /var/log/syslog | tail -20
```

### Calendário de Execução Automática

| Frequência | Horário | Script | Ação |
|-----------|---------|--------|------|
| Segunda-feira | 03:00 | `manutencao-completa.sh` | Manutenção completa |
| Todo dia | 09:00 | `alerta-disco.sh` | Alerta de disco |
| Diário | Automático | `unattended-upgrades` | Updates de segurança |

### Dashboard de Monitoramento

Execute o comando:
```bash
status-completo
```

Saída exemplo:
```
╔════════════════════════════════════════════════════════════╗
║          STATUS COMPLETO DO VPS + COOLIFY                  ║
╚════════════════════════════════════════════════════════════╝

📅 Segunda-feira, 18 de Outubro de 2025 - 14:30:00
🖥️  Hostname: meu-vps

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 DISCO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Usado: 12G de 50G (25%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 MEMÓRIA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Usado: 2.1G de 4.0G (52%)
...
```

---

## 🔧 Troubleshooting

### Manutenção não está rodando automaticamente

**Verificar se cron está ativo:**
```bash
sudo systemctl status cron
```

**Verificar crontab:**
```bash
sudo crontab -l
```

**Ver erros do cron:**
```bash
grep CRON /var/log/syslog | tail -20
```

### Espaço em disco não está sendo liberado

**Ver o que está ocupando espaço:**
```bash
sudo du -sh /* | sort -h
sudo ncdu /  # Interface interativa (instalar: sudo apt install ncdu)
```

**Verificar volumes Docker órfãos:**
```bash
docker volume ls -qf dangling=true
```

**Verificar logs grandes:**
```bash
sudo du -sh /var/log/*
sudo journalctl --disk-usage
```

### Updates de segurança não estão sendo aplicados

**Verificar status do unattended-upgrades:**
```bash
sudo systemctl status unattended-upgrades
```

**Ver log de updates:**
```bash
sudo cat /var/log/unattended-upgrades/unattended-upgrades.log
```

**Forçar execução manual:**
```bash
sudo unattended-upgrade -d
```

### Kernels antigos não estão sendo removidos

**Listar kernels:**
```bash
dpkg --list | grep linux-image
```

**Ver kernel em uso:**
```bash
uname -r
```

**Remover manualmente:**
```bash
# Remover kernel específico
sudo apt remove --purge linux-image-VERSAO

# Remover automaticamente
sudo apt autoremove --purge
```

### Docker ocupando muito espaço

**Ver uso detalhado:**
```bash
docker system df -v
```

**Limpeza manual agressiva:**
```bash
# Remover TUDO não usado (CUIDADO!)
docker system prune -a --volumes

# Apenas containers parados
docker container prune

# Apenas imagens não usadas
docker image prune -a

# Apenas build cache
docker builder prune -a
```

---

## ✅ Checklist de Boas Práticas

- [ ] Manutenção automática configurada e rodando semanalmente
- [ ] Unattended-upgrades instalado e ativo
- [ ] Alertas de disco configurados
- [ ] Logs sendo rotacionados automaticamente
- [ ] Sistema de monitoramento em uso (status-completo)
- [ ] Retenção de kernels ajustada
- [ ] Notificações configuradas
- [ ] Teste do sistema executado com sucesso
- [ ] Revisão semanal dos logs agendada

---

## 📚 Recursos Adicionais

- [Documentação Unattended Upgrades](https://wiki.debian.org/UnattendedUpgrades)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Ubuntu Security Guide](https://ubuntu.com/security)

---

**Dúvidas?** Consulte o [README principal](../README.md) ou a documentação completa.
