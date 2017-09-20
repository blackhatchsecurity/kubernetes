data "template_file" "kubernetes_node_userdata" {
  template = "${file("../../kubernetes/userdata/kubernetes_node.tpl")}"
  vars {
    env = "${var.tag_environment}"
    kubernetes_dns_service_ip = "${var.kubernetes_dns_service_ip}"
    proxy_asg = "${aws_autoscaling_group.etcd_node.name}"

  }
}

resource "aws_autoscaling_policy" "kubernetes_node" {
  name = "kubernetes_nodes.${var.tag_environment}"
  scaling_adjustment = 3
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.kubernetes_node.name}"
}

resource "aws_cloudwatch_metric_alarm" "kubernetes_node" {
  alarm_name = "kubernetes_nodes.${var.tag_environment}-CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "60"
  alarm_description = "This metric monitor sites EC2 cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.kubernetes_node.arn}"]
}

resource "aws_launch_configuration" "kubernetes_node" {
  image_id = "${lookup(var.coreos_ami, var.aws_region)}"
  instance_type = "${var.core_node_size}"
  associate_public_ip_address = false
  user_data = "${data.template_file.kubernetes_node_userdata.rendered}"
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
  "${aws_security_group.kubernetes_node.id}",
  "${aws_security_group.default.id}"

  ]

}

resource "aws_autoscaling_group" "kubernetes_node" {
  name = "kubernetes_nodes.${var.tag_environment}"
  max_size = 10
  min_size = 1
  health_check_grace_period = 300
  desired_capacity = 1
  launch_configuration = "${aws_launch_configuration.kubernetes_node.name}"
  vpc_zone_identifier = ["${aws_subnet.private1a.id}" , "${aws_subnet.private1b.id}" , "${aws_subnet.private1c.id}"]

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["desired_capacity"]
  }

  tag {
    key = "Name"
    value = "kubernetes-node.${var.tag_environment}"
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
}

resource "aws_iam_role_policy" "kubernetes_node" {
  name = "kubernetes_node.${var.tag_environment}"
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

resource "aws_iam_instance_profile" "kubernetes_node" {
  name = "kubernetes_node.${var.tag_environment}"
  roles = ["${aws_iam_role.kubernetes_node.name}"]
}

resource "aws_iam_role" "kubernetes_node" {
  name = "kubernetes_node.${var.tag_environment}"
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
