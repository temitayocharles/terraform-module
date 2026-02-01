// Service discovery (moved from root) — updated to reference module outputs

resource "aws_service_discovery_private_dns_namespace" "cicd" {
  name        = "${local.env.project_config.name}.local"
  description = "Private DNS namespace for CI/CD infrastructure service discovery"
  vpc         = local.final_vpc_id

  tags = {
    Name        = "${local.env.project_config.name}-service-discovery"
    Project     = local.env.project_config.name
    Environment = local.env.project_config.environment
  }
}

# Jenkins & K8s Master Service
resource "aws_service_discovery_service" "jenkins_k8s_master" {
  count = length(module.jenkins_k8s_master) > 0 ? 1 : 0
  name  = "jenkins-k8s-master"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cicd.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = {
    Name        = "${local.env.project_config.name}-jenkins-k8s-master-discovery"
    Project     = local.env.project_config.name
    Environment = local.env.project_config.environment
  }
}

resource "aws_service_discovery_instance" "jenkins_k8s_master" {
  count       = length(module.jenkins_k8s_master) > 0 ? 1 : 0
  instance_id = module.jenkins_k8s_master[0].instance_ids[0]
  service_id  = aws_service_discovery_service.jenkins_k8s_master[0].id

  attributes = {
    AWS_INSTANCE_IPV4 = module.jenkins_k8s_master[0].private_ips[0]
    AWS_INSTANCE_PORT = "8080"
  }
}

# K8s Worker 1 Service
resource "aws_service_discovery_service" "k8s_worker_1" {
  count = length(module.k8s_worker_1) > 0 ? 1 : 0
  name  = "k8s-worker-1"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cicd.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = {
    Name        = "${local.env.project_config.name}-k8s-worker-1-discovery"
    Project     = local.env.project_config.name
    Environment = local.env.project_config.environment
  }
}

resource "aws_service_discovery_instance" "k8s_worker_1" {
  count       = length(module.k8s_worker_1) > 0 ? 1 : 0
  instance_id = module.k8s_worker_1[0].instance_ids[0]
  service_id  = aws_service_discovery_service.k8s_worker_1[0].id

  attributes = {
    AWS_INSTANCE_IPV4 = module.k8s_worker_1[0].private_ips[0]
  }
}

# K8s Worker 2 Service (conditional)
resource "aws_service_discovery_service" "k8s_worker_2" {
  count = length(module.k8s_worker_2) > 0 ? 1 : 0
  name  = "k8s-worker-2"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cicd.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = {
    Name        = "${local.env.project_config.name}-k8s-worker-2-discovery"
    Project     = local.env.project_config.name
    Environment = local.env.project_config.environment
  }
}

resource "aws_service_discovery_instance" "k8s_worker_2" {
  count       = length(module.k8s_worker_2) > 0 ? 1 : 0
  instance_id = module.k8s_worker_2[0].instance_ids[0]
  service_id  = aws_service_discovery_service.k8s_worker_2[0].id

  attributes = {
    AWS_INSTANCE_IPV4 = module.k8s_worker_2[0].private_ips[0]
  }
}

# Nexus & SonarQube Service (conditional)
resource "aws_service_discovery_service" "nexus_sonarqube" {
  count = length(module.nexus_sonarqube) > 0 ? 1 : 0
  name  = "tools"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cicd.id
    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = {
    Name        = "${local.env.project_config.name}-tools-discovery"
    Project     = local.env.project_config.name
    Environment = local.env.project_config.environment
  }
}

resource "aws_service_discovery_instance" "nexus_sonarqube" {
  count       = length(module.nexus_sonarqube) > 0 ? 1 : 0
  instance_id = module.nexus_sonarqube[0].instance_ids[0]
  service_id  = aws_service_discovery_service.nexus_sonarqube[0].id

  attributes = {
    AWS_INSTANCE_IPV4 = module.nexus_sonarqube[0].private_ips[0]
    NEXUS_PORT        = "8081"
    SONARQUBE_PORT    = "9000"
  }
}

# Monitoring Service (conditional)
resource "aws_service_discovery_service" "monitoring" {
  count = length(module.monitoring) > 0 ? 1 : 0
  name  = "monitoring"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.cicd.id
    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = {
    Name        = "${local.env.project_config.name}-monitoring-discovery"
    Project     = local.env.project_config.name
    Environment = local.env.project_config.environment
  }
}

resource "aws_service_discovery_instance" "monitoring" {
  count       = length(module.monitoring) > 0 ? 1 : 0
  instance_id = module.monitoring[0].instance_ids[0]
  service_id  = aws_service_discovery_service.monitoring[0].id

  attributes = {
    AWS_INSTANCE_IPV4  = module.monitoring[0].private_ips[0]
    PROMETHEUS_PORT    = "9090"
    GRAFANA_PORT       = "3000"
    NODE_EXPORTER_PORT = "9100"
  }
}
