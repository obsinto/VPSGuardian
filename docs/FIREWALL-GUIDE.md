# 🔥 Guia Completo do Firewall Interativo - VPS Guardian

Gerenciador inteligente de firewall UFW com múltiplos perfis de segurança.

---

## 🚀 Quick Start

```bash
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh
```

---

## 🎯 3 Perfis de Segurança

### 1️⃣ SEGURO (Recomendado) 🔒

**Melhor para:** Produção, servidores críticos, compliance

**Características:**
- ✅ Porta 22 **FECHADA publicamente**
- ✅ SSH via **Cloudflare Tunnel** (Zero Trust)
- ✅ MFA/2FA obrigatório
- ✅ Auditoria completa de acessos
- ✅ IP dinâmico funciona
- ✅ Stealth mode (servidor invisível para scanners)

**SSH permitido de:**
- Localhost (127.0.0.1)
- Rede LAN (sua rede local)
- Redes Docker (10.0.0.0/8)

**Para acesso remoto:**
```bash
# Instalar cloudflared no cliente
cloudflared access ssh user@servidor.exemplo.com
```

**Segurança:** ⭐⭐⭐⭐⭐ (Máxima)

---

### 2️⃣ HÍBRIDO 🔐

**Melhor para:** Transição, backup de acesso, flexibilidade

**Características:**
- ✅ Cloudflare Tunnel como método **principal**
- ✅ Whitelist de IPs como **fallback**
- ✅ Porta 22 exposta apenas para IPs específicos
- ⚠️ Requer gerenciamento de IPs

**SSH permitido de:**
- Localhost (127.0.0.1)
- Rede LAN (sua rede local)
- Redes Docker (10.0.0.0/8)
- **+ IPs na whitelist** (você gerencia)

**Exemplo de uso:**
```bash
# Adicionar IP fixo do escritório como backup
# Menu → Opção 5 → Adicionar IP

# Usar Cloudflare normalmente
cloudflared access ssh user@servidor

# Se Cloudflare cair, usar IP direto
ssh user@servidor
```

**Segurança:** ⭐⭐⭐⭐ (Alta)

---

### 3️⃣ BÁSICO 🔓

**Melhor para:** Homelab, desenvolvimento, testes

**Características:**
- ⚠️ Porta 22 **EXPOSTA** (mas restrita)
- ⚠️ Apenas IPs na whitelist podem acessar
- ❌ Visível para port scanners
- ⚠️ Sujeito a brute force (use fail2ban)

**SSH permitido de:**
- Localhost (127.0.0.1)
- Rede LAN (sua rede local)
- Redes Docker (10.0.0.0/8)
- IPs na whitelist (você gerencia)

**⚠️ IMPORTANTE:**
- Configure **fail2ban** para proteção
- Use **chaves SSH** (desabilite senha)
- Monitore logs: `tail -f /var/log/auth.log`

**Segurança:** ⭐⭐⭐ (Boa, mas não ideal)

---

## 📊 Comparação Rápida

| Critério | SEGURO | HÍBRIDO | BÁSICO |
|----------|--------|---------|--------|
| Porta 22 exposta | ❌ Não | ⚠️ Só whitelist | ⚠️ Só whitelist |
| Zero Trust | ✅ Sim | ✅ Sim | ❌ Não |
| IP dinâmico | ✅ OK | ⚠️ Precisa whitelist | ⚠️ Precisa whitelist |
| Complexidade | Média | Média | Baixa |
| Segurança | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Fallback | ❌ | ✅ Sim | ✅ Direto |

---

## 🛠️ Gerenciar Whitelist de IPs

### Ver IPs Configurados
```
Menu → Opção 4
```

### Adicionar IP Manualmente
```
Menu → Opção 5

Digite o IP: 203.0.113.50
Descrição: Escritório
```

### Adicionar Seu IP Atual
```
Menu → Opção 6

# Detecta automaticamente e pergunta se quer adicionar
```

### Remover IP
```
Menu → Opção 7

# Lista IPs numerados
# Digite o número para remover
```

### Editar Manualmente
```bash
sudo nano /etc/vpsguardian/firewall-whitelist.conf

# Formato:
# IP DESCRIÇÃO
203.0.113.50 Escritório
198.51.100.25 Casa
```

---

## 🔍 Ferramentas de Diagnóstico

### Ver Status do Firewall
```
Menu → Opção 8

# Ou via terminal:
sudo ufw status verbose
```

### Ver Logs do Firewall
```
Menu → Opção 9

# Ou via terminal:
sudo tail -f /var/log/ufw.log
```

### Testar Conectividade SSH
```bash
# De outro servidor/computador:
ssh -v user@seu-servidor

# Se falhar, verificar:
1. IP está na whitelist?
2. Firewall está ativo? (ufw status)
3. SSH está rodando? (systemctl status ssh)
```

---

## 🎓 Workflows Práticos

### Workflow 1: Setup Inicial (Modo Seguro)

```bash
# 1. Configurar Cloudflare Tunnel primeiro
cloudflared tunnel login
cloudflared tunnel create meu-servidor
# Configurar DNS e rotas...

# 2. Aplicar firewall seguro
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh
# Opção 1 (SEGURO)
# Informar sua rede LAN: 192.168.31

# 3. Testar acesso via Cloudflare
cloudflared access ssh user@servidor.exemplo.com

# 4. Confirmar SSH funciona
# ✅ Pronto! Porta 22 fechada publicamente
```

### Workflow 2: Migração de Básico → Seguro

