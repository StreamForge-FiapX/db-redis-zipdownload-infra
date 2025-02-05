variable "aws-region" {
  type        = string
  description = "AWS Region"
  default     = "sa-east-1"
}

terraform {
  backend "s3" {
    bucket  = "6soat-tfstate"
    key     = "terraform-redis/zipdownload-redis/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws-region
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "zipdownload-redis-subnet-group"
  subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]

  tags = {
    Name        = "zipdownload-redis Subnet Group"
    Environment = "production"
    Service     = "zipdownload"
  }
}

resource "aws_elasticache_replication_group" "redis_replication_group" {
  replication_group_id        = "zipdownload-redis"
  description                 = "Redis Replication Group for zipdownload"
  engine                      = "redis"
  engine_version              = "7.0"
  node_type                   = "cache.t3.micro"
  num_cache_clusters          = 2
  automatic_failover_enabled  = true
  multi_az_enabled            = true
  preferred_cache_cluster_azs = ["sa-east-1a", "sa-east-1b"]
  parameter_group_name        = "default.redis7"
  subnet_group_name           = aws_elasticache_subnet_group.redis_subnet_group.id
  security_group_ids          = [aws_security_group.redis_sg.id]

  tags = {
    Name        = "zipdownload Redis Replication Group"
    Environment = "production"
    Service     = "zipdownload"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "zipdownload-redis-sg"
  description = "Security group for zipdownload Redis"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "zipdownload Redis Security Group"
    Environment = "production"
    Service     = "zipdownload"
  }
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis_replication_group.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.redis_replication_group.port
}

resource "aws_iam_policy" "secretsPolicy" {
  name = "podsecret-deployment-policy-zipdownload"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = [aws_secretsmanager_secret.db_credentials.arn]
      },
    ]
  })
}

output "secrets_policy" {
  value = aws_iam_policy.secretsPolicy.arn
}

output "secrets_id" {
  value = aws_secretsmanager_secret.db_credentials.id
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "zipdownload-dbcredential-redis-db"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    redis_host     = aws_elasticache_replication_group.redis_replication_group.primary_endpoint_address
    redis_port     = aws_elasticache_replication_group.redis_replication_group.port
    redis_password = ""
  })
}
