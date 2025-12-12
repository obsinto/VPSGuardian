# 🔐 Métodos de Autenticação SSH - Migração de Volumes

## 📋 Resumo

O script `migrar-volumes.sh` agora suporta **DOIS** métodos de autenticação SSH:

1. **🔑 Chave SSH (RECOMENDADO)**
2. **🔒 Senha SSH**

---

## 🎯 Quando Usar Cada Método

### ✅ Chave SSH (Opção 1) - RECOMENDADO

**Use quando:**
- Você tem acesso a chave SSH privada
- Quer máxima segurança
- Está fazendo migração automatizada
- Não quer digitar senha múltiplas vezes

**Vantagens:**
- ✅ Mais seguro (criptografia de chave pública)
- ✅ Sem prompts interativos
- ✅ Conexão persistente (mais rápida)
- ✅ Best practice da indústria

**Requisitos:**
```bash
# Ter uma chave SSH privada
~/.ssh/id_rsa  # ou outra chave

# Chave pública deve estar no servidor de destino
~/.ssh/authorized_keys (no servidor remoto)
```

---

### ⚠️ Senha SSH (Opção 2)

**Use quando:**
- Não tem chave SSH configurada
- É uma migração rápida/pontual
- Servidor permite autenticação por senha

**Desvantagens:**
- ⚠️ Menos seguro que chave SSH
- ⚠️ Pode solicitar senha múltiplas vezes durante migração longa
- ⚠️ Não é ideal para automação

**Requisitos:**
```bash
# Pacote sshpass deve estar instalado
sudo apt-get install -y sshpass  # Ubuntu/Debian
sudo yum install -y sshpass      # CentOS/RHEL
```

O script **instala automaticamente** se não estiver presente.

---

## 🚀 Como Funciona

### Durante a Execução

```
1. Você escolhe o servidor de destino
2. Script pergunta qual método de autenticação:

   [1] SSH Key (RECOMMENDED) ✅
   [2] Password ⚠️

3. Baseado na escolha:

   OPÇÃO 1 (Key):
   - Solicita caminho da chave privada
   - Estabelece conexão persistente
   - Nenhum prompt adicional durante migração

   OPÇÃO 2 (Password):
   - Solicita senha uma vez
   - Usa senha para todos os comandos SSH/SCP
   - Pode ter pequenos delays extras
```

---

## 📝 Exemplos de Uso

### Exemplo 1: Usando Chave SSH (Padrão)

```bash
./migrar-volumes.sh

# Durante execução:
Select method [1/2] (default: 1): 1  # ou apenas ENTER
# ou
Select method [1/2] (default: 1): [ENTER]

# Se chave não estiver em /root/.ssh/id_rsa:
Enter path to SSH private key: /home/user/.ssh/my_key
```

---

### Exemplo 2: Usando Senha

```bash
./migrar-volumes.sh

# Durante execução:
Select method [1/2] (default: 1): 2

# Se sshpass não estiver instalado:
Install sshpass now? (yes/no): yes

# Digita senha (oculta):
Enter SSH password for root@1.2.3.4: ********
```

---

## 🔧 Requisitos do Servidor Remoto

### Para Chave SSH:

```bash
# No servidor REMOTO, a chave pública deve estar em:
~/.ssh/authorized_keys

# Como adicionar:
ssh-copy-id -i ~/.ssh/id_rsa.pub root@SERVIDOR_REMOTO
```

### Para Senha SSH:

```bash
# No servidor REMOTO, editar /etc/ssh/sshd_config:
PasswordAuthentication yes

# Reiniciar SSH:
sudo systemctl restart sshd
```

---

## ⚡ Diferenças Técnicas

| Aspecto | Chave SSH | Senha SSH |
|---------|-----------|-----------|
| **Segurança** | 🟢 Alta (RSA 2048+) | 🟡 Média (depende da senha) |
| **Velocidade** | 🟢 Rápida (1 conexão persistente) | 🟡 Normal (reconecta cada comando) |
| **Automação** | 🟢 Ideal | 🔴 Não recomendado |
| **Setup** | 🟡 Requer config inicial | 🟢 Pronto se permitido |
| **Prompts** | 🟢 Zero | 🟡 Possíveis em caso de timeout |

