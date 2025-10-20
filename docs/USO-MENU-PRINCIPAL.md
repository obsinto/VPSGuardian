# 🚀 Menu Principal - Central de Gerenciamento VPS

## 📋 Visão Geral

O **Menu Principal** é uma interface interativa e centralizada que facilita o acesso a **todos os scripts** do repositório. Ele organiza as ferramentas em categorias lógicas, oferece confirmações para operações críticas e registra todas as execuções em logs.

### 🎯 Objetivo

Substituir a execução manual de scripts por uma interface amigável que:
- ✅ Agrupa scripts por função (backup, manutenção, status, etc)
- ✅ Exibe descrições claras de cada operação
- ✅ Pede confirmação em operações críticas
- ✅ Registra todas as execuções em log
- ✅ Apresenta output colorido e organizado
- ✅ Facilita navegação entre diferentes ferramentas

---

## 🚀 Como Usar

### Execução Básica

```bash
# Navegar até o diretório
cd ~/manutencao_backup_vps

# Executar o menu (recomenda-se usar sudo)
sudo ./menu-principal.sh
```

### Criar Alias Global (Recomendado)

Para acessar de qualquer lugar com um único comando:

```bash
# Adicionar ao ~/.bashrc
echo "alias vps='sudo ~/manutencao_backup_vps/menu-principal.sh'" >> ~/.bashrc

# Recarregar configuração
source ~/.bashrc

# Agora pode executar de qualquer lugar:
vps
```

Ou criar um alias ainda mais intuitivo:

```bash
# Alias alternativos
echo "alias menu='sudo ~/manutencao_backup_vps/menu-principal.sh'" >> ~/.bashrc
echo "alias gerenciar='sudo ~/manutencao_backup_vps/menu-principal.sh'" >> ~/.bashrc
```

### Executar Remotamente via SSH

```bash
# Executar menu diretamente ao conectar
ssh root@seu-servidor "cd manutencao_backup_vps && ./menu-principal.sh"
```

---

## 📚 Estrutura do Menu

### 🏠 Menu Principal

```
╔══════════════════════════════════════════════════════════════════╗
║        🚀 MENU PRINCIPAL - GERENCIAMENTO VPS 🚀                 ║
╚══════════════════════════════════════════════════════════════════╝

MENU PRINCIPAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 → 📊 Status e Diagnóstico
  2 → 💾 Backups
  3 → 🔧 Manutenção
  4 → 🚚 Migração
  5 → ⚙️  Configuração
  6 → 📚 Documentação
  7 → 📜 Ver Logs de Execução
  0 → 🚪 Sair
```

---

### 1️⃣ Status e Diagnóstico

**Objetivo:** Verificar a saúde e status do servidor.

```
📊 STATUS E DIAGNÓSTICO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 → 🏥 Verificação de Saúde Completa
       (17 seções, score 0-100, recomendações)

  2 → 📋 Status Resumido
       (Visão rápida: disco, memória, Docker, Coolify)

  3 → 🧪 Teste do Sistema
       (Verificar funcionalidades básicas)
```

#### Scripts Executados

| Opção | Script | Descrição |
|-------|--------|-----------|
| **1** | `verificar-saude-completa.sh` | Análise completa com 17 seções e score |
| **2** | `status-completo.sh` | Visão rápida de recursos e serviços |
| **3** | `test-sistema.sh` | Testes de funcionalidade básica |

---

### 2️⃣ Backups

**Objetivo:** Criar e restaurar backups de forma interativa.

```
💾 BACKUPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CRIAR BACKUPS
  1 → 📦 Backup Completo do Coolify
  2 → 🗄️  Backup de Bancos de Dados
  3 → 📁 Backup de Volume Específico (Interativo)
  4 → 📤 Enviar Backups para Destinos Remotos

  RESTAURAR BACKUPS
  5 → 📥 Restaurar Coolify de Backup Remoto
  6 → 🔄 Restaurar Volume Específico (Interativo)
```

#### Scripts Executados

| Opção | Script | Confirmação? |
|-------|--------|--------------|
| **1** | `backup-coolify.sh` | ✅ Sim |
| **2** | `backup-databases.sh` | ✅ Sim |
| **3** | `backup-volume-interativo.sh` | ❌ Não (já é interativo) |
| **4** | `backup-destinos.sh` | ✅ Sim |
| **5** | `restaurar-coolify-remoto.sh` | ✅ Sim (crítico!) |
| **6** | `restaurar-volume-interativo.sh` | ❌ Não (já é interativo) |

**🔐 Segurança:** Operações de restauração pedem confirmação adicional.

---

