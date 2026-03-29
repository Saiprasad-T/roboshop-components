locals {
    ami_id = data.aws_ami.ami.id
    private_snet = split(",", data.aws_ssm_parameter.private-snet.value[0])
    sg_id = data.aws_ssm_parameter.sg_id.value
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    listener_arn = data.aws_ssm_parameter.listener_arn.value
    port_number = var.component == "frontend" ? 80 : 8080
    health_check_path = var.component == "frontend" ? "/" : "/health"
    values = var.component == "frontend" ? "${var.component}-${var.environment}.${var.domain}" : "${var.component}.backend-alb-${var.environment}.${var.domain}"
}

locals {
    common_tags = {         #if not tags were given, this will fill common tags
        Name = var.project
        environment = var.environment
        terraform = true
    }
}