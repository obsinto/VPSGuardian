# Teste Rápido: Validar Migração de Volumes

## 🧪 Passo 1: Validar Scripts (1 minuto)

```bash
cd /opt/vpsguardian/migrar
./test-migration-scripts.sh
```

**Resultado esperado:** ✅ TODOS OS TESTES PASSARAM

---

## 🔍 Passo 2: Testar Help (30 segundos)

```bash
./backup-volumes.sh --help
./transfer-volumes.sh --help
./restore-volumes.sh --help
```

**Resultado esperado:** Cada comando exibe instruções de uso

---

## 🎯 Passo 3: Teste Prático (Opcional - 5 minutos)

### Criar Volume de Teste

```bash
# 1. Criar volume de teste
docker volume create volume-teste

# 2. Adicionar arquivos de teste
docker run --rm -v volume-teste:/data alpine sh -c '
  echo "Teste 1" > /data/file1.txt
  echo "Teste 2" > /data/file2.txt
  mkdir /data/subdir
  echo "Teste 3" > /data/subdir/file3.txt
'

# 3. Verificar conteúdo
docker run --rm -v volume-teste:/data alpine ls -la /data
```

### Fazer Backup

```bash
./backup-volumes.sh --volume=volume-teste
```

**Resultado esperado:**
- Backup criado em `./volume-backup/volume-teste-backup-TIMESTAMP.tar.gz`
- Mensagem de sucesso exibida

### Verificar Backup

```bash
ls -lh ./volume-backup/
tar -tzf ./volume-backup/volume-teste-backup-*.tar.gz | head -10
```

**Resultado esperado:**
- Arquivo .tar.gz criado
- Lista de arquivos mostra file1.txt, file2.txt, subdir/

### Restaurar Backup (Teste Local)

```bash
# 1. Criar novo volume
docker volume create volume-teste-restaurado

# 2. Restaurar backup
./restore-volumes.sh --volume=volume-teste-restaurado \
  --backup=./volume-backup/volume-teste-backup-*.tar.gz

# 3. Verificar conteúdo restaurado
docker run --rm -v volume-teste-restaurado:/data alpine ls -la /data
docker run --rm -v volume-teste-restaurado:/data alpine cat /data/file1.txt
```

**Resultado esperado:**
- Volume restaurado com sucesso
- Arquivos idênticos aos originais

### Limpar Teste

```bash
docker volume rm volume-teste volume-teste-restaurado
rm -rf ./volume-backup/
```

---

## 🌐 Passo 4: Teste de Migração Remota (Opcional - 10 minutos)

**Requisitos:** Servidor remoto com Docker e acesso SSH

### Preparar Servidor Remoto

```bash
# No servidor remoto
ssh root@IP_SERVIDOR_REMOTO
docker --version  # Verificar Docker instalado
exit
```

### Executar Migração

```bash
# 1. Criar volume de teste (se ainda não existe)
docker volume create volume-teste
docker run --rm -v volume-teste:/data alpine sh -c 'echo "Migração Teste" > /data/teste.txt'

# 2. Criar backup
./backup-volumes.sh --volume=volume-teste

# 3. Executar migração completa
./migrar-volumes.sh
# Informar IP do servidor remoto
# Selecionar volume-teste
# Confirmar migração
```

### Validar no Servidor Remoto

```bash
ssh root@IP_SERVIDOR_REMOTO

# Listar volumes
docker volume ls | grep volume-teste

# Ver conteúdo
docker run --rm -v volume-teste:/data alpine cat /data/teste.txt

# Deve exibir: "Migração Teste"
```

### Limpar

```bash
# Local
docker volume rm volume-teste
rm -rf ./volume-backup/

# Remoto
ssh root@IP_SERVIDOR_REMOTO 'docker volume rm volume-teste'
```

---

## ✅ Checklist de Validação

### Testes Básicos
- [ ] Script de teste executado com sucesso
- [ ] Comandos --help funcionam
- [ ] Scripts têm permissão de execução

### Teste de Backup
- [ ] Backup criado com sucesso
- [ ] Arquivo .tar.gz gerado
- [ ] Tamanho do arquivo razoável
- [ ] Conteúdo verificado com tar -tzf

### Teste de Restauração
- [ ] Volume restaurado localmente
- [ ] Arquivos idênticos aos originais
- [ ] Permissões preservadas

### Teste de Migração Remota (Opcional)
- [ ] Conexão SSH estabelecida
- [ ] Backup transferido
- [ ] Volume criado no servidor remoto
- [ ] Dados restaurados corretamente
- [ ] Arquivos validados no destino

---

## 🚨 Solução de Problemas

### Erro: "Docker not found"
```bash
# Verificar instalação
docker --version

# Se não instalado
curl -fsSL https://get.docker.com | bash
```

### Erro: "Permission denied"
```bash
# Dar permissão de execução
chmod +x migrar/*.sh
```

### Erro: "No such file lib/common.sh"
```bash
# Verificar estrutura do projeto
ls -la lib/

# Se não existe, você está no diretório errado
cd /opt/vpsguardian
```

### Erro SSH na migração remota
```bash
# Testar SSH manualmente
ssh -i /root/.ssh/id_rsa root@IP

# Verificar chave
ls -la ~/.ssh/id_rsa

# Gerar nova chave se necessário
ssh-keygen -t rsa -b 4096
ssh-copy-id root@IP
```

---

## 📋 Resultado Esperado Final

Após executar todos os testes:

```
✅ Scripts validados
✅ Backup funcional
✅ Restauração funcional
✅ Migração remota funcional (se testado)
```

**Próximo passo:** Usar em produção com confiança!

---

## 🎯 Uso em Produção

Após validar tudo:

```bash
# Via menu
vps-guardian
# → 3. Migração
# → 2. Migrar Volumes Docker

# Ou diretamente
./migrar/migrar-volumes.sh
```

---

**Dica:** Execute sempre o teste básico (`./test-migration-scripts.sh`) antes de usar em produção para garantir que tudo está OK.
