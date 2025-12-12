# Sistema de Lotes de Backup (Batch Management)

## 🎯 Problema Resolvido

Antes desta implementação, o sistema tinha os seguintes problemas:

1. **Confusão com Backups Antigos**: Quando existiam backups de múltiplas execuções, o sistema contava TODOS os arquivos de backup como se fossem da mesma "família", resultando em:
   - Contagem incorreta (ex: 44 backups encontrados quando esperava 22)
   - Impossibilidade de distinguir backups de diferentes datas/horários
   - Validação falhando por incompatibilidade de contagem

2. **Parsing de Seleção Inadequado**: O sistema não aceitava:
   - Vírgulas como separador (ex: `0,1,2,3`)
   - Intervalos (ex: `0-5`)
   - Formato misto (ex: `0-3,5,7-9`)
   - Resultado: erro "integer expression expected"

## ✅ Solução Implementada

### 1. Sistema de Batch ID

Cada execução de backup agora recebe um **identificador único** (Batch ID) baseado no timestamp:

```bash
BATCH_ID=20251212_102131  # Formato: YYYYMMDD_HHMMSS
```

**Mudanças em `backup-volumes.sh`:**

- ✅ Batch ID único por execução
- ✅ Arquivo de metadata criado (`.batch-YYYYMMDD_HHMMSS.meta`)
- ✅ Backups nomeados com Batch ID: `volume-name-backup-20251212_102131.tar.gz`
- ✅ Metadata inclui: data de criação, total de volumes, backups bem-sucedidos, hostname, versão do Docker

**Exemplo de arquivo `.batch-20251212_102131.meta`:**

```bash
BATCH_ID=20251212_102131
CREATED=2025-12-12 10:21:31
TOTAL_VOLUMES=22
SUCCESSFUL_BACKUPS=22
HOSTNAME=vps-origin
DOCKER_VERSION=Docker version 24.0.7, build afdd53b
```

### 2. Detecção e Listagem de Lotes

**Mudanças em `migrar-volumes.sh`:**

- ✅ Função `detect_backup_batches()`: detecta todos os lotes disponíveis
- ✅ Função `list_backup_batches()`: lista lotes de forma organizada
- ✅ Função `get_batch_backups()`: retorna apenas backups do lote selecionado
- ✅ Seleção automática se houver apenas 1 lote
- ✅ Permite escolher qual lote usar quando há múltiplos

**Exemplo de Saída:**

```
═══════════════════════════════════════════════════════════════
  BATCH SELECTION
═══════════════════════════════════════════════════════════════

Lotes de backup disponíveis:

  [0] Lote: 20251212_102131
      Criado em: 2025-12-12 10:21:31
      Volumes no lote: 22/22
      Backups encontrados: 22

  [1] Lote: 20251211_233412
      Criado em: 2025-12-11 23:34:12
      Volumes no lote: 22/22
      Backups encontrados: 22

Escolha o lote de backup:
  - Digite o número do lote [0-1]
  - Digite 'latest' para usar o mais recente (default)
```

### 3. Parsing Inteligente de Seleção

Nova função `normalize_selection()` que aceita múltiplos formatos:

**Formatos Aceitos:**

- Espaços: `0 1 2 3`
- Vírgulas: `0,1,2,3`
- Intervalos: `0-3` (expande para `0 1 2 3`)
- Misto: `0-3,5,7-9` (expande para `0 1 2 3 5 7 8 9`)
- Combinado: `0-2, 5-7, 10` (aceita espaços e vírgulas)

**Validação:**

- ✅ Remove caracteres inválidos
- ✅ Valida índices dentro do range
- ✅ Avisa sobre índices fora do range
- ✅ Mensagens de erro claras

**Exemplo de Interface:**

```
Select volumes to migrate:
  - Enter numbers: separated by spaces (e.g., 0 2 4)
  - Enter numbers: separated by commas (e.g., 0,2,4)
  - Enter ranges: using dash (e.g., 0-5 10-15)
  - Enter 'all' to migrate all volumes
  - Enter 'none' to cancel

  Examples:
    0 1 2 3         → volumes 0, 1, 2, 3
    0,1,2,3         → volumes 0, 1, 2, 3
    0-3             → volumes 0, 1, 2, 3
    0-3,5,7-9       → volumes 0, 1, 2, 3, 5, 7, 8, 9

Selection: 0-3,5,7-9
```

