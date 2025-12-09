# Configuração de Backup AWS S3 para Coolify

Guia completo para configurar backups automáticos do Coolify para buckets AWS S3.

## 📋 Visão Geral

O Coolify oferece backups automáticos para buckets AWS S3, proporcionando durabilidade de nível empresarial com 99.999999999% de disponibilidade e replicação automática entre múltiplas instalações.

## ✅ Vantagens da Integração S3

- **Durabilidade & Disponibilidade**: Projetado para máxima confiabilidade com replicação multi-instalação
- **Custo-Benefício**: Modelo pay-as-you-go com regras de ciclo de vida para otimização
- **Integração Perfeita**: Hooks diretos da API eliminam scripts customizados e garantem backups agendados

## ⚠️ Quando Evitar S3

- Requisitos rígidos de residência de dados que exigem armazenamento on-premises
- Ambientes onde acesso à internet de saída está bloqueado

---

## 🚀 Configuração Passo a Passo

### 1. Criar Bucket S3

1. Acesse o console AWS S3: `console.aws.amazon.com/s3`
2. Clique em **"Create Bucket"**
3. Configure:
   - Nome do bucket
   - Configurações de propriedade
4. Deixe outras configurações no padrão (a menos que tenha requisitos específicos)
5. Confirme a criação do bucket

### 2. Criar Política IAM (IAM Policy)

1. Navegue até o console de políticas IAM
2. Clique em **"Create Policy"**
3. Selecione o editor **JSON**
4. Aplique a seguinte política de permissões:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:GetObjectAcl",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::nome-do-seu-bucket",
        "arn:aws:s3:::nome-do-seu-bucket/*"
      ]
    }
  ]
}
```

**⚠️ IMPORTANTE:** Substitua `nome-do-seu-bucket` pelo nome real do bucket criado no passo 1.

5. Continue e atribua um nome descritivo para a política
6. Finalize a criação da política

### 3. Criar Usuário IAM

1. Acesse o console de usuários IAM
2. Clique em **"Create user"**
3. Digite o nome do usuário
4. Selecione **"Attach policies directly"** (Anexar políticas diretamente)
5. Atribua a política criada no passo 2
6. Finalize a criação do usuário

### 4. Gerar Access Keys (Chaves de Acesso)

1. Clique no nome do usuário recém-criado
2. Selecione **"Create access key"**
3. Escolha **"Other"** como caso de uso
4. Gere as chaves e **armazene com segurança**:
   - **Access Key ID**
   - **Secret Access Key**

**🔴 CRÍTICO:** As chaves NÃO podem ser recuperadas após este passo. Salve em local seguro (ex: gerenciador de senhas).

### 5. Configurar S3 no Coolify

1. Acesse o dashboard do Coolify
2. Navegue até a seção **Storage**
3. Clique em **"Add"**
4. Preencha os seguintes detalhes:
   - **Storage name**: Nome identificador (arbitrário)
   - **Description**: Descrição opcional
   - **Endpoint**: `https://s3.REGION.amazonaws.com`
     - Substitua `REGION` pela região AWS (ex: `us-east-1`, `sa-east-1`)
   - **Bucket name**: Nome do bucket criado
   - **AWS region**: Região do bucket (ex: `us-east-1`)
   - **Access Key**: Access Key ID gerada no passo 4
   - **Secret Access Key**: Secret Access Key gerada no passo 4
5. Clique em **"Validate Connection & Continue"**

**Exemplo de endpoint para São Paulo:** `https://s3.sa-east-1.amazonaws.com`

### 6. Habilitar Backups Automáticos

1. Vá para **Settings** → **Backup**
2. Ative a opção **S3**
3. Selecione o storage S3 configurado
4. Configure:
   - **Frequência de backup**: Suporta expressões cron
     - Exemplo: `0 2 * * *` (diariamente às 02:00)
   - **Políticas de retenção**: Quantos backups manter
5. Teste com o botão **"Backup Now"**

---

## ✅ Verificação

Monitore os logs de execução para confirmar que os backups estão sendo armazenados com sucesso no bucket S3.

**Verificar no AWS S3:**
1. Acesse o console S3
2. Navegue até seu bucket
3. Verifique se os arquivos de backup estão sendo criados

---

## 🌍 Regiões AWS Disponíveis

| Região | Código | Endpoint |
|--------|--------|----------|
| US East (N. Virginia) | us-east-1 | https://s3.us-east-1.amazonaws.com |
| US East (Ohio) | us-east-2 | https://s3.us-east-2.amazonaws.com |
| US West (N. California) | us-west-1 | https://s3.us-west-1.amazonaws.com |
| US West (Oregon) | us-west-2 | https://s3.us-west-2.amazonaws.com |
| South America (São Paulo) | sa-east-1 | https://s3.sa-east-1.amazonaws.com |
| Europe (Ireland) | eu-west-1 | https://s3.eu-west-1.amazonaws.com |
| Europe (Frankfurt) | eu-central-1 | https://s3.eu-central-1.amazonaws.com |
| Asia Pacific (Singapore) | ap-southeast-1 | https://s3.ap-southeast-1.amazonaws.com |
| Asia Pacific (Tokyo) | ap-northeast-1 | https://s3.ap-northeast-1.amazonaws.com |

---

## 🔒 Segurança

**Boas práticas:**

1. **Nunca compartilhe** Access Keys publicamente
2. Use **políticas IAM mínimas** (princípio do menor privilégio)
3. Habilite **versionamento** no bucket S3 para proteção contra exclusões acidentais
4. Configure **MFA Delete** para buckets críticos
5. Revise **regularmente** as chaves de acesso e rotacione se necessário

---

## 🛠️ Troubleshooting

### Erro: "Invalid credentials"
- Verifique se Access Key e Secret Access Key estão corretos
- Confirme que a política IAM está anexada ao usuário
- Verifique se o usuário IAM está ativo

### Erro: "Access denied"
- Confirme que a política IAM tem permissões corretas
- Verifique se o ARN do bucket na política está correto
- Confirme que o bucket existe na região especificada

### Erro: "Endpoint not found"
- Verifique se a região no endpoint está correta
- Confirme que o formato do endpoint está correto: `https://s3.REGION.amazonaws.com`

### Backups não aparecem no bucket
- Verifique os logs no Coolify (Settings → Backup → Logs)
- Confirme que "Backup Now" funciona manualmente
- Verifique se o cron está configurado corretamente

---

## 💡 Dicas

1. **Teste primeiro**: Use "Backup Now" antes de confiar nos backups agendados
2. **Monitore custos**: Configure alertas de billing na AWS
3. **Lifecycle rules**: Configure regras para mover backups antigos para S3 Glacier (mais barato)
4. **Retenção inteligente**: Use a estratégia GFS (veja `docs/RETENCAO-BACKUPS.md`)

---

## 📚 Referências

- [Documentação oficial AWS S3](https://docs.aws.amazon.com/s3/)
- [Coolify Discord](https://discord.gg/coolify)
- [Guia de Backup S3 do VPS Guardian](BACKUP-S3-GUIDE.md)

---

**Criado com base no tutorial oficial:** https://envix.shadowarcanist.com/coolify/tutorials/aws-s3-backup-setup/
