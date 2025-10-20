# 🛡️ Guia Completo: Infraestrutura Segura com Cloudflare Zero Trust

> **Ferramenta Definitiva de Segurança e Acesso Remoto**
> Todas as configurações de infraestrutura Zero Trust centralizadas em um único documento

---

## 📚 Índice Geral

### Parte I - Fundamentos
1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Componentes da Solução](#2-componentes-da-solução)
3. [Pré-requisitos](#3-pré-requisitos)

### Parte II - Configuração Base (Zero Trust)
4. [Configuração dos Túneis Cloudflare](#4-configuração-dos-túneis-cloudflare)
5. [Perfis de Dispositivo (Split Tunnels)](#5-perfis-de-dispositivo-split-tunnels)
6. [Configuração dos Clientes WARP](#6-configuração-dos-clientes-warp)
7. [Blindagem com UFW + Docker](#7-blindagem-com-ufw--docker)

### Parte III - Features Avançadas
8. [Terminal SSH no Navegador](#8-terminal-ssh-no-navegador)
9. [Acesso a Bancos de Dados Remotos](#9-acesso-a-bancos-de-dados-remotos)
10. [Aplicações Web com Cloudflare Access](#10-aplicações-web-com-cloudflare-access)

### Parte IV - Operação e Manutenção
11. [Como o Tráfego Flui (Diagramas)](#11-como-o-tráfego-flui)
12. [Testes e Validação](#12-testes-e-validação)
13. [Troubleshooting Completo](#13-troubleshooting-completo)
14. [Monitoramento e Logs](#14-monitoramento-e-logs)

### Parte V - Referências
15. [Comandos Úteis](#15-comandos-úteis)
16. [Checklist de Segurança](#16-checklist-de-segurança)
17. [Expansões Futuras](#17-expansões-futuras)

---

## 1. Visão Geral da Arquitetura

### 🎯 O Que Você Vai Construir

Uma **infraestrutura Zero Trust de nível empresarial** que combina:

- ✅ **Rede privada global** via Cloudflare (substitui VPN tradicional)
- ✅ **Túneis seguros** sem expor portas públicas
- ✅ **Firewall inteligente** que diferencia tráfego público vs privado
- ✅ **Terminal SSH no navegador** (sem precisar de cliente SSH)
- ✅ **Proxy reverso** com Cloudflare + Coolify para aplicações web
- ✅ **Isolamento de containers Docker** respeitando o firewall
- ✅ **Autenticação centralizada** com email/OTP

### 🏆 Objetivos Alcançados

| Funcionalidade | Antes | Depois |
|----------------|-------|---------|
| **SSH Homelab** | ❌ Exposto na porta 22 | ✅ Acessível apenas via WARP/navegador |
| **SSH VPS** | ❌ Exposto na porta 22 | ✅ Acessível apenas via WARP/navegador |
| **Bancos de Dados** | ❌ Portas 5432-5434 expostas | ✅ Acessíveis apenas via WARP |
| **Painéis Admin** | ❌ Coolify/Netdata públicos | ✅ Protegidos com autenticação |
| **Apps Web** | ⚠️ Expostas sem proteção | ✅ CDN + WAF + DDoS protection |
| **Acesso Remoto** | ⚠️ VPN lenta e complexa | ✅ WARP automático e rápido |

### 🏗️ Arquitetura Visual

```
┌─────────────────────────────────────────────────────────────────┐
│                      USUÁRIOS (VOCÊ)                            │
│  • Notebooks com WARP    • Celulares com WARP                  │
│  • Navegador com Access  • Clientes DB                         │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ Autenticação + Criptografia
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                   CLOUDFLARE GLOBAL NETWORK                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   CDN/WAF    │  │ Zero Trust   │  │ WARP Network │         │
│  │ (Apps Web)   │  │  (Access)    │  │ (100.64.x.x) │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└───────────────────────────┬─────────────────────────────────────┘
                            │
              ┌─────────────┴──────────────┐
              │                            │
    Túneis Cloudflared          Túneis Cloudflared
    (Criptografados)            (Criptografados)
              │                            │
              ↓                            ↓
┌─────────────────────────┐  ┌─────────────────────────┐
│   VPS (31.97.23.42)     │  │  HOMELAB (192.168.31.x) │
│                         │  │                         │
│  🔥 UFW Firewall        │  │  🔥 UFW Firewall        │
│   • Porta 80/443: ✅    │  │   • Tudo fechado: ❌    │
│   • Porta 22: ❌        │  │   • WARP only: ✅       │
│   • Outras: ❌          │  │                         │
│                         │  │                         │
│  🐳 Docker Containers   │  │  💻 Serviços Locais     │
│   • Apps Web Públicas   │  │   • SSH                 │
│   • PostgreSQL (Priv)   │  │   • Arquivos            │
│   • Coolify (Privado)   │  │   • Outros serviços     │
│   • Netdata (Privado)   │  │                         │
└─────────────────────────┘  └─────────────────────────┘
```

---

## 2. Componentes da Solução

### 🖥️ Servidores

#### **VPS (Servidor Cloud)**
- **IP Público:** `31.97.23.42` (adapte ao seu)
- **Software:**
  - `cloudflared` - Túnel Cloudflare
  - `Coolify` - Gerenciador de aplicações
  - `Docker` - Containers
  - `UFW` - Firewall
- **Serviços Públicos:**
  - Portas 80/443 (HTTP/HTTPS)
- **Serviços Privados:**
  - SSH (22)
  - PostgreSQL (5432-5434)
  - Netdata (19999)
  - Coolify UI (8000)

#### **Homelab (PC em Casa)**
- **IP Local:** `192.168.31.228` (adapte ao seu)
- **Rede Local:** `192.168.31.0/24`
- **Software:**
  - `cloudflared` - Túnel Cloudflare
  - Cliente WARP
- **Função Dupla:** Servidor SSH + Cliente WARP (requer configuração especial)

### 📱 Clientes

- **Dispositivos:** Notebooks, celulares, tablets
- **Software:** Cloudflare WARP
- **Identidades:**
  - **Identidade A (Cliente):** `deyvid-pessoal@seudominio.com`
  - **Identidade B (Servidor):** `deyvid-servidor@seudominio.com`

### ☁️ Cloudflare Services

- **Zero Trust:** Plataforma principal
- **Tunnels:** Conexões seguras sem portas abertas
- **WARP:** Cliente VPN moderno
- **Access:** Autenticação para aplicações
- **CDN/WAF:** Proteção e cache para apps web

---

## 3. Pré-requisitos

### ✅ Conta Cloudflare

1. **Criar conta gratuita:** https://dash.cloudflare.com/sign-up
2. **Adicionar domínio:**
   - Adicione seu domínio (ex: `agilytech.com`)
   - Altere os nameservers no seu registrador
   - Aguarde propagação (pode levar até 24h)
3. **Ativar Zero Trust:**
   - Acesse: https://one.dash.cloudflare.com/
   - Escolha um nome para sua organização
   - Plano gratuito suporta até 50 usuários

### ✅ Servidores Configurados

```bash
# Em cada servidor (VPS e Homelab), verifique:

# Sistema operacional suportado
cat /etc/os-release
# Recomendado: Ubuntu 22.04/24.04, Debian 11/12

# Acesso root ou sudo
sudo -v

# Conexão com internet
ping -c 3 1.1.1.1

# Portas necessárias livres
sudo netstat -tlnp | grep -E ':(80|443|22)\s'
```

### ✅ Emails para Identidades

Você precisa de **dois emails diferentes**:

1. **Email Principal (Identidade A):** Para usar nos dispositivos clientes
   - Exemplo: `seu-email@gmail.com`

2. **Email Servidor (Identidade B):** Para usar no Homelab (evitar loop)
   - Exemplo: `seu-email+servidor@gmail.com` (Gmail permite `+alias`)
   - Ou: `servidor@seudominio.com`

---

## 4. Configuração dos Túneis Cloudflare

### 📡 Conceito: O Que É Um Túnel?

Um **Cloudflare Tunnel** é uma conexão segura e criptografada entre seu servidor e a rede Cloudflare. Ele **elimina a necessidade de abrir portas** no firewall, pois a conexão é **saída** (do servidor para Cloudflare).

```
Servidor → cloudflared → Cloudflare Network → Internet/WARP Clients
  (Firewall fechado)     (Conexão criptografada)
```

### 🔧 Túnel 1: VPS (Servidor Cloud)

#### Passo 1: Criar Túnel no Painel

1. Acesse: `Zero Trust → Networks → Tunnels`
2. Clique em `Create a tunnel`
3. Escolha: `Cloudflared`
4. Nome: `vps-tunnel` (ou `vps_01`)
5. Clique em `Save tunnel`

#### Passo 2: Instalar cloudflared na VPS

```bash
# Conecte-se via SSH à VPS (pela última vez usando IP público!)
ssh root@31.97.23.42

# Baixar e instalar
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Copie o token fornecido pelo painel Cloudflare e execute:
sudo cloudflared service install eyJhIjoiNGY...SEU_TOKEN_AQUI

# Verificar status
sudo systemctl status cloudflared
```

#### Passo 3: Configurar Private Network (IMPORTANTE!)

De volta ao painel Cloudflare:

1. No túnel `vps-tunnel`, clique em `Configure`
2. Vá para a aba `Private Networks`
3. Clique em `Add a private network`
4. Configure:
   - **CIDR:** `31.97.23.42/32` (IP da VPS em formato CIDR)
   - **Description:** `VPS Principal`
5. Clique em `Save`

**🔑 O que isso faz?** Informa à rede WARP que este túnel pode rotear tráfego para o IP `31.97.23.42`, mesmo que ele não esteja publicamente acessível.

#### Passo 4: Adicionar Rotas Públicas (Opcional)

Se você tem aplicações web (ex: Coolify gerenciando sites):

1. Na aba `Public Hostname`, clique em `Add a public hostname`
2. Configure para cada site:
   ```
   Subdomain: analytics
   Domain: agilytech.com
   Type: HTTP
   URL: http://localhost:19999
   ```
3. Repita para outros serviços web

---

### 🔧 Túnel 2: Homelab (PC de Casa)

#### Passo 1: Criar Túnel no Painel

1. `Zero Trust → Networks → Tunnels`
2. `Create a tunnel` → `Cloudflared`
3. Nome: `homelab`
4. `Save tunnel`

#### Passo 2: Instalar cloudflared no Homelab

```bash
# No seu PC de casa
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
sudo cloudflared service install eyJhIjoiNGY...SEU_TOKEN_DO_HOMELAB

# Verificar
sudo systemctl status cloudflared
```

#### Passo 3: Configurar Private Network

No painel:

1. Túnel `homelab` → `Configure` → `Private Networks`
2. `Add a private network`
3. Configure:
   - **CIDR:** `192.168.31.0/24` (sua rede local completa)
   - **Description:** `Rede Local Casa`
4. `Save`

**💡 Por que a rede inteira?** Assim você pode acessar não só o PC principal (192.168.31.228), mas também outros dispositivos na rede local (impressora, NAS, etc).

---

### ✅ Validação dos Túneis

```bash
# Em cada servidor, verificar status
sudo systemctl status cloudflared

# Ver logs em tempo real
sudo journalctl -u cloudflared -f

# No painel Cloudflare
# Zero Trust → Networks → Tunnels
# Ambos devem mostrar status: HEALTHY (verde)
```

---

## 5. Perfis de Dispositivo (Split Tunnels)

### 🧩 O Problema do Loop

Quando o Homelab (192.168.31.228) precisa ser **servidor E cliente** ao mesmo tempo:

```
❌ SEM PERFIS CORRETOS:
PC liga WARP → WARP vê "192.168.31.0/24 via túnel homelab"
→ PC tenta acessar 192.168.31.228 (ele mesmo!)
→ Envia pro túnel → Túnel devolve → LOOP INFINITO!
```

### ✅ A Solução: Dois Perfis Diferentes

**Painel:** `Settings → WARP Client → Device profiles`

---

#### 🔵 Perfil 1: `Servidor-Casa` (Para o Homelab)

**Objetivo:** Permitir que o PC acesse a VPS via WARP, mas **NÃO** roteie tráfego para sua própria rede.

| Campo | Valor |
|-------|-------|
| **Name** | `Servidor-Casa` |
| **Precedence** | `1` (prioridade MAIS ALTA) |
| **Assignment Rule** | `User email` **is** `deyvid-servidor@seudominio.com` |
| **Split Tunnel Mode** | `Exclude IPs and domains` |
| **Exclusions** | `192.168.31.0/24`, `127.0.0.1/32`, `::1/128` |

**Como criar:**

1. `Device profiles` → `Add a profile` → `Create new profile`
2. Preencha os campos acima
3. Em `Assign to users`, configure:
   - `Selector: User email`
   - `Operator: is`
   - `Value: deyvid-servidor@seudominio.com`
4. Em `Split Tunnels`:
   - `Mode: Exclude IPs and domains`
   - `Add destination` para cada exclusão
5. `Save profile`

**📌 Resultado:** Quando o Homelab logar com este email, ele:
- ✅ Roteia tráfego para VPS (31.97.23.42) via WARP
- ❌ Ignora tráfego para 192.168.31.0/24 (usa rede local diretamente)
- ❌ Ignora localhost (127.0.0.1)

---

#### 🟢 Perfil 2: `Clientes-Externos` (Notebooks, Celulares)

**Objetivo:** Rotear **apenas** tráfego para VPS e Homelab via WARP. Todo o resto (Netflix, Google) usa internet local.

| Campo | Valor |
|-------|-------|
| **Name** | `Clientes-Externos` |
| **Precedence** | `2` (prioridade MENOR) |
| **Assignment Rule** | `User email` **is not** `deyvid-servidor@seudominio.com` |
| **Split Tunnel Mode** | `Include IPs and domains` |
| **Inclusions** | `192.168.31.0/24`, `31.97.23.42/32` |

**Como criar:**

1. `Add a profile` → `Create new profile`
2. Preencha os campos
3. `Assign to users`:
   - `Selector: User email`
   - `Operator: is not`
   - `Value: deyvid-servidor@seudominio.com`
4. `Split Tunnels`:
   - `Mode: Include IPs and domains`
   - Add: `192.168.31.0/24`
   - Add: `31.97.23.42/32`
5. `Save profile`

**📌 Resultado:** Notebooks e celulares:
- ✅ Roteiam SSH/DB para VPS e Homelab via WARP
- ✅ Acessam internet normalmente (sem lentidão)

---

### 🎓 Entendendo Precedence

- **Número MENOR = MAIOR prioridade**
- Cloudflare testa perfis em ordem crescente de `Precedence`
- O **primeiro perfil que der match** é aplicado
- Por isso `Servidor-Casa` (1) vem antes de `Clientes-Externos` (2)

---

## 6. Configuração dos Clientes WARP

### 🖥️ Homelab (Configuração Especial)

**⚠️ CRÍTICO:** Deve usar **Identidade B** (`deyvid-servidor@...`) para pegar o perfil correto!

```bash
# No PC de casa
sudo systemctl start warp-svc

# Limpar qualquer registro anterior
warp-cli registration delete

# Novo registro
warp-cli registration new
```

**🔥 PROBLEMA COMUM:** O navegador loga automaticamente com sua conta principal (Identidade A).

**✅ SOLUÇÃO:**

1. O comando acima mostra um URL: `Please visit: https://...`
2. **NÃO clique** direto no terminal
3. **Copie o URL**
4. Abra **janela anônima/privada** no navegador
5. Cole o URL
6. Faça login com **Identidade B** (`deyvid-servidor@...`)

```bash
# Conectar
warp-cli connect

# Verificar qual perfil foi aplicado
warp-cli settings

# Deve mostrar exclusões: 192.168.31.0/24, 127.0.0.1/32, ::1/128
```

---

### 💻 Notebooks e Dispositivos Móveis

**Usar Identidade A** (`deyvid-pessoal@...`):

#### Linux

```bash
# Instalar
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt update && sudo apt install cloudflare-warp

# Registrar e conectar
warp-cli registration new
warp-cli connect
```

#### Windows

1. Download: https://1.1.1.1/
2. Instalar e abrir o app
3. Clicar em "Connect"
4. Fazer login com **Identidade A**

#### macOS

1. Download: https://1.1.1.1/
2. Instalar o app
3. Preferences → Account → Login with Cloudflare Zero Trust
4. Usar **Identidade A**

#### Android/iOS

1. Baixar app "1.1.1.1" na Play Store/App Store
2. Abrir → Menu → Account → Login with Cloudflare Zero Trust
3. Usar **Identidade A**

---

### ✅ Verificação

```bash
# Linux/macOS
warp-cli status
# Deve mostrar: Connected

# Ver qual perfil está ativo
warp-cli settings | grep -A 20 "Split"

# Testar conectividade
ping 31.97.23.42
ping 192.168.31.228
```

---

## 7. Blindagem com UFW + Docker

### ⚠️ O Grande Problema: Docker Bypass do UFW

Por padrão, Docker **ignora completamente** as regras do UFW:

```
Docker cria container → Adiciona regras diretas no iptables
→ PULA o UFW → Porta fica exposta!
```

**Exemplo real:**

```bash
# Você configura UFW
sudo ufw deny 5432

# Mas Docker expõe PostgreSQL
docker run -p 5432:5432 postgres

# Resultado: Porta 5432 ESTÁ ACESSÍVEL! 😱
```

### ✅ A Solução: Chain DOCKER-USER

O Docker possui uma "trava de segurança" chamada `DOCKER-USER` chain. Vamos usá-la!

---

### 🛡️ Configuração Completa do Firewall

**⚠️ AVISO:** Execute estas mudanças **conectado via WARP ou console do provedor**. Se fizer via SSH público, pode se trancar para fora!

#### Passo 1: Regras Básicas do UFW

```bash
# Conecte-se via WARP ou console
ssh root@31.97.23.42  # (via WARP)

# Política padrão
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir web pública (essencial para apps web)
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Permitir acesso total de clientes WARP
sudo ufw allow in from 100.64.0.0/10 comment 'Cloudflare WARP'

# Permitir loopback (comunicação interna)
sudo ufw allow in on lo comment 'Localhost'
```

**🔑 Explicação:**
- `100.64.0.0/10` é a faixa de IPs CGNAT usada pelo WARP
- Todo cliente WARP aparece como vindo desta rede
- Isso permite SSH, DB, painéis admin via WARP

---

#### Passo 2: Forçar Docker a Respeitar UFW

```bash
# Editar regras avançadas do UFW
sudo nano /etc/ufw/before.rules
```

**Role até o FINAL do arquivo** (após todos os `COMMIT`) e adicione:

```ini
#
# Regras para forçar Docker a respeitar UFW
# ADICIONAR NO FINAL DO ARQUIVO
#

*filter
:DOCKER-USER - [0:0]

# 1. Permitir portas web públicas (80 e 443)
-A DOCKER-USER -p tcp -m tcp --dport 80 -j RETURN
-A DOCKER-USER -p tcp -m tcp --dport 443 -j RETURN

# 2. Permitir tráfego interno do Docker (containers entre si)
-A DOCKER-USER -i docker0 -j RETURN
-A DOCKER-USER -i br-+ -j RETURN

# 3. Permitir loopback (host para containers)
-A DOCKER-USER -i lo -j RETURN

# 4. Permitir redes privadas Docker (172.x.x.x)
-A DOCKER-USER -s 172.16.0.0/12 -j RETURN

# 5. Permitir acesso via Cloudflare WARP
-A DOCKER-USER -s 100.64.0.0/10 -j RETURN

# 6. BLOQUEAR todo o resto vindo da interface pública
# Ajuste 'eth0' para o nome da sua interface pública
-A DOCKER-USER -i eth0 -j DROP

COMMIT
```

**Salvar:** `Ctrl+O` → `Enter` → `Ctrl+X`

**🔍 Como descobrir sua interface pública:**

```bash
ip addr show
# Procure pela interface com seu IP público (31.97.23.42)
# Normalmente: eth0, ens3, enp0s3
```

---

#### Passo 3: Aplicar Configurações (CRÍTICO!)

```bash
# 1. Recarregar UFW (lê as novas regras)
sudo ufw reload

# 2. Reiniciar Docker (ESSENCIAL! Sem isso, não funciona)
sudo systemctl restart docker

# 3. Reiniciar cloudflared (se parou)
sudo systemctl restart cloudflared

# 4. Ativar UFW (se não estava ativo)
sudo ufw enable

# 5. Verificar status
sudo ufw status verbose
```

**⚠️ Por que reiniciar Docker?**
- Docker lê a chain `DOCKER-USER` **apenas na inicialização**
- Se não reiniciar, continua usando as regras antigas

---

#### Passo 4: Verificar Segurança

```bash
# Ver regras iptables do Docker
sudo iptables -L DOCKER-USER -n -v

# Deve mostrar as regras que adicionamos
# Se estiver vazio, o Docker não leu o arquivo!

# Listar portas abertas
sudo ss -tlnp

# Testar de fora (SEM WARP ligado)
# Em outro PC/celular, desconecte WARP e tente:
nmap -p 22,80,443,5432,8000,19999 31.97.23.42
```

**✅ Resultado esperado:**

```
PORT     STATE    SERVICE
80/tcp   open     http       ← Correto
443/tcp  open     https      ← Correto
22/tcp   filtered ssh        ← Correto (bloqueado)
5432/tcp filtered postgresql ← Correto (bloqueado)
8000/tcp filtered unknown    ← Correto (bloqueado)
19999/tcp filtered unknown   ← Correto (bloqueado)
```

---

### 🔧 Troubleshooting: Aplicações Pararam?

Se após configurar o firewall suas aplicações web pararam de funcionar:

**Causa comum:** `cloudflared` não consegue acessar containers.

**Solução:**

```bash
# Verificar logs do cloudflared
sudo journalctl -u cloudflared -n 50

# Se ver erros de conexão, verifique as regras
sudo nano /etc/ufw/before.rules

# Certifique-se que estas linhas existem:
# -A DOCKER-USER -i docker0 -j RETURN
# -A DOCKER-USER -i lo -j RETURN
# -A DOCKER-USER -s 172.16.0.0/12 -j RETURN

# Recarregar
sudo ufw reload
sudo systemctl restart docker cloudflared
```

---

## 8. Terminal SSH no Navegador

### 🌐 Feature: Acesso SSH Sem Cliente

**Problema que resolve:**
- Computador público sem cliente SSH instalado
- Tablet/celular iOS sem app SSH
- Firewall corporativo bloqueando SSH
- Querer acesso de emergência de qualquer lugar

**Solução:** Terminal SSH renderizado no navegador via Cloudflare Access.

---

### 📡 Fase 1: Configurar o Túnel (Public Hostname)

**Objetivo:** Associar um domínio (ex: `ssh.agilytech.com`) ao serviço SSH do servidor.

#### Para VPS

1. **Painel:** `Zero Trust → Networks → Tunnels`
2. Clique em `Configure` no túnel `vps-tunnel`
3. Vá para a aba `Public Hostname`
4. Clique `Add a public hostname`
5. Configure:
   ```
   Subdomain: ssh
   Domain: agilytech.com
   Path: (deixe vazio)

   Service:
     Type: SSH
     URL: ssh://localhost:22
   ```
6. `Save hostname`

#### Para Homelab

**Mesmo processo**, mas no túnel `homelab`:

```
Subdomain: ssh-home
Domain: agilytech.com

Service:
  Type: SSH
  URL: ssh://localhost:22
```

**💡 Resultado até aqui:**
- `ssh.agilytech.com` → SSH da VPS
- `ssh-home.agilytech.com` → SSH do Homelab

**⚠️ MAS:** Se tentar acessar agora, verá uma "tela branca". Falta o porteiro (Access)!

---

### 🔐 Fase 2: Configurar Aplicação de Acesso (A Mágica)

**Objetivo:** Proteger o hostname e habilitar o terminal no navegador.

#### Passo 1: Criar Aplicação

1. **Painel:** `Zero Trust → Access → Applications`
2. Clique `Add an application`
3. Escolha `Self-hosted`

#### Passo 2: Configurar Aplicação

**Aba: Application Configuration**

| Campo | Valor |
|-------|-------|
| **Application name** | `VPS SSH (Web)` |
| **Session Duration** | `1 hour` (recomendado para segurança) |
| **Application domain** | |
| - Subdomain | `ssh` |
| - Domain | `agilytech.com` |

#### Passo 3: Adicionar Política de Acesso

**Ainda na mesma tela, seção "Add policies":**

1. **Policy name:** `Permitir Meu Email`
2. **Action:** `Allow`
3. **Configure rules:**
   - `Selector: Emails`
   - `Value: deyvid-pessoal@seudominio.com`
4. Clique `Next`

#### Passo 4: ATIVAR RENDERIZAÇÃO (CRÍTICO!)

**Aba: Additional settings**

1. Role até a seção `Browser rendering`
2. **LIGUE** a opção: `Enable browser rendering` ✅
3. **LIGUE** também: `Enable binding cookie` ✅ (segurança extra)

**🔑 Por que isso é crítico?**

Sem isso, Cloudflare envia protocolo SSH puro → Navegador não entende → Tela branca!

Com isso, Cloudflare atua como "tradutor" → Converte SSH em terminal HTML5 → Navegador renderiza!

4. Clique `Save application`

---

### 🚀 Usando o Terminal Web

1. **Abrir navegador** (qualquer dispositivo)
2. Acessar: `https://ssh.agilytech.com`
3. **Login:** Cloudflare pede autenticação
   - Use **Identidade A** (`deyvid-pessoal@...`)
   - Pode receber código OTP no email
4. **Terminal SSH aparece!**
   - Username: `root` (ou seu usuário)
   - Password: senha do SSH
   - Ou use chave SSH (se configurou)

**🎉 Pronto!** Terminal SSH completo no navegador, sem instalar nada.

---

### 🔄 Repetir para Homelab

Crie segunda aplicação:

```
Application name: Homelab SSH (Web)
Application domain: ssh-home.agilytech.com
Policy: Permitir Meu Email
Browser rendering: ENABLED
```

Agora tem:
- `ssh.agilytech.com` → VPS
- `ssh-home.agilytech.com` → Homelab

---

### 🛡️ Segurança Adicional

#### Adicionar Autenticação de Dois Fatores

1. Na aplicação, aba `Policies`
2. Editar política existente
3. Adicionar regra extra:
   ```
   Include:
     - Emails: seu-email@...
   Require:
     - Authentication method: One-time PIN
   ```

#### Restringir por País

```
Include:
  - Emails: seu-email@...
Require:
  - Country: Brazil, United States
```

#### Adicionar Múltiplos Usuários

```
Include:
  - Emails: usuario1@..., usuario2@..., usuario3@...
```

---

## 9. Acesso a Bancos de Dados Remotos

### 💾 Feature: Conectar DBeaver, pgAdmin, etc via WARP

**Problema que resolve:**
- Bancos de dados privados (PostgreSQL, MySQL, MongoDB)
- Não expor portas públicas (5432, 3306, 27017)
- Acessar de qualquer lugar com segurança

---

### 🔧 Configuração

**Pré-requisito:** WARP ligado no seu PC.

#### PostgreSQL (Coolify ou standalone)

**No DBeaver/pgAdmin:**

```
Host: 31.97.23.42
Port: 5432 (ou 5433, 5434 se múltiplos DBs)
Database: nome_do_banco
Username: postgres
Password: sua_senha
SSL: Disable (conexão já é criptografada pelo WARP)
```

**Testar conexão:**

```bash
# Via terminal (com WARP ligado)
psql -h 31.97.23.42 -U postgres -d nome_banco
```

#### MySQL/MariaDB

```
Host: 31.97.23.42
Port: 3306
Username: root
Password: sua_senha
```

#### MongoDB

```
Connection String: mongodb://31.97.23.42:27017/nome_banco
```

---

### 🔒 Segurança: Por Que Isso É Seguro?

```
Seu PC com WARP → Criptografia → Cloudflare → Túnel → VPS
                    (TLS 1.3)                    (Firewall bloqueia
                                                   acesso direto)
```

**Verificação:**

```bash
# SEM WARP (deve falhar)
warp-cli disconnect
telnet 31.97.23.42 5432
# Connection refused ✅

# COM WARP (deve funcionar)
warp-cli connect
telnet 31.97.23.42 5432
# Connected ✅
```

---

## 10. Aplicações Web com Cloudflare Access

### 🌐 Proteger Painéis Admin com Login

**Cenário:** Você tem Netdata, Coolify UI, Grafana, etc rodando.

**Problema:**
- Expor na porta 80/443 = qualquer um pode acessar
- Bloquear = você também não acessa de fora

**Solução:** Cloudflare Access = Login antes de acessar.

---

### 🔧 Configuração Completa

#### Exemplo: Proteger Netdata (porta 19999)

**Passo 1: Adicionar Public Hostname no Túnel**

1. `Zero Trust → Networks → Tunnels`
2. Túnel `vps-tunnel` → `Configure` → `Public Hostname`
3. `Add a public hostname`:
   ```
   Subdomain: netdata
   Domain: agilytech.com

   Service:
     Type: HTTP
     URL: http://localhost:19999
   ```

**Passo 2: Criar Aplicação Access**

1. `Zero Trust → Access → Applications`
2. `Add an application` → `Self-hosted`
3. Configure:
   ```
   Name: Netdata Monitoring
   Session Duration: 24 hours

   Application domain:
     Subdomain: netdata
     Domain: agilytech.com

   Policy:
     Name: Acesso Restrito
     Action: Allow
     Include: Emails → seu-email@...
   ```

4. **NÃO** ative `Browser rendering` (não é SSH, é web normal)
5. `Save application`

**Resultado:**
- Acessar `https://netdata.agilytech.com`
- Cloudflare pede login
- Após login, Netdata aparece normalmente

---

### 📋 Outros Serviços Comuns

#### Coolify UI (porta 8000)

```
Public Hostname:
  Subdomain: coolify
  URL: http://localhost:8000

Access Application:
  Name: Coolify Admin
  Session: 12 hours
  Policy: Allow emails (seu-email)
```

#### Portainer (porta 9000)

```
Public Hostname:
  Subdomain: portainer
  URL: http://localhost:9000

Access Application:
  Name: Portainer
  Policy: Allow emails
```

#### Grafana (porta 3000)

```
Public Hostname:
  Subdomain: grafana
  URL: http://localhost:3000

Access Application:
  Name: Grafana Dashboards
  Policy: Allow emails
```

---

### 🔐 Políticas Avançadas

#### Permitir Equipe Inteira

```
Include:
  - Email domain: empresa.com
```

#### Exigir GitHub SSO

1. `Settings → Authentication → Login methods`
2. `Add new` → `GitHub`
3. Configurar OAuth App no GitHub
4. Na política da aplicação:
   ```
   Include:
     - Login method: GitHub
     - GitHub organization: sua-org
   ```

#### Exigir Localização + Email

```
Include:
  - Emails: seu-email@...
Require:
  - Country: Brazil
```

---

## 11. Como o Tráfego Flui

### 🌐 Cenário 1: Aplicação Web Pública (via Domínio)

**Exemplo:** Usuário acessa `https://analytics.agilytech.com`

```
┌──────────────┐
│ Usuário      │
│ (Navegador)  │
└──────┬───────┘
       │ 1. DNS lookup
       ↓
┌─────────────────────────────────┐
│ DNS: analytics.agilytech.com    │
│ Resolve: 104.21.x.x (Cloudflare)│  ← NÃO é seu IP!
└──────┬──────────────────────────┘
       │ 2. HTTPS request
       ↓
┌─────────────────────────────────┐
│ Cloudflare Edge                 │
│ • CDN (cache se configurado)    │
│ • WAF (bloqueia ataques)        │
│ • DDoS protection               │
│ • SSL/TLS termination           │
└──────┬──────────────────────────┘
       │ 3. Túnel criptografado
       ↓
┌─────────────────────────────────┐
│ VPS: cloudflared                │
│ Escuta em localhost:PORTA       │
└──────┬──────────────────────────┘
       │ 4. Proxy reverso interno
       ↓
┌─────────────────────────────────┐
│ Coolify/Traefik                 │
│ Roteia para container correto   │
└──────┬──────────────────────────┘
       │ 5. HTTP local
       ↓
┌─────────────────────────────────┐
│ Container Docker                │
│ Netdata:19999                   │
│ (Escutando apenas localhost)    │
└──────┬──────────────────────────┘
       │ 6. Resposta HTTP
       │
       ↓ (Caminho reverso)
┌──────────────┐
│ Usuário      │ Recebe HTML/CSS/JS
└──────────────┘
```

**🔑 Pontos-chave:**
- Porta 19999 **nunca foi acessada externamente**
- Tráfego entrou pela 443 (pública)
- Roteamento interno via `localhost`
- Firewall nem foi testado (tráfego interno)

---

### 🔴 Cenário 2: Tentativa de Acesso Direto (BLOQUEADO)

**Exemplo:** Hacker tenta `http://31.97.23.42:19999`

```
┌──────────────┐
│ Atacante     │
└──────┬───────┘
       │ 1. HTTP GET 31.97.23.42:19999
       ↓
┌─────────────────────────────────┐
│ Internet                        │
└──────┬──────────────────────────┘
       │ 2. Pacote chega na VPS
       ↓
┌─────────────────────────────────┐
│ VPS: Interface pública (eth0)   │
│ IP: 31.97.23.42                 │
└──────┬──────────────────────────┘
       │ 3. Firewall analisa
       ↓
┌─────────────────────────────────┐
│ iptables: Chain DOCKER-USER     │
│                                 │
│ Regra 1: Porta 80? NÃO          │
│ Regra 2: Porta 443? NÃO         │
│ Regra 3: Origem 100.64.x.x? NÃO │
│ Regra 4: Interface docker0? NÃO │
│ ...                             │
│ Última regra: DROP! ❌          │
└──────┬──────────────────────────┘
       │ 4. Pacote descartado
       ↓
┌──────────────┐
│ Atacante     │ Connection timeout
└──────────────┘
```

**🔑 Resultado:** Porta parece **não existir** (stealth mode).

---

### 🟢 Cenário 3: Acesso SSH via WARP

**Exemplo:** Você com WARP ligado faz `ssh root@31.97.23.42`

```
┌──────────────┐
│ Seu PC       │
│ WARP: ON     │
└──────┬───────┘
       │ 1. ssh root@31.97.23.42
       ↓
┌─────────────────────────────────┐
│ Cliente WARP                    │
│ Detecta: 31.97.23.42 em Include │
│ Decisão: Rotear via Cloudflare  │
└──────┬──────────────────────────┘
       │ 2. Encapsula em WireGuard
       ↓
┌─────────────────────────────────┐
│ Cloudflare Network              │
│ • Descriptografa                │
│ • Consulta: "31.97.23.42 via?"  │
│ • Encontra: vps-tunnel          │
└──────┬──────────────────────────┘
       │ 3. Túnel cloudflared
       ↓
┌─────────────────────────────────┐
│ VPS: cloudflared                │
│ Recebe pacote                   │
│ IP origem: 100.64.x.x (WARP)    │
└──────┬──────────────────────────┘
       │ 4. Firewall analisa
       ↓
┌─────────────────────────────────┐
│ UFW/iptables                    │
│ Regra: 100.64.0.0/10 = ALLOW ✅ │
└──────┬──────────────────────────┘
       │ 5. Encaminha para porta 22
       ↓
┌─────────────────────────────────┐
│ SSH Server                      │
│ Autentica e cria sessão         │
└──────┬──────────────────────────┘
       │ 6. Resposta SSH
       │
       ↓ (Caminho reverso)
┌──────────────┐
│ Seu PC       │ Shell interativo
└──────────────┘
```

**🔑 Pontos-chave:**
- Conexão **nunca tocou a internet pública** diretamente
- Passou pela rede privada Cloudflare (CGNAT)
- Firewall reconheceu IP WARP (100.64.x.x)
- SSH autenticou normalmente

---

### 🏠 Cenário 4: Homelab Acessa VPS (Sem Loop)

**Exemplo:** PC de casa (com WARP) faz `ssh root@31.97.23.42`

```
┌──────────────────────┐
│ Homelab              │
│ IP: 192.168.31.228   │
│ WARP: ON (Perfil 1)  │
└──────┬───────────────┘
       │ 1. ssh root@31.97.23.42
       ↓
┌─────────────────────────────────┐
│ Cliente WARP                    │
│ Perfil: Servidor-Casa           │
│ Exclusões: 192.168.31.0/24      │
│                                 │
│ Decisão:                        │
│ • 31.97.23.42 NÃO está excluído │
│ • Rotear via Cloudflare ✅      │
└──────┬──────────────────────────┘
       │ 2. Túnel WARP
       ↓
┌─────────────────────────────────┐
│ Cloudflare Network              │
│ Roteia para vps-tunnel          │
└──────┬──────────────────────────┘
       │ 3. Conexão SSH normal
       ↓
┌─────────────────────────────────┐
│ VPS                             │
│ SSH responde                    │
└──────┬──────────────────────────┘
       │ 4. Resposta
       ↓
┌──────────────────────┐
│ Homelab              │ Conectado!
└──────────────────────┘
```

**✅ Por que NÃO deu loop?**
- Exclusão `192.168.31.0/24` só afeta tráfego para **essa rede**
- `31.97.23.42` está **fora** da exclusão
- WARP roteia normalmente

---

### ❌ Cenário 5: Homelab Tenta Acessar a Si Mesmo (Bloqueado)

**Exemplo:** PC de casa tenta `ssh deyvid@192.168.31.228`

```
┌──────────────────────┐
│ Homelab              │
│ IP: 192.168.31.228   │
│ WARP: ON (Perfil 1)  │
└──────┬───────────────┘
       │ 1. ssh deyvid@192.168.31.228
       ↓
┌─────────────────────────────────┐
│ Cliente WARP                    │
│ Perfil: Servidor-Casa           │
│ Exclusões: 192.168.31.0/24      │
│                                 │
│ Decisão:                        │
│ • 192.168.31.228 está excluído  │
│ • NÃO rotear pelo WARP          │
│ • Usar interface local ❌       │
└──────┬──────────────────────────┘
       │ 2. Tenta acesso direto
       ↓
┌─────────────────────────────────┐
│ Kernel Linux                    │
│ Detecta: destino = próprio IP   │
│ Redireciona para loopback       │
│ MAS: SSH escuta em eth0, não lo │
│ FALHA ❌                        │
└──────┬──────────────────────────┘
       │ Connection refused
       ↓
┌──────────────────────┐
│ Homelab              │ Erro
└──────────────────────┘
```

**💡 Solução:** Para acessar o próprio PC localmente:

```bash
# Desligar WARP temporariamente
warp-cli disconnect

# OU acessar via localhost
ssh deyvid@localhost

# OU adicionar regra SSH para escutar em loopback
# /etc/ssh/sshd_config:
# ListenAddress 0.0.0.0
# ListenAddress ::
# ListenAddress 127.0.0.1
```

---

## 12. Testes e Validação

### ✅ Checklist de Funcionalidade

Execute todos os testes abaixo para garantir que tudo está funcionando:

#### 1. Túneis Cloudflare

```bash
# Em cada servidor
sudo systemctl status cloudflared

# Deve mostrar: active (running)
# Se não: sudo systemctl restart cloudflared

# Ver logs
sudo journalctl -u cloudflared -n 50 --no-pager

# Painel web
# Zero Trust → Networks → Tunnels
# Ambos devem estar: HEALTHY (verde)
```

#### 2. Firewall (Portas Bloqueadas)

**De um dispositivo SEM WARP** (celular em 4G, PC de amigo):

```bash
# Online scanner
# Acesse: https://www.yougetsignal.com/tools/open-ports/
# IP: 31.97.23.42
# Portas: 22, 5432, 8000, 19999
# Resultado esperado: CLOSED

# Ou via nmap (se tiver instalado)
nmap -p 22,80,443,5432,8000,19999 31.97.23.42

# Resultado esperado:
# 80/tcp   open
# 443/tcp  open
# 22/tcp   filtered  ✅
# 5432/tcp filtered  ✅
# 8000/tcp filtered  ✅
# 19999/tcp filtered ✅
```

#### 3. Acesso via WARP (SSH)

**Do seu PC com WARP ligado:**

```bash
# Verificar WARP
warp-cli status
# Deve mostrar: Connected

# Testar SSH da VPS
ssh root@31.97.23.42
# Deve conectar ✅

# Testar SSH do Homelab
ssh deyvid@192.168.31.228
# Deve conectar (se não for do próprio Homelab) ✅

# Testar PostgreSQL
psql -h 31.97.23.42 -U postgres
# Deve conectar ✅
```

#### 4. Terminal SSH no Navegador

```bash
# Abrir navegador (pode desligar WARP para este teste)
warp-cli disconnect

# Acessar
https://ssh.agilytech.com

# Resultado esperado:
# 1. Página de login Cloudflare ✅
# 2. Após login, terminal SSH aparece ✅
# 3. Consegue digitar comandos ✅
```

#### 5. Aplicações Web Protegidas

```bash
# Netdata (deve pedir login)
https://netdata.agilytech.com

# Coolify (deve pedir login)
https://coolify.agilytech.com

# Site público (NÃO deve pedir login)
https://seusite.agilytech.com
```

#### 6. Perfis WARP Corretos

```bash
# No Homelab
warp-cli settings | grep -A 10 "Split"
# Deve mostrar exclusões: 192.168.31.0/24

# No notebook
warp-cli settings | grep -A 10 "Split"
# Deve mostrar inclusões: 192.168.31.0/24, 31.97.23.42/32
```

---

### 🔍 Testes de Segurança Avançados

#### Teste 1: Bypass via IP Direto (Deve Falhar)

```bash
# SEM WARP, tentar acessar aplicação por IP
curl -v http://31.97.23.42:19999

# Resultado esperado: Connection timeout ou refused
```

#### Teste 2: Scan de Portas Completo

```bash
# De fora (sem WARP)
nmap -p- -T4 31.97.23.42

# Deve mostrar APENAS 80 e 443 abertas
# Todas as outras: filtered ou closed
```

#### Teste 3: Tentar SQL Injection (Simulado)

```bash
# SEM WARP, tentar conectar PostgreSQL
psql -h 31.97.23.42 -U postgres

# Resultado esperado:
# psql: error: connection timed out
```

#### Teste 4: Verificar Headers de Segurança

```bash
curl -I https://seusite.agilytech.com

# Deve incluir (Cloudflare adiciona automaticamente):
# cf-ray: xxxxx
# cf-cache-status: xxx
# server: cloudflare
```

---

### 📊 Benchmark de Performance

#### Latência WARP vs Direto

```bash
# COM WARP
warp-cli connect
ping -c 10 31.97.23.42

# SEM WARP (se ainda tiver SSH aberto temporariamente)
warp-cli disconnect
ping -c 10 31.97.23.42

# Comparar tempos
# Normalmente: +5-20ms de overhead (aceitável)
```

#### Velocidade de Transferência

```bash
# Criar arquivo de teste (100MB)
dd if=/dev/zero of=teste.bin bs=1M count=100

# Upload via WARP+SSH
warp-cli connect
scp teste.bin root@31.97.23.42:/tmp/

# Download
scp root@31.97.23.42:/tmp/teste.bin teste-download.bin

# Observar velocidade (deve ser >10 MB/s em boa conexão)
```

---

## 13. Troubleshooting Completo

### 🔴 Problema: "Me tranquei para fora do SSH!"

**Sintomas:**
- Configurou UFW
- Desconectou WARP
- Agora não consegue conectar via SSH

**Soluções:**

#### Opção 1: Console do Provedor

```bash
# Hetzner Cloud: Console → Launch Console
# AWS: EC2 → Connect → Session Manager
# DigitalOcean: Droplet → Access → Launch Console

# Uma vez dentro:
sudo ufw status
sudo ufw allow from SEU_IP_ATUAL to any port 22
# Ou temporariamente:
sudo ufw disable
```

#### Opção 2: Se Tinha WARP Ligado Antes

```bash
# Religar WARP
warp-cli connect

# Tentar SSH
ssh root@31.97.23.42
```

#### Opção 3: Recovery Mode

Alguns provedores permitem boot em modo de recuperação:
- Hetzner: Rescue System
- AWS: EC2 Rescue
- DigitalOcean: Recovery Console

---

### 🔴 Problema: "Aplicações web pararam após configurar firewall"

**Sintomas:**
- Sites funcionavam antes
- Após configurar UFW/Docker, erro 502/504
- `cloudflared` rodando, mas apps inacessíveis

**Diagnóstico:**

```bash
# Ver logs do cloudflared
sudo journalctl -u cloudflared -n 100 --no-pager

# Procurar por erros como:
# "dial tcp 127.0.0.1:19999: connect: connection refused"
```

**Causa:** Firewall bloqueando `cloudflared` de acessar containers.

**Solução:**

```bash
# Verificar regras DOCKER-USER
sudo iptables -L DOCKER-USER -n -v

# Se estiver vazio, editar
sudo nano /etc/ufw/before.rules

# Adicionar (se não existir):
-A DOCKER-USER -i docker0 -j RETURN
-A DOCKER-USER -i lo -j RETURN
-A DOCKER-USER -s 172.16.0.0/12 -j RETURN

# Recarregar
sudo ufw reload
sudo systemctl restart docker
sudo systemctl restart cloudflared

# Aguardar 30s e testar novamente
```

---

### 🔴 Problema: "WARP conecta mas não acesso os servidores"

**Sintomas:**
- `warp-cli status` mostra "Connected"
- SSH/DB ainda não funcionam

**Diagnóstico:**

```bash
# Ver configurações do WARP
warp-cli settings

# Verificar rotas
ip route | grep 100.64
```

**Causas possíveis:**

#### Causa 1: Perfil Errado

```bash
# Ver qual perfil está ativo
warp-cli settings | grep -i "split"

# Se não mostrar os IPs corretos:
warp-cli registration delete
warp-cli registration new
# Fazer login com email correto
warp-cli connect
```

#### Causa 2: Private Networks Não Configuradas

- Painel: `Zero Trust → Networks → Tunnels`
- Verificar que cada túnel tem `Private Networks` configuradas:
  - `vps-tunnel`: 31.97.23.42/32
  - `homelab`: 192.168.31.0/24

#### Causa 3: Túneis Offline

```bash
# Em cada servidor
sudo systemctl status cloudflared

# Se parado:
sudo systemctl restart cloudflared
```

---

### 🔴 Problema: "Terminal SSH no navegador mostra tela branca"

**Sintomas:**
- Acessa `ssh.agilytech.com`
- Faz login no Cloudflare
- Tela branca ou erro genérico

**Causa:** `Browser rendering` não foi ativado.

**Solução:**

1. `Zero Trust → Access → Applications`
2. Encontrar aplicação (`VPS SSH (Web)`)
3. `Edit`
4. Aba `Settings` → `Additional settings`
5. **LIGAR:** `Enable browser rendering` ✅
6. `Save application`
7. Aguardar 1 minuto e tentar novamente

---

### 🔴 Problema: "Loop no Homelab"

**Sintomas:**
- PC de casa trava ao conectar WARP
- `warp-cli connect` demora infinitamente
- Não consegue acessar nada

**Causa:** PC logado com Identidade A (perfil errado).

**Solução:**

```bash
# Desconectar
warp-cli disconnect

# Deletar registro
warp-cli registration delete

# Novo registro (ATENÇÃO AO EMAIL!)
warp-cli registration new

# Quando aparecer o URL, copiar e abrir em JANELA ANÔNIMA
# Logar com Identidade B (deyvid-servidor@...)

# Conectar
warp-cli connect

# Verificar perfil
warp-cli settings | grep -A 10 "Split"
# Deve mostrar EXCLUSÕES (não inclusões)
```

---

### 🔴 Problema: "Coolify não consegue fazer deploy após firewall"

**Sintomas:**
- Coolify web UI funciona
- Mas deploys de novas aplicações falham
- Containers não conseguem baixar imagens

**Causa:** Firewall bloqueando tráfego de saída dos containers.

**Solução:**

```bash
# Verificar política padrão
sudo ufw status verbose

# Deve mostrar:
# Default: deny (incoming), allow (outgoing)

# Se outgoing estiver deny:
sudo ufw default allow outgoing

# Recarregar
sudo ufw reload
sudo systemctl restart docker
```

---

### 🔴 Problema: "Domínio não resolve após adicionar ao Cloudflare"

**Sintomas:**
- Adicionou domínio no Cloudflare
- `nslookup seudominio.com` não funciona

**Causa:** Nameservers não foram alterados no registrador.

**Solução:**

```bash
# Verificar nameservers atuais
dig NS seudominio.com +short

# Deve mostrar algo como:
# ns1.cloudflare.com
# ns2.cloudflare.com

# Se mostrar outros:
# 1. Ir ao registrador (Registro.br, GoDaddy, etc)
# 2. Alterar para nameservers do Cloudflare
# 3. Aguardar propagação (até 24h)
```

---

## 14. Monitoramento e Logs

### 📊 Logs Essenciais

#### Cloudflared (Túneis)

```bash
# Ver logs em tempo real
sudo journalctl -u cloudflared -f

# Últimas 100 linhas
sudo journalctl -u cloudflared -n 100 --no-pager

# Filtrar erros
sudo journalctl -u cloudflared -p err -n 50

# Logs de ontem
sudo journalctl -u cloudflared --since yesterday
```

**Erros comuns:**

```
# Erro de conexão
ERR error="dial tcp: lookup localhost: no such host"
→ Solução: Verificar /etc/hosts

# Erro de autenticação
ERR error="failed to authenticate tunnel connection"
→ Solução: Reinstalar cloudflared com novo token

# Erro de roteamento
ERR error="no route to host"
→ Solução: Verificar firewall local
```

---

#### UFW (Firewall)

```bash
# Ver logs do UFW
sudo tail -f /var/log/ufw.log

# Filtrar pacotes bloqueados
sudo grep -i "BLOCK" /var/log/ufw.log | tail -20

# Ver últimos bloqueios por porta
sudo grep "DPT=22" /var/log/ufw.log | tail -10

# Estatísticas de bloqueios
sudo grep -c "BLOCK" /var/log/ufw.log
```

**Ativar logging detalhado:**

```bash
# Nível alto de detalhes
sudo ufw logging high

# Verificar
sudo ufw status verbose
```

---

#### Docker

```bash
# Logs de um container específico
docker logs -f container_name

# Últimas 100 linhas
docker logs --tail 100 container_name

# Logs com timestamps
docker logs -t container_name

# Ver todos os containers rodando
docker ps

# Ver uso de recursos
docker stats
```

---

#### WARP (Cliente)

```bash
# Status detalhado
warp-cli status

# Ver configurações aplicadas
warp-cli settings

# Debugging
warp-cli debug
```

---

### 📈 Monitoramento com Netdata

Se instalou Netdata (recomendado), acesse `https://netdata.agilytech.com`:

**Métricas importantes:**

1. **CPU Usage**
   - Alerta se > 80% por >5 minutos

2. **Memory Usage**
   - Alerta se > 90%

3. **Disk I/O**
   - Verificar gargalos em backups

4. **Network Traffic**
   - Monitorar picos (possível ataque DDoS)

5. **Docker Containers**
   - Ver uso individual por container

6. **System Log**
   - Erros do kernel/systemd

---

### 🔔 Alertas Automatizados

#### Configurar Netdata para Enviar Emails

```bash
# SSH na VPS
ssh root@31.97.23.42

# Editar configuração de alertas
sudo nano /etc/netdata/health_alarm_notify.conf

# Configurar email:
SEND_EMAIL="YES"
DEFAULT_RECIPIENT_EMAIL="seu-email@gmail.com"

# Para Gmail (exemplo):
SENDEMAIL="/usr/bin/sendemail"
EMAIL_SENDER="netdata@agilytech.com"
SMTP_SERVER="smtp.gmail.com:587"
SMTP_USERNAME="seu-email@gmail.com"
SMTP_PASSWORD="sua-senha-app"

# Reiniciar
sudo systemctl restart netdata
```

---

#### Script de Monitoramento Customizado

Crie um script para verificar saúde dos túneis:

```bash
#!/bin/bash
# /usr/local/bin/check-tunnels.sh

TELEGRAM_TOKEN="seu-bot-token"
TELEGRAM_CHAT="seu-chat-id"

send_alert() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT" \
        -d text="🚨 ALERTA VPS: $1"
}

# Verificar cloudflared
if ! systemctl is-active --quiet cloudflared; then
    send_alert "Cloudflared está PARADO!"
    systemctl restart cloudflared
fi

# Verificar uso de disco
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    send_alert "Disco em ${DISK_USAGE}%"
fi

# Verificar memória
MEM_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100)}')
if [ "$MEM_USAGE" -gt 90 ]; then
    send_alert "Memória em ${MEM_USAGE}%"
fi
```

**Agendar no cron:**

```bash
# Editar crontab
crontab -e

# Adicionar (verificar a cada 5 minutos)
*/5 * * * * /usr/local/bin/check-tunnels.sh
```

---

## 15. Comandos Úteis

### 🔧 Cloudflare CLI (cloudflared)

```bash
# Status do serviço
sudo systemctl status cloudflared

# Reiniciar
sudo systemctl restart cloudflared

# Parar
sudo systemctl stop cloudflared

# Ver configuração
sudo cat /etc/cloudflared/config.yml

# Atualizar cloudflared
sudo cloudflared update

# Testar túnel manualmente (debug)
sudo cloudflared tunnel run --token eyJh...
```

---

### 🔧 WARP CLI

```bash
# Conectar/Desconectar
warp-cli connect
warp-cli disconnect

# Status
warp-cli status

# Ver configurações
warp-cli settings

# Deletar registro (fazer novo login)
warp-cli registration delete
warp-cli registration new

# Modo de conexão
warp-cli mode warp  # VPN completa
warp-cli mode doh   # Apenas DNS
```

---

### 🔧 UFW

```bash
# Status completo
sudo ufw status verbose
sudo ufw status numbered  # Com números para deletar regras

# Permitir/Negar
sudo ufw allow 80/tcp
sudo ufw deny 22/tcp
sudo ufw allow from 192.168.1.0/24

# Deletar regra (por número)
sudo ufw delete 3

# Resetar tudo (CUIDADO!)
sudo ufw reset

# Recarregar configuração
sudo ufw reload

# Ver logs
sudo tail -f /var/log/ufw.log
```

---

### 🔧 Docker

```bash
# Listar containers
docker ps              # Rodando
docker ps -a           # Todos (incluindo parados)

# Logs
docker logs -f container_name
docker logs --tail 50 container_name

# Executar comando em container
docker exec -it container_name bash
docker exec container_name ls /app

# Uso de recursos
docker stats

# Limpar recursos não usados
docker system prune -a  # Remove tudo não usado
docker image prune      # Remove imagens órfãs
docker volume prune     # Remove volumes órfãos

# Reiniciar container
docker restart container_name

# Parar/Iniciar
docker stop container_name
docker start container_name
```

---

### 🔧 Diagnóstico de Rede

```bash
# Verificar portas escutando
sudo netstat -tlnp
sudo ss -tlnp           # Alternativa moderna

# Testar conectividade
ping 1.1.1.1
curl -I https://google.com

# Testar porta específica
telnet 31.97.23.42 22
nc -zv 31.97.23.42 22

# Ver rotas
ip route
ip route get 31.97.23.42

# DNS lookup
nslookup agilytech.com
dig agilytech.com

# Trace route
traceroute 31.97.23.42
mtr 31.97.23.42         # Mais detalhado
```

---

### 🔧 Análise de Performance

```bash
# Uso de CPU
top
htop  # Mais amigável (instalar: apt install htop)

# Uso de memória
free -h
vmstat 1

# Uso de disco
df -h
du -sh /*  # Tamanho de cada pasta raiz

# I/O de disco
iostat -x 1

# Processos mais pesados
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
```

---

## 16. Checklist de Segurança

### ✅ Antes de Ir para Produção

#### Infraestrutura Base

- [ ] Cloudflare configurado e ativo
- [ ] Nameservers do domínio apontando para Cloudflare
- [ ] SSL/TLS modo: Full (Strict) em `SSL/TLS → Overview`
- [ ] Túneis cloudflared instalados e HEALTHY
- [ ] Private Networks configuradas em ambos túneis
- [ ] WARP funcionando em pelo menos um dispositivo teste

#### Firewall

- [ ] UFW ativo (`sudo ufw status` = active)
- [ ] Apenas portas 80/443 abertas publicamente
- [ ] Regras DOCKER-USER configuradas em `/etc/ufw/before.rules`
- [ ] Docker reiniciado após mudanças no firewall
- [ ] Teste de scan externo confirmando portas fechadas

#### Acesso

- [ ] SSH funcionando via WARP (porta 22 fechada publicamente)
- [ ] Terminal SSH no navegador funcionando (se configurado)
- [ ] Bancos de dados acessíveis apenas via WARP
- [ ] Painéis admin protegidos com Cloudflare Access
- [ ] Perfis de dispositivo corretos (Homelab com exclusões)

#### Autenticação

- [ ] Dois emails configurados (cliente e servidor)
- [ ] Políticas de acesso criadas para aplicações sensíveis
- [ ] Session duration configurada (1-24h dependendo do serviço)
- [ ] Método de autenticação adicional ativado (OTP, GitHub, Google)

#### Monitoramento

- [ ] Netdata instalado e acessível
- [ ] Logs do cloudflared sem erros críticos
- [ ] Logs do UFW mostrando bloqueios (se esperado)
- [ ] Alertas configurados (email, Telegram, etc)

#### Backups

- [ ] Backup automático de `/etc/ufw/before.rules`
- [ ] Backup automático de `/etc/cloudflared/config.yml`
- [ ] Backup de bancos de dados funcionando
- [ ] Testou restauração de pelo menos um backup

#### Documentação

- [ ] Senhas armazenadas em gerenciador seguro (Bitwarden, 1Password)
- [ ] IPs e domínios documentados
- [ ] Credenciais de acesso anotadas (usuários, emails, senhas)
- [ ] Procedimento de recuperação de desastre escrito

---

### 🔒 Hardening Adicional (Recomendado)

#### SSH

```bash
# Editar configuração
sudo nano /etc/ssh/sshd_config

# Mudanças recomendadas:
PermitRootLogin prohibit-password  # Apenas chaves SSH
PasswordAuthentication no           # Desabilita senhas
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30

# Reiniciar SSH
sudo systemctl restart sshd
```

#### Fail2Ban

```bash
# Instalar
sudo apt install fail2ban

# Configurar
sudo nano /etc/fail2ban/jail.local

# Adicionar:
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Iniciar
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### Atualizações Automáticas

```bash
# Instalar
sudo apt install unattended-upgrades

# Configurar
sudo dpkg-reconfigure -plow unattended-upgrades

# Verificar
sudo systemctl status unattended-upgrades
```

#### Auditoria de Segurança

```bash
# Instalar Lynis
sudo apt install lynis

# Executar auditoria
sudo lynis audit system

# Revisar sugestões no relatório
```

---

## 17. Expansões Futuras

### 🚀 Próximas Features para Adicionar

#### 1. VPN WireGuard para Clientes Legados

**Quando usar:** Dispositivos que não suportam WARP (TVs, IoT, etc).

**Recursos:**
- [WireGuard Installation Guide](https://www.wireguard.com/install/)
- [Cloudflare + WireGuard](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/warp-for-linux/)

**Checklist para implementar:**
- [ ] Instalar WireGuard na VPS
- [ ] Configurar bridge entre WireGuard e WARP
- [ ] Gerar chaves para cada cliente
- [ ] Testar com dispositivo IoT

---

#### 2. Kubernetes Homelab

**Quando usar:** Múltiplos serviços containerizados em casa.

**Recursos:**
- [K3s Lightweight Kubernetes](https://k3s.io/)
- [Cloudflare Tunnel Ingress Controller](https://github.com/cloudflare/cloudflare-ingress-controller)

**Checklist:**
- [ ] Instalar K3s no Homelab
- [ ] Configurar Ingress com Cloudflare Tunnel
- [ ] Migrar containers Docker para pods
- [ ] Configurar ArgoCD para GitOps

---

#### 3. Backup Automático para S3/Backblaze

**Quando usar:** Proteção contra perda de dados.

**Recursos:**
- [Restic Backup](https://restic.net/)
- [Backblaze B2 + Restic](https://help.backblaze.com/hc/en-us/articles/115003231633-Using-Restic-with-B2)

**Checklist:**
- [ ] Criar bucket no Backblaze B2
- [ ] Instalar Restic
- [ ] Configurar cronjob de backup diário
- [ ] Testar restore de emergência

---

#### 4. Logs Centralizados (ELK/Loki)

**Quando usar:** Múltiplos servidores ou análise avançada.

**Recursos:**
- [Grafana Loki](https://grafana.com/oss/loki/)
- [Promtail + Loki + Grafana](https://grafana.com/docs/loki/latest/installation/)

**Checklist:**
- [ ] Instalar Loki na VPS
- [ ] Configurar Promtail em todos os servidores
- [ ] Criar dashboards no Grafana
- [ ] Configurar alertas de log

---

#### 5. WAF Customizado (ModSecurity)

**Quando usar:** Aplicações web críticas.

**Recursos:**
- [ModSecurity NGINX](https://github.com/SpiderLabs/ModSecurity-nginx)
- [OWASP Core Rule Set](https://coreruleset.org/)

**Checklist:**
- [ ] Instalar ModSecurity
- [ ] Configurar OWASP CRS
- [ ] Criar regras customizadas
- [ ] Testar com ferramenta de pentest

---

#### 6. Autenticação com Hardware Key (YubiKey)

**Quando usar:** Máxima segurança.

**Recursos:**
- [Cloudflare Access + WebAuthn](https://developers.cloudflare.com/cloudflare-one/identity/devices/webauthn/)
- [YubiKey SSH](https://developers.yubico.com/SSH/)

**Checklist:**
- [ ] Comprar YubiKey
- [ ] Configurar WebAuthn no Cloudflare Access
- [ ] Configurar SSH para exigir YubiKey
- [ ] Testar autenticação

---

#### 7. CDN para Assets Estáticos

**Quando usar:** Sites com muitas imagens/vídeos.

**Recursos:**
- [Cloudflare R2](https://www.cloudflare.com/products/r2/)
- [Automatic Platform Optimization](https://developers.cloudflare.com/automatic-platform-optimization/)

**Checklist:**
- [ ] Criar bucket R2
- [ ] Configurar CORS
- [ ] Migrar assets para R2
- [ ] Configurar cache rules

---

#### 8. Disaster Recovery Plan

**Quando usar:** Produção crítica.

**Checklist:**
- [ ] Documentar arquitetura completa
- [ ] Criar scripts de restore automático
- [ ] Testar failover para VPS secundária
- [ ] Configurar DNS secundário
- [ ] Treinar restore mensalmente

---

### 📚 Recursos Adicionais

#### Documentação Oficial

- [Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/)
- [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [WARP Client](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/)
- [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/policies/access/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [UFW Guide](https://help.ubuntu.com/community/UFW)

#### Comunidade

- [Cloudflare Community](https://community.cloudflare.com/)
- [r/selfhosted](https://reddit.com/r/selfhosted)
- [r/homelab](https://reddit.com/r/homelab)

---

## 🎉 Conclusão

Você construiu uma **infraestrutura de nível empresarial** com:

✅ **Segurança Zero Trust** - Nenhum serviço exposto desnecessariamente
✅ **Acesso Global** - De qualquer lugar com WARP
✅ **Terminal Web** - SSH sem cliente
✅ **Proteção DDoS** - Via Cloudflare
✅ **Firewall Inteligente** - Docker + UFW integrados
✅ **Autenticação Centralizada** - Cloudflare Access
✅ **Monitoramento** - Logs e métricas

**🔐 Sua infraestrutura agora está mais segura que 90% das empresas!**

---

## 📝 Manutenção Recomendada

### Semanal

- Verificar status dos túneis (5 min)
- Revisar logs de bloqueios do firewall (10 min)

### Mensal

- Atualizar cloudflared (`sudo cloudflared update`)
- Revisar dashboards Netdata
- Testar restore de backup
- Atualizar sistema (`sudo apt update && sudo apt upgrade`)

### Trimestral

- Auditar políticas de acesso (remover usuários inativos)
- Revisar senhas e chaves SSH
- Testar disaster recovery completo
- Executar scan de segurança (Lynis, nmap)

---

**📅 Última atualização:** 2025-01-19
**📧 Suporte:** Abra issue no repositório ou consulte a documentação oficial Cloudflare

**🙏 Contribuições são bem-vindas!**
