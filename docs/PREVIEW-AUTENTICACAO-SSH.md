# Preview: Interface de Autenticação SSH

## 🎨 Nova Interface (PT-BR e Melhorada)

```
═══════════════════════════════════════════════════════════════
  MÉTODO DE AUTENTICAÇÃO SSH
═══════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════╗
║  Escolha o método de autenticação SSH para o servidor      ║
╚═══════════════════════════════════════════════════════════════╝

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Chave SSH (RECOMENDADO) 🔑
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      ✅ Máxima segurança (criptografia assimétrica)
      ✅ Sem solicitação de senha durante a migração
      ✅ Padrão da indústria e melhores práticas DevOps
      ✅ Permite automação segura de processos
      ✅ Auditável e rastreável

      📋 Pré-requisito: Chave SSH configurada em ~/.ssh/id_rsa
                       ou será solicitado o caminho alternativo

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [2] Senha (Autenticação por Senha) 🔓
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      ⚠️  Menor segurança (senha trafega pela rede)
      ⚠️  Pode solicitar senha múltiplas vezes
      ⚠️  Não recomendado para ambientes de produção
      ⚠️  Dificulta automação de processos
      ⚠️  Vulnerável a ataques de força bruta

      📋 Pré-requisito: Servidor deve permitir autenticação por senha
                       (PasswordAuthentication yes no sshd_config)

═══════════════════════════════════════════════════════════════

[ Volume Migration Agent ] [ INPUT ] Selecione o método [1/2] (padrão: 1):
```

---

## 📋 Fluxos de Interação

### Fluxo 1: Selecionando Chave SSH (Opção 1)

```
[ Volume Migration Agent ] [ INPUT ] Selecione o método [1/2] (padrão: 1): 1

[ Volume Migration Agent ] [ ✓ ] Método de autenticação: Chave SSH 🔑
[ Volume Migration Agent ] [ INFO ] Configurando conexão SSH com o servidor de destino...
[ Volume Migration Agent ] [ INFO ] Iniciando ssh-agent...
[ Volume Migration Agent ] [ ✓ ] Chave SSH adicionada ao agente.
[ Volume Migration Agent ] [ INFO ] Testando conexão SSH...
[ Volume Migration Agent ] [ ✓ ] Conexão SSH estabelecida com sucesso.
[ Volume Migration Agent ] [ INFO ] Estabelecendo conexão SSH persistente...
[ Volume Migration Agent ] [ ✓ ] Conexão SSH persistente estabelecida.
```

### Fluxo 2: Selecionando Senha (Opção 2)

```
[ Volume Migration Agent ] [ INPUT ] Selecione o método [1/2] (padrão: 1): 2

[ Volume Migration Agent ] [ ⚠ ] Método de autenticação: Senha 🔓
[ Volume Migration Agent ] [ ⚠ ] ATENÇÃO: Este método é menos seguro. Considere usar chave SSH.

═══════════════════════════════════════════════════════════════
  CONFIGURAÇÃO DE SENHA SSH
═══════════════════════════════════════════════════════════════

  Servidor: root@192.168.1.100
  Porta:    22

  Digite a senha SSH: ••••••••

[ Volume Migration Agent ] [ ✓ ] Senha configurada com sucesso.
[ Volume Migration Agent ] [ INFO ] Configurando conexão SSH com o servidor de destino...
[ Volume Migration Agent ] [ INFO ] Testando conexão SSH com senha...
[ Volume Migration Agent ] [ ✓ ] Conexão SSH estabelecida com sucesso.
[ Volume Migration Agent ] [ INFO ] Usando autenticação por senha para cada comando SSH.
```

### Fluxo 3: Senha - sshpass não instalado

```
[ Volume Migration Agent ] [ INPUT ] Selecione o método [1/2] (padrão: 1): 2

[ Volume Migration Agent ] [ ⚠ ] Método de autenticação: Senha 🔓
[ Volume Migration Agent ] [ ⚠ ] ATENÇÃO: Este método é menos seguro. Considere usar chave SSH.

[ Volume Migration Agent ] [ ✗ ] O pacote 'sshpass' não está instalado.
[ Volume Migration Agent ] [ ✗ ] Autenticação por senha requer o sshpass.

═══════════════════════════════════════════════════════════════
  Para instalar o sshpass:

    Ubuntu/Debian:  sudo apt-get install -y sshpass
    CentOS/RHEL:    sudo yum install -y sshpass
    Alpine:         apk add sshpass
═══════════════════════════════════════════════════════════════

  Deseja instalar o sshpass agora? (yes/no): yes

[ Volume Migration Agent ] [ INFO ] Instalando sshpass...
[ Volume Migration Agent ] [ ✓ ] sshpass instalado com sucesso.

═══════════════════════════════════════════════════════════════
  CONFIGURAÇÃO DE SENHA SSH
═══════════════════════════════════════════════════════════════

  Servidor: root@192.168.1.100
  Porta:    22

  Digite a senha SSH: ••••••••

[ Volume Migration Agent ] [ ✓ ] Senha configurada com sucesso.
```