```bash
# Estado atual: Modo Básico (porta 22 exposta)
# Objetivo: Migrar para Cloudflare Tunnel

# 1. Configurar Cloudflare Tunnel
cloudflared tunnel login
cloudflared tunnel create meu-servidor

# 2. Testar Tunnel funciona (antes de fechar porta 22)
cloudflared access ssh user@servidor

# 3. Mudar para modo Híbrido (segurança)
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh
# Opção 2 (HÍBRIDO)

# 4. Testar 24h (Tunnel + fallback IP)

# 5. Após confirmar estável, mudar para Seguro
# Opção 1 (SEGURO)

# ✅ Migração completa!
```

### Workflow 3: Adicionar Acesso Temporário

```bash
# Cenário: Precisa dar acesso SSH temporário para alguém

# 1. Abrir firewall interativo
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh

# 2. Adicionar IP
# Opção 5 → Adicionar IP manualmente
# IP: 203.0.113.100
# Descrição: Suporte Temporário

# 3. Aplicar modo híbrido
# Opção 2 (HÍBRIDO)

# 4. Após trabalho, remover IP
# Opção 7 → Remover IP
# Opção 2 → Re-aplicar híbrido
```

### Workflow 4: Emergency Access (Cloudflare Down)

```bash
# Cenário: Cloudflare Tunnel caiu, precisa acessar servidor

# Se configurado modo SEGURO:
❌ Sem acesso direto (porta 22 fechada)
✅ Precisa acessar via console do provedor (DigitalOcean, AWS, etc.)

# Se configurado modo HÍBRIDO:
✅ Use IP da whitelist:
ssh user@servidor-ip

# Por isso recomendamos HÍBRIDO para produção crítica!
```

---

## 🔒 Boas Práticas de Segurança

### ✅ FAÇA:

1. **Use Cloudflare Tunnel** para acesso principal
2. **Modo Híbrido em produção** (Tunnel + 1-2 IPs fixos backup)
3. **Atualize whitelist regularmente** (remova IPs antigos)
4. **Monitore logs** pelo menos semanalmente
5. **Use chaves SSH** (desabilite senha)
6. **Configure fail2ban** se usar modo Básico
7. **Teste acesso** antes de desconectar
8. **Documente IPs** na whitelist (use descrições claras)

### ❌ NÃO FAÇA:

1. **Não adicione 0.0.0.0/0** (libera para todo mundo)
2. **Não exponha porta 22** sem necessidade
3. **Não esqueça de testar** antes de desconectar SSH
4. **Não adicione IPs** sem saber de quem é
5. **Não desative firewall** "temporariamente" (sempre esquecem de reativar)
6. **Não use senhas fracas** se usar modo Básico
7. **Não ignore logs** de tentativas de acesso

---

## 🆘 Troubleshooting

### Problema: "Perdi acesso SSH após aplicar firewall"

**Solução 1 - Via Console do Provedor:**
```bash
# Acessar via console web (DigitalOcean, AWS, etc.)
sudo ufw disable
sudo ufw status

# Verificar regras:
sudo ufw show added

# Re-aplicar corretamente
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh
```

**Solução 2 - Via Cloudflare Tunnel:**
```bash
# Se configurou Tunnel:
cloudflared access ssh user@servidor
```

### Problema: "IP dinâmico mudou, perdi acesso"

**Solução:**
```bash
# 1. Acessar via Cloudflare Tunnel (se configurado)
cloudflared access ssh user@servidor

# 2. Ou via console do provedor

# 3. Atualizar whitelist
sudo nano /etc/vpsguardian/firewall-whitelist.conf
# Alterar IP antigo para novo

# 4. Re-aplicar firewall
sudo /opt/vpsguardian/manutencao/firewall-interativo.sh
# Opção 2 ou 3 (re-aplicar)
```

### Problema: "Cloudflare Tunnel não conecta"

**Verificar:**
```bash
# 1. Loopback está permitido?
sudo ufw status | grep lo
# Deve mostrar: Anywhere on lo → ALLOW

# 2. Cloudflared está rodando?
sudo systemctl status cloudflared

# 3. Token correto?
cat ~/.cloudflared/config.yml

# 4. Porta 22 local acessível?
nc -zv 127.0.0.1 22
```

### Problema: "Porta 22 aparece como filtered em nmap"

**Isso é NORMAL e CORRETO!**

Se usando modo **SEGURO**:
- Porta 22 está fechada publicamente (DENY)
- `nmap` mostra "filtered" ou não mostra nada
- ✅ **Comportamento esperado!**

Se usando modo **HÍBRIDO/BÁSICO**:
- Porta 22 aparece "filtered" para quem não está na whitelist
- ✅ **Comportamento esperado!**

---

## 📞 Suporte

- **Logs:** `tail -f /var/log/ufw.log`
- **Status:** `sudo ufw status verbose`
- **Whitelist:** `/etc/vpsguardian/firewall-whitelist.conf`
- **Documentação:** [INSTALACAO.md](./INSTALACAO.md)

---

## 🎯 Recomendação Final

Para **produção:**
```
Modo HÍBRIDO = Melhor escolha
  ├─ Cloudflare Tunnel (principal)
  ├─ 1-2 IPs fixos (backup emergência)
  └─ Rede LAN (se aplicável)
```

Para **homelab/dev:**
```
Modo BÁSICO = Aceitável
  ├─ Whitelist IPs conhecidos
  ├─ fail2ban configurado
  └─ Chaves SSH (sem senha)
```

**Nunca:** Deixar porta 22 aberta para 0.0.0.0/0 (todo mundo) ❌

---

**🛡️ VPS Guardian - Firewall Inteligente e Seguro**
