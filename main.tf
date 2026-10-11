resource "aws_instance" "main"{
    ami = local.ami_id
    instance_type = var.instance_type
    subnet_id = local.private_subnet_ids
    vpc_security_group_ids = [local.sg_id]
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
            "sudo sh /tmp/bootstrap.sh ${var.project} ${var.environment} ${var.app_version}"
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
}