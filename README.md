# VPC - FIAP Hack

Esta pasta contém a infraestrutura de rede para o projeto FIAP Hack, criando uma VPC escalável e preparada para Kubernetes.

## Arquitetura

A VPC foi projetada seguindo as melhores práticas da AWS para ambientes Kubernetes:

### Componentes Criados

- **VPC**: CIDR 10.0.0.0/16
- **Subnets Públicas**: 3 subnets em diferentes AZs (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- **Subnets Privadas**: 3 subnets em diferentes AZs (10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24)
- **Internet Gateway**: Para acesso à internet das subnets públicas
- **NAT Gateways**: Para acesso à internet das subnets privadas
- **Route Tables**: Configuradas para roteamento adequado
- **Security Groups**: Preparados para EKS

### Características

- **Multi-AZ**: Distribuição em 3 zonas de disponibilidade
- **Escalável**: Preparada para crescimento futuro
- **Segura**: Subnets privadas para cargas de trabalho sensíveis
- **Kubernetes Ready**: Tags e configurações otimizadas para EKS

## Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- Bucket S3 para armazenar o state do Terraform
- Permissões adequadas na AWS

## Configuração

1. **Configure o backend S3** (se necessário):
   ```bash
   aws s3 mb s3://fiap-hack-terraform-state --region us-east-1
   ```

2. **Configure as credenciais AWS**:
   ```bash
   aws configure
   ```

## Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Destruir

```bash
cd terraform
terraform destroy
```

## Outputs

Após o deploy, você terá acesso aos seguintes outputs:

- `vpc_id`: ID da VPC criada
- `public_subnet_ids`: IDs das subnets públicas
- `private_subnet_ids`: IDs das subnets privadas
- `cluster_security_group_id`: ID do security group para EKS
- `node_security_group_id`: ID do security group para nodes EKS

## Custos

- VPC: Gratuita
- NAT Gateways: ~$45/mês por AZ
- EIPs: ~$3.65/mês por EIP
- Data Transfer: Variável

## Próximos Passos

Esta VPC será utilizada pelos seguintes componentes:
- Cluster EKS para o serviço principal
- RDS PostgreSQL
- RabbitMQ no Kubernetes 