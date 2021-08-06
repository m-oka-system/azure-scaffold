################################
# ECS
################################
# Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.env}-${var.project}-cluster"
}

# Task definition
resource "aws_ecs_task_definition" "app" {
  family = "${var.env}-${var.project}-app"

  execution_role_arn       = var.ecs_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"


  container_definitions = jsonencode(
    [
      {
        name  = "app"
        image = "${var.ecr_repository}:latest"

        portMappings = [
          {
            protocol : "tcp",
            hostPort : 3000,
            containerPort : 3000
          }
        ]

        command = ["rails", "s", "-p", "3000", "-b", "0.0.0.0"]

        environment = [
          {
            name  = "RAILS_ENV"
            value = "production"
          },
          {
            name  = "RAILS_SERVE_STATIC_FILES"
            value = "1"
          }
        ]

        secrets = [
          {
            name      = "MYSQL_ROOT_USER"
            valueFrom = aws_ssm_parameter.ecs_db_user.name
          },
          {
            name      = "MYSQL_ROOT_PASSWORD"
            valueFrom = aws_ssm_parameter.ecs_db_password.name
          },
          {
            name      = "RDS_HOST_NAME"
            valueFrom = aws_ssm_parameter.ecs_db_host_name.name
          },
          {
            name      = "SECRET_KEY_BASE"
            valueFrom = aws_ssm_parameter.rails_master_key.name
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${var.env}/${var.project}"
            awslogs-region        = var.region
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    ]
  )
}

# Service
resource "aws_ecs_service" "this" {
  name            = "${var.env}-${var.project}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "app"
    container_port   = "3000"
  }

  network_configuration {
    subnets          = aws_subnet.public.*.id
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }
}
