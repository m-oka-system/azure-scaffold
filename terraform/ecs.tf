################################
# ECS
################################
resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-cluster"
}
