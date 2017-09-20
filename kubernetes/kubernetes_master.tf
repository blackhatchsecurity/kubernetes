data "template_file" "kubernetes_master_userdata" {
  template = "${file("../../kubernetes/userdata/kubernetes_master.tpl")}"
  vars {
    env = "${var.tag_environment}"
    kubernetes_dns_service_ip = "${var.kubernetes_dns_service_ip}"
    kubernetes_service_ip_range = "${var.kubernetes_service_ip_range}"
    proxy_asg = "${aws_autoscaling_group.etcd_node.name}"

  }
}

resource "aws_launch_configuration" "kubernetes_master" {
  image_id = "${lookup(var.coreos_ami, var.aws_region)}"
  instance_type = "${var.core_node_size}"
  associate_public_ip_address = false
  user_data = "${data.template_file.kubernetes_master_userdata.rendered}"
  key_name = "kubernetes-2"
  iam_instance_profile = "${aws_iam_instance_profile.kubernetes_master.id}"
  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_size}"
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "gp2"
    volume_size = "${var.ebs_size}"
    encrypted = true
  }

  security_groups = [
    "${aws_security_group.coreos.id}",
    "${aws_security_group.remote.id}",
    "${aws_security_group.etcd_node.id}",
    "${aws_security_group.kubernetes_master.id}"
  ]

}

resource "aws_autoscaling_notification" "dns_kubernetes_master" {
  group_names = [
    "${aws_autoscaling_group.kubernetes_master.name}"

  ]
  notifications  = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE"
  ]
  topic_arn = "${aws_sns_topic.dns_etcd.arn}"
}

resource "aws_autoscaling_group" "kubernetes_master" {
  name = "kubernetes.${var.tag_environment}"
  max_size = 1
  min_size = 1
  health_check_grace_period = 5
  desired_capacity = 1
  launch_configuration = "${aws_launch_configuration.kubernetes_master.name}"
  vpc_zone_identifier = ["${aws_subnet.private1a.id}"]

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["desired_capacity"]
  }

  tag {
    key = "Name"
    value = "kubernetes-master.${var.tag_environment}"
    propagate_at_launch = true
  }

  tag {
    key = "KubernetesCluster"
    value = "${var.tag_project}.${var.tag_environment}"
    propagate_at_launch = true
  }

  tag {
    key = "Environment"
    value = "${var.tag_environment}"
    propagate_at_launch = true
  }

  tag {
    key = "Project"
    value = "${var.tag_project}"
    propagate_at_launch = true
  }

  tag {
    key = "DomainMeta"
    value = "${aws_route53_zone.vpc_zone.zone_id}:kubernetes"
    propagate_at_launch = true
  }

}


resource "aws_iam_role_policy" "kubernetes_master" {
  name = "kubernetes_master.${var.tag_environment}"
  role = "${aws_iam_role.kubernetes_master.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*",
        "autoscaling:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "kubernetes_master" {
  name = "kubernetes_master.${var.tag_environment}"
  roles = ["${aws_iam_role.kubernetes_master.name}"]
}

resource "aws_iam_role" "kubernetes_master" {
  name = "kubernetes_master.${var.tag_environment}"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

#resource "aws_route53_record" "kubernetes" {
#  zone_id = "${aws_route53_zone.vpc_zone.zone_id}"
#  name = "kubernetes"
#  type = "A"
#  ttl = "60"
#  records = ["${aws_instance.kubernetes_master.private_ip}"]
#}