---

## 🛡️ Recomendações de Segurança

### 🔐 Sempre prefira Chave SSH quando possível

1. **Gere uma chave forte:**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "migracao-vps"
   ```

2. **Copie para servidor de destino:**
   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa.pub root@SERVIDOR_DESTINO
   ```

3. **Teste a conexão:**
   ```bash
   ssh -i ~/.ssh/id_rsa root@SERVIDOR_DESTINO
   ```

### ⚠️ Se usar Senha SSH:

1. **Use senha forte** (16+ caracteres, mix de tipos)
2. **Desabilite senha depois da migração:**
   ```bash
   # No servidor REMOTO:
   sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

---

## 🐛 Troubleshooting

### Problema: "SSH key not found"

**Solução:**
```bash
# Verificar se chave existe:
ls -la ~/.ssh/

# Se não existe, gerar:
ssh-keygen -t rsa -b 4096

# Copiar para servidor:
ssh-copy-id root@SERVIDOR_DESTINO
```

---

### Problema: "sshpass is not installed"

**Solução:**
```bash
# O script oferece instalar automaticamente
# Ou instale manualmente:
sudo apt-get install -y sshpass  # Ubuntu/Debian
sudo yum install -y sshpass      # CentOS/RHEL
```

---

### Problema: "SSH connection failed" com senha

**Solução:**
```bash
# 1. Verificar se servidor permite senha:
ssh -o PreferredAuthentications=password root@SERVIDOR_DESTINO

# 2. Se falhar, habilitar no servidor:
# No SERVIDOR_REMOTO editar /etc/ssh/sshd_config:
PasswordAuthentication yes

# Reiniciar:
sudo systemctl restart sshd
```

---

### Problema: "Permission denied" com chave

**Solução:**
```bash
# 1. Verificar permissões da chave:
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 2. Verificar se chave pública está no servidor:
ssh root@SERVIDOR_DESTINO "cat ~/.ssh/authorized_keys | grep 'sua-chave'"

# 3. Re-adicionar se necessário:
ssh-copy-id -i ~/.ssh/id_rsa.pub root@SERVIDOR_DESTINO
```

---

## 📊 Comparação de Performance

### Migração de 5 volumes (total: 2GB)

| Método | Tempo | Prompts |
|--------|-------|---------|
| **Chave SSH** | ~8 minutos | 0 |
| **Senha SSH** | ~9-10 minutos | 0-2 (se timeout) |

**Diferença:** Chave SSH usa conexão persistente, evitando handshakes SSH repetidos.

---

## ✅ Checklist Rápido

### Antes da Migração:

**Opção 1: Chave SSH**
- [ ] Chave SSH privada existe
- [ ] Chave pública no servidor de destino
- [ ] Conexão SSH funciona sem senha

**Opção 2: Senha SSH**
- [ ] Servidor permite PasswordAuthentication
- [ ] sshpass instalado (ou aceitar instalação automática)
- [ ] Senha do servidor em mãos

---

## 🎯 Quick Start

```bash
# 1. Executar script:
cd /home/deyvid/Repositories/manutencao_backup_vps/migrar
./migrar-volumes.sh

# 2. Seguir prompts interativos
# 3. Escolher método de autenticação [1 ou 2]
# 4. Fornecer credenciais (chave ou senha)
# 5. Aguardar migração
```

---

## 📞 Suporte

Em caso de problemas:

1. **Consultar logs:**
   ```bash
   cat ./volume-migration-logs/volume-migration-TIMESTAMP.log
   ```

2. **Validar conectividade SSH:**
   ```bash
   # Com chave:
   ssh -i ~/.ssh/id_rsa root@SERVIDOR_DESTINO

   # Com senha:
   ssh root@SERVIDOR_DESTINO
   ```

3. **Reportar issue:**
   - GitHub: https://github.com/USER/REPO/issues
