data "template_file" "openssl_cnf" {
  template = "${file("${path.module}/scripts/openssl.tpl")}"

  vars {
    K8S_SERVICE_IP = "${var.kubernetes_service_ip}"
    DOMAIN_NAME = "${var.domain_name}"
  }
}

data "template_file" "init_ssl" {
  template = "${file("${path.module}/scripts/init-ssl.tpl")}"

  vars {
    PATH_ROOT = "${path.root}"
  }
}

resource "null_resource" "pki" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/ssl"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.openssl_cnf.rendered}\" > ${path.root}/ssl/openssl.cnf"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.init_ssl.rendered}\" > ${path.root}/ssl/init-ssl.sh && chmod +x ${path.root}/ssl/init-ssl.sh"
  }

  provisioner "local-exec" {
    command = "${path.root}/ssl/init-ssl.sh"
  }
}