### 3️⃣ Manutenção

**Objetivo:** Executar tarefas de manutenção do servidor.

```
🔧 MANUTENÇÃO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 → 🔄 Manutenção Completa
  2 → ⚠️  Verificar Alerta de Disco
  3 → 🆙 Configurar Updates Automáticos
  4 → 🧹 Limpeza Manual do Docker
  5 → 🔄 Reiniciar Serviços Essenciais
```

#### Scripts Executados

| Opção | Script/Comando | Confirmação? |
|-------|----------------|--------------|
| **1** | `manutencao-completa.sh` | ✅ Sim |
| **2** | `alerta-disco.sh` | ❌ Não |
| **3** | `configurar-updates-automaticos.sh` | ✅ Sim |
| **4** | `docker system prune -a --volumes` | ✅ Sim |
| **5** | `systemctl restart docker/cloudflared/ufw` | ✅ Sim |

**💡 Dica:** Opção 4 (Limpeza Docker) é útil quando o disco está cheio.

---

### 4️⃣ Migração

**Objetivo:** Migrar dados e serviços entre servidores.

```
🚚 MIGRAÇÃO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⚠️  ATENÇÃO: Operações de migração são CRÍTICAS!
  Certifique-se de ter backups antes de prosseguir.

  1 → 🚀 Migrar Coolify Completo
  2 → 📦 Migrar Volumes Docker
  3 → 📤 Transferir Backups Entre Servidores
```

#### Scripts Executados

| Opção | Script | Confirmação? |
|-------|--------|--------------|
| **1** | `migrar-coolify.sh` | ✅ Sim (muito crítico!) |
| **2** | `migrar-volumes.sh` | ✅ Sim (crítico!) |
| **3** | `transferir-backups.sh` | ❌ Não |

**🚨 ATENÇÃO:** Sempre faça backups antes de migrar!

---

### 5️⃣ Configuração

**Objetivo:** Configurar serviços e parâmetros do sistema.

```
⚙️  CONFIGURAÇÃO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1 → ⏰ Configurar Tarefas Agendadas (Cron)
  2 → 📝 Editar Configurações (config.env)
  3 → 🛡️  Configurar Firewall (UFW)
  4 → 🔐 Configurar Cloudflare Tunnel
  5 → 📋 Mostrar Configurações Atuais
```

#### Funcionalidades

| Opção | Ação |
|-------|------|
| **1** | Executa `configurar-cron.sh` |
| **2** | Abre `config.env` no nano |
| **3** | Exibe status do UFW + link para guia |
| **4** | Exibe status do cloudflared + link para guia |
| **5** | Mostra cron jobs, portas abertas e config.env |

---

### 6️⃣ Documentação

**Objetivo:** Acessar guias e documentação.

```
📚 DOCUMENTAÇÃO DISPONÍVEL
═══════════════════════════════════════════════════════════════
Guias disponíveis no diretório 'docs/':

  → GUIA-COMPLETO-INFRAESTRUTURA-SEGURA.md
  → USO-SCRIPT-VERIFICACAO-SAUDE.md
  → USO-MENU-PRINCIPAL.md

Outros arquivos de documentação:
  → README.md
  → GUIA.md
```

**Lista todos os arquivos de documentação** disponíveis no repositório.

---

### 7️⃣ Ver Logs de Execução

**Objetivo:** Auditar execuções anteriores.

```
📜 LOGS DE EXECUÇÃO
═══════════════════════════════════════════════════════════════
Últimas 30 execuções:

[2025-01-19 14:30:22] INÍCIO: Verificação de Saúde Completa
[2025-01-19 14:31:05] SUCESSO: Verificação de Saúde Completa
[2025-01-19 14:32:10] INÍCIO: Backup Completo do Coolify
[2025-01-19 14:35:42] SUCESSO: Backup Completo do Coolify
[2025-01-19 14:40:01] INÍCIO: Manutenção Completa
[2025-01-19 14:40:15] ERRO: Manutenção Completa (código: 1)
```

**🎨 Cores:**
- 🟢 Verde: Sucessos
- 🔴 Vermelho: Erros
- ⚪ Cinza: Informações gerais

**📍 Localização do log:** `/var/log/manutencao/menu-execucoes.log`

---

## 🎨 Recursos Visuais

### Cores e Símbolos

O menu usa cores para facilitar a compreensão:

| Cor | Uso |
|-----|-----|
| 🔵 **Azul/Ciano** | Cabeçalhos e separadores |
| 🟢 **Verde** | Opções de menu, sucessos |
| 🟡 **Amarelo** | Avisos e confirmações |
| 🔴 **Vermelho** | Erros e opção "Sair" |
| ⚪ **Branco** | Títulos e destaques |
| ⚫ **Cinza** | Descrições e informações secundárias |

