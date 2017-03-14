variable "haproxy_node_size" {
  default = "m3.2xlarge"
}

data "template_file" "haproxy_node_userdata" {
  template = "${file("../../mod-infrastructure/userdata/haproxy_node.tpl")}"
  vars {
    env = "${var.tag_environment}"
    kubernetes_dns_service_ip = "${var.kubernetes_dns_service_ip}"
    proxy_asg = "${aws_autoscaling_group.etcd_node.name}"

  }


}

resource "aws_launch_configuration" "haproxy_node" {
  image_id = "${lookup(var.coreos_ami, var.aws_region)}"
  instance_type = "${var.haproxy_node_size}"
  associate_public_ip_address = true
  user_data = "${data.template_file.haproxy_node_userdata.rendered}"
  key_name = "coreos"
  iam_instance_profile = "${aws_iam_instance_profile.haproxy_node.id}"


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
  "${aws_security_group.haproxy_node.id}",
  "${aws_security_group.default.id}"

  ]


}

resource "aws_autoscaling_notification" "dns_kubernetes_haproxy" {
  group_names = [
    "${aws_autoscaling_group.haproxy_node.name}"

  ]
  notifications  = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE"
  ]
  topic_arn = "${aws_sns_topic.dns.arn}"
}


resource "aws_autoscaling_group" "haproxy_node" {
  name = "haproxy_nodes.${var.tag_environment}"
  max_size = 20
  min_size = 3
  health_check_grace_period = 300
  desired_capacity = 3
  launch_configuration = "${aws_launch_configuration.haproxy_node.name}"
  vpc_zone_identifier = ["${aws_subnet.public1a.id}" , "${aws_subnet.public1b.id}" , "${aws_subnet.public1c.id}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "Name"
    value = "haproxy-node.${var.tag_environment}"
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
    value = "${aws_route53_zone.vpc_zone.zone_id}:nodes"
    propagate_at_launch = true
  }

}

resource "aws_iam_role_policy" "haproxy_node" {
    name = "haproxy_node.${var.tag_environment}"
    role = "${aws_iam_role.haproxy_node.id}"
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

resource "aws_iam_instance_profile" "haproxy_node" {
  name = "haproxy_node.${var.tag_environment}"
  roles = ["${aws_iam_role.haproxy_node.name}"]
}

resource "aws_iam_role" "haproxy_node" {
  name = "haproxy_node.${var.tag_environment}"
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