### Fluxo 4: Senha - Conexão falhou

```
[ Volume Migration Agent ] [ INFO ] Testando conexão SSH com senha...
[ Volume Migration Agent ] [ ✗ ] Falha na conexão SSH. Verifique:

  ❌ IP/hostname do servidor está correto?
  ❌ Usuário e senha estão corretos?
  ❌ Porta SSH está correta?
  ❌ Servidor permite autenticação por senha?

  💡 Dica: Para habilitar autenticação por senha no servidor:
     1. Edite /etc/ssh/sshd_config
     2. Defina: PasswordAuthentication yes
     3. Reinicie: systemctl restart sshd
```

### Fluxo 5: Chave SSH - Caminho alternativo

```
[ Volume Migration Agent ] [ INPUT ] Selecione o método [1/2] (padrão: 1): 1

[ Volume Migration Agent ] [ ✓ ] Método de autenticação: Chave SSH 🔑
[ Volume Migration Agent ] [ INFO ] Configurando conexão SSH com o servidor de destino...
[ Volume Migration Agent ] [ ⚠ ] Chave SSH não encontrada em: /root/.ssh/id_rsa

[ Volume Migration Agent ] [ INPUT ] Digite o caminho da chave SSH privada: /root/.ssh/vps_key

[ Volume Migration Agent ] [ INFO ] Iniciando ssh-agent...
[ Volume Migration Agent ] [ ✓ ] Chave SSH adicionada ao agente.
[ Volume Migration Agent ] [ INFO ] Testando conexão SSH...
[ Volume Migration Agent ] [ ✓ ] Conexão SSH estabelecida com sucesso.
```

---

## ✨ Melhorias Implementadas

### 1. **Tradução Completa para PT-BR**
- Todas as mensagens traduzidas
- Terminologia técnica em português
- Mantém emojis para melhor visualização

### 2. **Interface Mais Clara e Informativa**
- Box decorativo separando as opções
- Linhas separadoras coloridas (verde para recomendado, amarelo para aviso)
- Emojis contextuais (🔑 para chave, 🔓 para senha)
- Mais informações sobre cada opção

### 3. **Mensagens de Erro Melhoradas**
- Lista de verificação com ❌ para facilitar debug
- Dicas práticas para resolver problemas
- Passos claros para habilitar autenticação por senha
- Suporte para Alpine Linux (além de Ubuntu/CentOS)

### 4. **Pré-requisitos Visíveis**
- Mostra claramente o que é necessário para cada método
- Explica onde a chave deve estar ou como fornecer caminho alternativo
- Informa sobre configuração necessária no servidor

### 5. **Atenção à Segurança**
- Avisos explícitos sobre riscos da autenticação por senha
- Recomendação clara de usar chave SSH
- Informações sobre por que chave SSH é mais segura

### 6. **Melhor Feedback Visual**
- Seção de configuração de senha destacada
- Mostra servidor/porta antes de solicitar senha
- Mensagens coloridas de sucesso/aviso/erro

---

## 🎯 Comparação: Antes vs Depois

### Antes (Inglês)
```
Choose SSH authentication method:

  [1] SSH Key (RECOMMENDED)
      ✅ More secure
      ✅ No password prompts during migration
      ✅ Industry best practice

  [2] Password
      ⚠️  Less secure
      ⚠️  May prompt for password multiple times
      ⚠️  Not recommended for automation
```

### Depois (PT-BR + Melhorias)
```
╔═══════════════════════════════════════════════════════════════╗
║  Escolha o método de autenticação SSH para o servidor      ║
╚═══════════════════════════════════════════════════════════════╝

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [1] Chave SSH (RECOMENDADO) 🔑
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      ✅ Máxima segurança (criptografia assimétrica)
      ✅ Sem solicitação de senha durante a migração
      ✅ Padrão da indústria e melhores práticas DevOps
      ✅ Permite automação segura de processos
      ✅ Auditável e rastreável

      📋 Pré-requisito: Chave SSH configurada em ~/.ssh/id_rsa
                       ou será solicitado o caminho alternativo
```

---

## 📝 Arquivos Modificados

- `migrar/migrar-volumes.sh` - Interface de autenticação SSH melhorada e traduzida
- `docs/PREVIEW-AUTENTICACAO-SSH.md` - Esta documentação (NOVO)

---

**Desenvolvido com** ❤️ **por VPS Guardian**
**Generated with** 🤖 **[Claude Code](https://claude.com/claude-code)**
