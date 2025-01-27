# Infraestrutura Redis para Zipdownload

Este repositório contém a configuração do Terraform para provisionar um cluster Redis na AWS ElastiCache para o serviço Zipdownload.

## Recursos Provisionados

- Cluster Redis ElastiCache com 2 nós em multi-AZ
- Grupo de segurança para controle de acesso
- Grupo de subnets para o cluster
- Secret no AWS Secrets Manager para armazenar credenciais
- Política IAM para acesso aos secrets

## Pré-requisitos

- Terraform instalado
- Credenciais AWS configuradas
- Bucket S3 para armazenar o estado do Terraform

## Variáveis

| Nome | Descrição | Valor Padrão |
|------|-----------|--------------|
| aws-region | Região AWS onde os recursos serão criados | sa-east-1 |

## Outputs

| Nome | Descrição |
|------|-----------|
| redis_primary_endpoint | Endpoint primário do cluster Redis |
| redis_port | Porta do Redis |
| secrets_policy | ARN da política IAM para acesso aos secrets |
| secrets_id | ID do secret no Secrets Manager |

## Como usar

1. Clone o repositório
2. Configure as credenciais AWS
3. Inicialize o Terraform:
