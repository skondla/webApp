####################
# MyService
####################
data "aws_ecs_task_definition" "myservice" {
  task_definition = "myservice-${var.environment}"
}

resource "aws_ecs_service" "myservice" {
  name                               = "myservice"
  cluster                            = "${var.name}-${var.environment}"
  task_definition                    = data.aws_ecs_task_definition.myservice.id
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  network_configuration {
    subnets = [aws_subnet.internal[0].id, aws_subnet.internal[1].id, aws_subnet.internal[2].id]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_count, task_definition]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.myservice.arn
  }
}

resource "aws_service_discovery_service" "myservice" {
  name = "myservice"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.private.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
