resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr_network}.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = false
  tags {
    Name = "main.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_vpc_dhcp_options" "dns_search" {
  domain_name = "${var.domain_name}"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags {
    Name = "default.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_search" {
  vpc_id = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dns_search.id}"
}

resource "aws_route53_zone" "vpc_zone" {
  name = "${var.domain_name}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "main.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_eip" "nat1a" {
  vpc = true
}

resource "aws_eip" "nat1b" {
  vpc = true
}

resource "aws_eip" "nat1c" {
  vpc = true
}

resource "aws_nat_gateway" "gw1a" {
  allocation_id = "${aws_eip.nat1a.id}"
  subnet_id = "${aws_subnet.public1a.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw1b" {
  allocation_id = "${aws_eip.nat1b.id}"
  subnet_id = "${aws_subnet.public1b.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw1c" {
  allocation_id = "${aws_eip.nat1c.id}"
  subnet_id = "${aws_subnet.public1c.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "private1a" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_cidr_network}.1.0/24"
  availability_zone = "eu-west-1a"

  tags {
    Name = "private1a.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
  }
}

resource "aws_subnet" "private1b" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_cidr_network}.2.0/24"
  availability_zone = "eu-west-1b"

  tags {
    Name = "private1b.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
  }
}

resource "aws_subnet" "private1c" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_cidr_network}.3.0/24"
  availability_zone = "eu-west-1c"

  tags {
    Name = "private1c.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
  }
}

resource "aws_subnet" "public1a" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_cidr_network}.11.0/24"
  availability_zone = "eu-west-1a"

  tags {
    Name = "public1a.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
  }
}

resource "aws_subnet" "public1b" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_cidr_network}.12.0/24"
  availability_zone = "eu-west-1b"

  tags {
    Name = "public1b.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}" // potential fix for AWS cloud-provider
  }
}

resource "aws_subnet" "public1c" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_cidr_network}.13.0/24"
  availability_zone = "eu-west-1c"

  tags {
    Name = "public1c.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}" // potential fix for AWS cloud-provider
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "public.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_route" "poseidon_public_shared" {
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "10.25.0.0/16"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.shared.id}"
  depends_on = ["aws_route_table.public", "aws_vpc_peering_connection.shared"]
}

output "rt_public" {
  value = "${aws_route_table.public.id}"
}

resource "aws_route" "igw" {
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
  depends_on = ["aws_route_table.public", "aws_internet_gateway.gw"]
}


resource "aws_route_table_association" "public1a" {
  subnet_id = "${aws_subnet.public1a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public1b" {
  subnet_id = "${aws_subnet.public1b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public1c" {
  subnet_id = "${aws_subnet.public1c.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private_1a" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "private1a.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

output "rt_private_1a" {
  value = "${aws_route_table.private_1a.id}"
}

resource "aws_route" "nat1a" {
  route_table_id = "${aws_route_table.private_1a.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.gw1a.id}"
  depends_on = ["aws_route_table.private_1a", "aws_nat_gateway.gw1a"]
}

resource "aws_route_table" "private_1b" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "private1b.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

output "rt_private_1b" {
  value = "${aws_route_table.private_1b.id}"
}

resource "aws_route" "nat1b" {
  route_table_id = "${aws_route_table.private_1b.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.gw1b.id}"
  depends_on = ["aws_route_table.private_1b", "aws_nat_gateway.gw1b"]
}

resource "aws_route_table" "private_1c" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "private1c.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

output "rt_private_1c" {
  value = "${aws_route_table.private_1c.id}"
}

resource "aws_route" "nat1c" {
  route_table_id = "${aws_route_table.private_1c.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.gw1c.id}"
  depends_on = ["aws_route_table.private_1c", "aws_nat_gateway.gw1c"]
}

resource "aws_route_table_association" "private1a" {
  subnet_id = "${aws_subnet.private1a.id}"
  route_table_id = "${aws_route_table.private_1a.id}"
}

resource "aws_route_table_association" "private1b" {
  subnet_id = "${aws_subnet.private1b.id}"
  route_table_id = "${aws_route_table.private_1b.id}"
}

resource "aws_route_table_association" "private1c" {
  subnet_id = "${aws_subnet.private1c.id}"
  route_table_id = "${aws_route_table.private_1c.id}"
}

resource "aws_vpc_peering_connection" "shared" {
  peer_owner_id = "${var.shared_owner_id}"
  peer_vpc_id = "${var.shared_vpc_id}"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "poseidon_${var.tag_environment}_to_shared"
  }
}

resource "aws_route" "poseidon_private1a_shared" {
  route_table_id = "${aws_route_table.private_1a.id}"
  destination_cidr_block = "${var.shared_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.shared.id}"
  depends_on = ["aws_route_table.private_1a", "aws_vpc_peering_connection.shared"]
}

resource "aws_route" "poseidon_private1b_shared" {
  route_table_id = "${aws_route_table.private_1b.id}"
  destination_cidr_block = "${var.shared_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.shared.id}"
  depends_on = ["aws_route_table.private_1b", "aws_vpc_peering_connection.shared"]
}

resource "aws_route" "poseidon_private1c_shared" {
  route_table_id = "${aws_route_table.private_1c.id}"
  destination_cidr_block = "${var.shared_vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.shared.id}"
  depends_on = ["aws_route_table.private_1c", "aws_vpc_peering_connection.shared"]
}


#### security groups

resource "aws_security_group" "default" {
  name = "default.${var.tag_environment}"
  description = "Used in the terraform"
  vpc_id = "${aws_vpc.main.id}"

  # outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "default.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_security_group" "natbox" {
  name = "natbox.${var.tag_environment}"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "natbox.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  # SMTP
  ingress {
    from_port = 25
    to_port = 25
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  ingress {
    from_port = 465
    to_port = 465
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  ingress {
    from_port = 587
    to_port = 587
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  # GIT
  ingress {
    from_port = 9418
    to_port = 9418
    protocol = "tcp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  # NTP
  ingress {
    from_port = 123
    to_port = 123
    protocol = "udp"
    security_groups = ["${aws_security_group.default.id}"]
  }

  # ICMP
  ingress {
    from_port = 0
    to_port = 0
    protocol = "icmp"
    security_groups = ["${aws_security_group.default.id}"]
  }
}

resource "aws_security_group" "monitoring_client" {
  name = "monitoring_client.${var.tag_environment}"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "monitoring_client.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}


resource "aws_security_group" "nat" {
  name = "nat.${var.tag_environment}"
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "nat.${var.tag_environment}.${var.tag_project}"
    Environment = "${var.tag_environment}"
  }
}

resource "aws_security_group" "kubernetes_master" {
  name = "kubernetes_master.${var.tag_environment}"
  description = "Controls public traffic into kubernetes master"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "kubernetes_master.${var.tag_environment}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
    Project = "${var.tag_project}"
  }
}

resource "aws_security_group" "kubernetes_node" {
  name = "kubernetes_node.${var.tag_environment}"
  description = "Controls traffic between kubernetes node instances"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "kubernetes_node.${var.tag_environment}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
    Project = "${var.tag_project}"
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "haproxy_node" {
  name = "haproxy_node.${var.tag_environment}"
  description = "Controls traffic between kubernetes node instances"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "haproxy_node.${var.tag_environment}"
    Environment = "${var.tag_environment}"
    KubernetesCluster = "${var.tag_project}.${var.tag_environment}"
    Project = "${var.tag_project}"
  }


  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.vpc_cidr_network}.0.0/16", "10.25.0.0/16"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = 443
    to_port = 443
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [
      "${var.shared_vpc_cidr_block}",
      "62.255.129.107/32",
      "62.255.129.108/32",
      "62.255.129.110/32"
    ]
  }

  ingress {
    from_port = 8888
    to_port = 8888
    protocol = "TCP"
    cidr_blocks = [
      "${var.shared_vpc_cidr_block}",
      "62.255.129.107/32",
      "62.255.129.108/32",
      "62.255.129.110/32"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "coreos" {
  name = "coreos.${var.tag_environment}"
  description = "Controls traffic between CoreOS instances"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "coreos.${var.tag_environment}"
    Environment = "${var.tag_environment}"
    Project = "${var.tag_project}"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "remote" {
  name = "remote.${var.tag_environment}"
  description = "Controls public traffic to/from instances"
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "remote.${var.tag_environment}"
    Environment = "${var.tag_environment}"
    Project = "${var.tag_project}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "kubernetes_sg" {
  value = "${aws_security_group.kubernetes_master.id}"
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "private_subnet_ids" {
  value = "${aws_subnet.private1a.id},${aws_subnet.private1b.id},${aws_subnet.private1c.id}"
}

output "public_subnet_ids" {
  value = "${aws_subnet.public1a.id},${aws_subnet.public1b.id},${aws_subnet.public1c.id}"
}

output "vpc_cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}