### 4. Validação Correta por Lote

Agora a validação compara apenas com os backups do lote selecionado:

**Antes:**
```
Docker volumes in origin: 22
Backup files created: 44  ← Contando todos os backups!
✗ Mismatch detected!
```

**Depois:**
```
Lote selecionado: 20251212_102131
Docker volumes in origin: 22
Backup files in selected batch: 22  ← Apenas do lote selecionado!
✓ Validation passed!
```

## 🧪 Testes

Foi criado um script de testes completo: `migrar/test-selection-parsing.sh`

**Execução:**
```bash
./migrar/test-selection-parsing.sh
```

**Resultados:**
```
✓ Input: '0,1,2,3' → Output: '0 1 2 3'
✓ Input: '0-3' → Output: '0 1 2 3'
✓ Input: '0-3,5,7-9' → Output: '0 1 2 3 5 7 8 9'
✓ Input: '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21' → Output: '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21'

🎉 Todos os testes passaram! (13/13)
```

## 📋 Fluxo de Uso

### Cenário 1: Primeiro Backup (Sem Lotes Anteriores)

```bash
./migrar/migrar-volumes.sh
```

1. Cria backup com Batch ID único
2. Detecta apenas 1 lote
3. Usa automaticamente o lote criado
4. Continua com a migração

### Cenário 2: Múltiplos Backups Existentes

```bash
./migrar/migrar-volumes.sh
```

1. Cria backup com novo Batch ID
2. Detecta múltiplos lotes disponíveis
3. Lista todos os lotes com informações
4. Permite escolher qual lote usar
5. Filtra backups apenas do lote escolhido
6. Valida contagem apenas do lote
7. Permite seleção flexível (vírgulas, intervalos, etc.)

### Cenário 3: Backups Legacy (Sem Metadata)

Se encontrar backups antigos sem arquivo `.batch-*.meta`:

1. Detecta ausência de metadata
2. Avisa o usuário
3. Oferece opção de continuar com TODOS os backups
4. Permite prosseguir em modo compatibilidade

## 🎉 Benefícios

1. **Organização**: Backups agrupados por lote/execução
2. **Rastreabilidade**: Sabe exatamente quando cada backup foi criado
3. **Validação Precisa**: Compara apenas backups do mesmo lote
4. **Usabilidade**: Múltiplos formatos de entrada aceitos
5. **Compatibilidade**: Funciona com backups antigos (modo legacy)
6. **Profissional**: Sistema robusto e testado
7. **Escalável**: Fácil adicionar novos metadados no futuro

## 🔧 Arquivos Modificados

- `migrar/backup-volumes.sh` - Sistema de Batch ID e metadata
- `migrar/migrar-volumes.sh` - Detecção, listagem e seleção de lotes
- `migrar/test-selection-parsing.sh` - Suite de testes (NOVO)
- `docs/SISTEMA-LOTES-BACKUP.md` - Esta documentação (NOVO)

## 📝 Notas Técnicas

### Formato do Batch ID

- **Padrão**: `YYYYMMDD_HHMMSS`
- **Exemplo**: `20251212_102131` = 12 de dezembro de 2025, 10:21:31
- **Ordenação**: Naturalmente ordenado por data/hora (mais recente primeiro com `ls -t`)

### Arquivo de Metadata

- **Localização**: `/root/volume-backups/.batch-YYYYMMDD_HHMMSS.meta`
- **Formato**: Shell script sourceable
- **Uso**: Carregado com `source` para ler variáveis

### Compatibilidade

- ✅ Backups novos: Incluem Batch ID no nome
- ✅ Backups antigos: Modo legacy detecta automaticamente
- ✅ Symlinks: `-latest.tar.gz` continuam funcionando
- ✅ Scripts existentes: Não quebram funcionalidade antiga

## 🚀 Próximos Passos (Opcional)

Melhorias futuras possíveis:

- [ ] Listar apenas lotes dos últimos N dias
- [ ] Permitir deletar lotes antigos
- [ ] Exportar lote para arquivo compactado único
- [ ] Comparar diferenças entre dois lotes
- [ ] Adicionar checksums no metadata
- [ ] Verificar integridade de lotes

---

**Desenvolvido com** ❤️ **por VPS Guardian**
**Generated with** 🤖 **[Claude Code](https://claude.com/claude-code)**
