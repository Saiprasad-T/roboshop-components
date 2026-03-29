resource "aws_instance" "main" {
  ami                     = local.ami_id
  instance_type           = var.instance_type
  subnet_id               = local.private_snet
  vpc_security_group_ids  = [local.sg_id]
  tags = merge(
    local.common_tags,
 {
    Name =  "${var.project}-${var.environment}-${var.component}"
 },
    var.ec2_tags
  )
}

resource "terraform_data" "main" {   #triggering to component
  triggers_replace = [
    aws_instance.main.id,
  ]

  connection {   #connecting to component
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.main.private_ip  #Terraform stores these values in the state file.
  }

  provisioner "file" {
    source      = "bootstrap.sh" # Local file path
    destination = "/tmp/bootstrap.sh"    # Destination path on the remote machine
  }

  provisioner "remote-exec" {   #after connecting it executes this values
     inline = [
        "chmod +x /tmp/bootstrap.sh",   #giving execution permission
        "sudo sh /tmp/bootstrap.sh ${var.component} ${var.environment}"     #running that bootstarp.sh
    ]
  }
}

#===============================================================================
#to stop ec2_instance

resource "aws_ec2_instance_state" "main" {
  instance_id = aws_instance.main.id
  state       = "stopped"

depends_on = [terraform_data.main]
}

#=====================================================================================
#to take the ami

resource "aws_ami_from_instance" "main" {
  name               = "${var.project}-${var.environment}-${var.component}"
  # name               = "catalogue-ami-${formatdate("YYYYMMDDhhmmss", timestamp())}" #as this format creating from starting
  source_instance_id = aws_instance.main.id
  depends_on = [aws_ec2_instance_state.main]
  tags = merge(
    {
        Name = "${var.project}-${var.environment}-${var.component}"
    },
    local.common_tags
  )
}

#=======================================
#created only target groups
resource "aws_lb_target_group" "main" {
  name        = "${var.project}-${var.environment}-${var.component}-tg"
  port        = local.port_number
  protocol    = "HTTP"
  deregistration_delay = 120
  vpc_id      = local.vpc_id

  health_check {
    matcher = "200-299"
    protocol = "HTTP"
    port = local.port_number
    healthy_threshold = 3
    unhealthy_threshold = 2
    interval = 10
    timeout  = 5
    path = local.health_check_path
  } 
}

#=======================================
#launch template

resource "aws_launch_template" "main" {
  name = "${var.project}-${var.environment}-${var.component}-lp"

  image_id = aws_ami_from_instance.main.id

  instance_initiated_shutdown_behavior = "terminate"  #if less traffic terminate device

  instance_type = "t3.micro"

  update_default_version = true  #ASG starts using the latest version

  vpc_security_group_ids = [local.sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
    {
      Name = "${var.project}-${var.environment}-${var.component}"
    },
    local.common_tags
    )
  }
  tags = merge(
    local.common_tags,
    {
        Name =  "${var.project}-${var.environment}-${var.component}"
    },
    var.launch_template_tags
  )
}

#===============================================================
#ASG

resource "aws_autoscaling_group" "main" {
  name                      = "${var.project}-${var.environment}-${var.component}"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 120
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = false
  launch_template {
  id      = aws_launch_template.main.id
  version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.main.arn]
  vpc_zone_identifier   = local.private_snet

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.environment}-${var.component}"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  name                   = "${var.project}-${var.environment}-${var.component}"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 120

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

#======================================================================

resource "aws_lb_listener_rule" "static" {
   listener_arn = local.listener_arn
   priority     = var.rule_priority
   action {
   type             = "forward"
   target_group_arn = aws_lb_target_group.main.arn
   }
   condition {
     host_header {
       values = [local.values]
     }
 }
 } 
 
/* resource "terraform_data" "catalogue_delete" {   
  triggers_replace = [
    aws_instance.catalogue.id,
  ]
  depends_on = [aws_autoscaling_policy.catalogue]
  provisioner "local-exec" {   #after connecting it executes this values
     command = "aws ec2 terminate-instances --instance-ids ${aws_instance.catalogue.id}"
  }
} */