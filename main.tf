resource "aws_instance" "main"{
    ami = local.ami_id
    instance_type = var.instance_type
    subnet_id = local.private_subnet_id
    vpc_security_group_ids = [local.sg_id]

    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-${var.component}"
        }
    )
}

resource "terraform_data" "main"{
    triggers_replace = [
        aws_instance.main.id
    ]

    connection {
        type = "ssh"
        user = "ec2-user"
        password = "DevOps321"
        host = aws_instance.main.private_ip
    }

    provisioner "file"{
        source = "bootstrap.sh"
        destination = "/tmp/bootstrap.sh"
    }

    provisioner "remote-exec"{
        inline = [
            "sudo chmod +x /tmp/bootstrap.sh",
            "sudo sh /tmp/bootstrap.sh ${var.component} ${var.environment} ${var.app_version}"
        ]
    }
    depends_on = [aws_instance.main]
}

resource "aws_ec2_instance_state" "main"{
    instance_id = aws_instance.main.id
    state = "stopped"
    depends_on = [terraform_data.main]
}

resource "aws_ami_from_instance" "main"{
    name = "${var.project}-${var.environment}-${var.component}-${var.app_version}-${aws_instance.main.id}"
    source_instance_id = aws_instance.main.id
    depends_on = [aws_ec2_instance_state.main]

    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-${var.component}"
        }
    )
}

resource "aws_lb_target_group" "main"{
    name = "${var.project}-${var.environment}-${var.component}"
    protocol = "HTTP"
    port = local.port_number
    vpc_id = local.vpc_id
    deregistration_delay = 60

    health_check {
        protocol = "HTTP"
        path = local.health_check_path
        port = local.port_number
        healthy_threshold = 5
        unhealthy_threshold = 3
        timeout = 2
        matcher = "200-299"
    }

    depends_on = [aws_ami_from_instance.main]
}

resource "aws_launch_template" "main"{
    name = "${var.project}-${var.environment}-${var.component}"
    image_id = aws_ami_from_instance.main.id
    instance_type = var.instance_type
    # once autoscaling sees less traffic, it will terminate the instance
    instance_initiated_shutdown_behavior = "terminate"
    vpc_security_group_ids = [local.sg_id]
    # each time we apply terraform this version will be updated as default
    update_default_version = true

     # tags for instances created by launch template through autoscaling
    tag_specifications{
        resource_type = "instance"

        tags = merge(
            local.common_tags,
            {
                Name = "${var.project}-${var.environment}-${var.component}"
            }
        )
    }
    
    # tags for volumes created by instances
    tag_specifications {
        resource_type = "volume"

        tags = merge(
            local.common_tags,
            {
                Name = "${var.project}-${var.environment}-${var.component}"
            }
        )
    }

    # tags for launch template
    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-${var.component}"
        }
    )

    depends_on = [aws_lb_target_group.main]
}

resource "aws_autoscaling_group" "main"{
    name = "${var.project}-${var.environment}-${var.component}"
    vpc_zone_identifier = [local.private_subnet_id]
    target_group_arns = [aws_lb_target_group.main.arn]
    health_check_grace_period = 120
    health_check_type = "ELB"
    force_delete = false
    min_size = 1
    max_size = 10
    desired_capacity = 1

    launch_template {
        id = aws_launch_template.main.id
        version = "$Latest"
    }
    #update EC2 instances gradually when the launch template changes, instead of replacing all instances at once.
    instance_refresh {
        strategy = "Rolling"
        preferences {
            min_healthy_percentage = 50
        }
    }

    dynamic tag{
        for_each = merge(
            {
                Name = "${var.project}-${var.environment}-${var.component}"
            },
            local.common_tags
        )

        content{
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }

    timeouts{
        delete = "15m"
    }
}

resource "aws_autoscaling_policy" "main"{
    autoscaling_group_name = aws_autoscaling_group.main.name
    name = "${var.project}-${var.environment}-${var.component}"
    policy_type = "TargetTrackingScaling"
    estimated_instance_warmup = 120

    target_tracking_configuration{
        predefined_metric_specification{
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 70
    }
   depends_on = [aws_autoscaling_group.main]
}

resource "aws_lb_listener_rule" "main"{
    listener_arn = local.alb_listener_arn
    
    condition{
        host_header = local.host_header
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.main.arn
    }
    
    priority = var.rule_priority
}

resource "terraform_data" "main_delete" {
  triggers_replace = [
    aws_instance.main.id
  ]
  depends_on = [aws_autoscaling_policy.main]
  
  # it executes in bastion
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${aws_instance.main.id} "
  }
}