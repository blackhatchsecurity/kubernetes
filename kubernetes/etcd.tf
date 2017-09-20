# Instances


data "template_file" "etcd_userdata" {
  template = "${file("../../kubernetes/userdata/etcd.tpl")}"
  vars {
    env = "${var.tag_environment}"
  }
}

resource "aws_launch_configuration" "etcd_node" {
  image_id = "${lookup(var.coreos_ami, var.aws_region)}"
  instance_type = "${var.core_node_size}"
  associate_public_ip_address = false
  user_data = "${data.template_file.etcd_userdata.rendered}"
  key_name = "kubernetes-2"
  iam_instance_profile = "${aws_iam_instance_profile.kubernetes_node.id}"
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
  "${aws_security_group.etcd_node.id}",
  "${aws_security_group.default.id}"

  ]

}


resource "aws_sns_topic" "dns" {
  name = "dns"
}

resource "aws_sns_topic" "dns_etcd" {
  name = "dns_etcd"
}

resource "aws_cloudwatch_metric_alarm" "etcd_node" {
  alarm_name = "etcd_nodes.${var.tag_environment}-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "60"
  alarm_description = "This metric monitor sites EC2 cpu utilization"
}

resource "aws_autoscaling_notification" "dns_etcd" {
  group_names = [
    "${aws_autoscaling_group.etcd_node.name}"

  ]
  notifications  = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE"
  ]
  topic_arn = "${aws_sns_topic.dns_etcd.arn}"
}

resource "aws_autoscaling_group" "etcd_node" {
  name = "etcd_node.${var.tag_environment}"
  max_size = 1
  min_size = 1
  health_check_grace_period = 5
  desired_capacity = 1
  launch_configuration = "${aws_launch_configuration.etcd_node.name}"
  vpc_zone_identifier = ["${aws_subnet.private1a.id}"]

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["desired_capacity"]
  }

  tag {
    key = "Name"
    value = "etcd-node.${var.tag_environment}"
    propagate_at_launch = true
  }

  tag {
    key = "EtcdCluster"
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
    value = "${aws_route53_zone.vpc_zone.zone_id}:etcd"
    propagate_at_launch = true
  }

}

resource "aws_iam_role_policy" "etcd_node" {
  name = "etcd_node.${var.tag_environment}"
  role = "${aws_iam_role.kubernetes_node.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "route53:*",
        "autoscaling:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}



resource "aws_security_group" "etcd_node" {
  name = "etcd.${var.tag_environment}"
  description = "Controls traffic between etcd instances"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "etcd.${var.tag_environment}"
    Environment = "${var.tag_environment}"
    Project = "${var.tag_project}"
  }

  ingress {
    from_port = 2379
    to_port = 2379
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 2380
    to_port = 2380
    protocol = "tcp"
    self = true
  }

  ingress {
    from_port = 2379
    to_port = 2379
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port = 2380
    to_port = 2380
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