### Confirmações Inteligentes

Operações críticas pedem confirmação:

```
Executar backup completo do Coolify?
Confirmar? [s/N]:
```

- **s** ou **sim** = Confirma
- Qualquer outra tecla = Cancela

---

## 📝 Sistema de Logs

### Registro Automático

**Todas as execuções** via menu são registradas automaticamente:

```bash
# Ver logs completos
cat /var/log/manutencao/menu-execucoes.log

# Ver apenas sucessos
grep SUCESSO /var/log/manutencao/menu-execucoes.log

# Ver apenas erros
grep ERRO /var/log/manutencao/menu-execucoes.log

# Ver logs de hoje
grep "$(date +%Y-%m-%d)" /var/log/manutencao/menu-execucoes.log
```

### Formato dos Logs

```
[YYYY-MM-DD HH:MM:SS] EVENTO: Nome do Script
```

**Eventos registrados:**
- `INÍCIO` - Script começou a executar
- `SUCESSO` - Script finalizou sem erros
- `ERRO` - Script finalizou com código de erro
- `Menu Principal encerrado` - Usuário saiu do menu

---

## 🔧 Personalização

### Adicionar Novo Script ao Menu

1. **Criar o script** em uma das pastas existentes
2. **Editar menu-principal.sh:**

```bash
nano ~/manutencao_backup_vps/menu-principal.sh
```

3. **Adicionar opção no menu** apropriado:

```bash
# Exemplo: Adicionar em show_backup_menu()
echo -e "  ${GREEN}7${NC} → 🆕 Meu Novo Backup"
echo -e "       ${GRAY}(Descrição do que faz)${NC}"
```

4. **Adicionar case no handle correspondente:**

```bash
# Em handle_backup_menu()
case $option in
    ...
    7)
        run_script "$SCRIPT_DIR/backup/meu-novo-script.sh" "Meu Novo Backup"
        ;;
    ...
esac
```

### Criar Nova Categoria

Se precisar de uma categoria totalmente nova:

1. **Criar função do menu:**

```bash
show_minha_categoria_menu() {
    print_header
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}🆕 MINHA CATEGORIA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC} → 📌 Minha Operação"
    echo -e "  ${RED}0${NC} → ↩️  Voltar ao Menu Principal"
    echo -ne "${WHITE}Escolha uma opção: ${NC}"
}
```

2. **Criar handler:**

```bash
handle_minha_categoria_menu() {
    while true; do
        show_minha_categoria_menu
        read -r option
        case $option in
            1) run_script "caminho/script.sh" "Nome Script" ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
        esac
    done
}
```

3. **Adicionar ao menu principal:**

```bash
# Em show_main_menu()
echo -e "  ${GREEN}8${NC} → 🆕 Minha Categoria"

# Em main() function
case $option in
    ...
    8) handle_minha_categoria_menu ;;
    ...
esac
```

---

## 🔍 Troubleshooting

### Problema: "Permission denied"

**Solução:**

```bash
# Tornar executável
chmod +x ~/manutencao_backup_vps/menu-principal.sh

# Executar com sudo
sudo ./menu-principal.sh
```

### Problema: Script não é encontrado

**Causa:** Caminho do script está incorreto.

**Solução:**

```bash
# Verificar estrutura de pastas
tree ~/manutencao_backup_vps

# Ajustar caminho no menu-principal.sh
# Variável $SCRIPT_DIR contém o caminho base
```

### Problema: Cores não aparecem

**Causa:** Terminal não suporta cores ANSI.

**Solução:**

```bash
# Verificar suporte a cores
echo $TERM

# Forçar terminal com cores
export TERM=xterm-256color
```

### Problema: Menu trava após executar script

**Causa:** Script filho não finalizou corretamente.

**Solução:**

```bash
# Verificar se script tem exit no final
# Adicionar ao final do script problemático:
exit 0
```

---

## 💡 Dicas de Uso

### 1. Rotina Diária

```bash
# Abrir menu
vps

# Opção 1 (Status) → Opção 1 (Saúde Completa)
# Ver score e recomendações

# Se score < 90, executar:
# Opção 3 (Manutenção) → Opção 1 (Manutenção Completa)
```

### 2. Antes de Update do Sistema

```bash
vps

# Criar backup preventivo
# Opção 2 (Backups) → Opção 1 (Backup Completo)

# Aguardar conclusão, depois fazer update via SSH normal
```

### 3. Investigar Problemas

```bash
vps

# 1. Ver saúde geral
# Opção 1 → Opção 1

# 2. Verificar logs
# Opção 7 (Ver Logs)

# 3. Se necessário, limpar Docker
# Opção 3 → Opção 4
```

### 4. Configuração Inicial

```bash
vps

# 1. Configurar cron jobs
# Opção 5 → Opção 1

# 2. Verificar configurações
# Opção 5 → Opção 5

# 3. Consultar documentação
# Opção 6
```

---

## 📊 Estatísticas de Uso

### Ver Scripts Mais Executados

```bash
# Contar execuções por script
grep "INÍCIO:" /var/log/manutencao/menu-execucoes.log | \
    cut -d':' -f3 | sort | uniq -c | sort -rn
```

### Taxa de Sucesso

```bash
# Total de execuções
TOTAL=$(grep -c "INÍCIO:" /var/log/manutencao/menu-execucoes.log)

# Sucessos
SUCESSOS=$(grep -c "SUCESSO:" /var/log/manutencao/menu-execucoes.log)

# Taxa
echo "Taxa de sucesso: $((SUCESSOS * 100 / TOTAL))%"
```

### Horários de Uso

```bash
# Scripts executados por hora
grep "INÍCIO:" /var/log/manutencao/menu-execucoes.log | \
    cut -d' ' -f2 | cut -d':' -f1 | sort | uniq -c
```

---

## 🚀 Integração com Outros Sistemas

### Executar Remotamente via SSH

```bash
# Executar opção específica automaticamente
ssh root@vps "cd manutencao_backup_vps && echo '1' | ./menu-principal.sh"
```

### Criar Wrapper para Ansible

```yaml
# playbook.yml
- name: Executar verificação de saúde
  hosts: vps
  tasks:
    - name: Rodar menu principal
      shell: cd /root/manutencao_backup_vps && ./menu-principal.sh
      args:
        stdin: "1\n1\n0\n0\n"  # Navegar até verificação de saúde
```

### Integrar com Cronjob

```bash
# Executar verificação automática toda segunda às 9h
0 9 * * 1 cd /root/manutencao_backup_vps && echo -e "1\n1\n0\n0\n" | ./menu-principal.sh >> /var/log/manutencao/cron-menu.log 2>&1
```

---

## 📚 Referências

### Arquivos Relacionados

- **Menu Principal:** `menu-principal.sh`
- **Logs:** `/var/log/manutencao/menu-execucoes.log`
- **Configuração:** `config/config.env`

### Documentação Complementar

- [Guia Completo de Infraestrutura Segura](GUIA-COMPLETO-INFRAESTRUTURA-SEGURA.md)
- [Uso do Script de Verificação de Saúde](USO-SCRIPT-VERIFICACAO-SAUDE.md)
- [README Principal](../README.md)

---

## 🎯 Fluxograma de Navegação

```
┌─────────────────────────────────────────┐
│       🏠 MENU PRINCIPAL                 │
└────────────────┬────────────────────────┘
                 │
      ┌──────────┼──────────┬──────────┬──────────┐
      ▼          ▼          ▼          ▼          ▼
┌──────────┐ ┌────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐
│ Status   │ │ Backup │ │Manutenção│ │Migração│ │  Config  │
└──────────┘ └────────┘ └──────────┘ └────────┘ └──────────┘
      │            │            │           │           │
      ▼            ▼            ▼           ▼           ▼
  3 opções     6 opções     5 opções   3 opções   5 opções
```

---

## ✅ Checklist de Primeiro Uso

Ao usar o menu pela primeira vez:

- [ ] Executar como root/sudo
- [ ] Testar cada categoria de menu
- [ ] Verificar se todos os scripts são encontrados
- [ ] Criar alias global (`vps`)
- [ ] Executar verificação de saúde (Opção 1 → 1)
- [ ] Configurar cron jobs (Opção 5 → 1)
- [ ] Verificar logs (Opção 7)
- [ ] Ler documentação disponível (Opção 6)

---

## 🎉 Benefícios do Menu Centralizado

| Antes (Scripts Manuais) | Depois (Menu) |
|-------------------------|---------------|
| Lembrar nomes de scripts | Navegação visual |
| Digitar caminhos completos | Seleção por número |
| Sem confirmação em operações críticas | Confirmações automáticas |
| Sem logs de execução | Logs automáticos |
| Documentação dispersa | Acesso centralizado |
| Erros sem contexto | Output formatado e colorido |

---

**🚀 Gerencie seu servidor VPS com facilidade e segurança!**

**Versão:** 1.0
**Última atualização:** 2025-01-19
