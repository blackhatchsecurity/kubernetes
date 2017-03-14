#cloud-config
write-files:
  - path: "/etc/flannel/options.env"
    owner: "root"
    content: |
      FLANNELD_IFACE=$private_ipv4
      FLANNELD_ETCD_ENDPOINTS=http://127.0.0.1:2379

  - path: "/etc/kubernetes.env"
    content: |
      MASTER_HOSTS=kubernetes
      DNS_SERVICE_IP=10.3.0.10
  - path: /etc/systemd/system/etcd2.service.d/30-etcd_peers.conf
    permissions: 0644
    content: |
      [Service]
      # Load the other hosts in the etcd leader autoscaling group from file
      EnvironmentFile=/etc/sysconfig/etcd-peers

  - path: "/tmp/setup-instance-env.sh"
    owner: "root"
    permissions: "0700"
    content: |
      #!/bin/bash
      echo "PRIVATE_IP=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-ipv4)" >> /tmp/instance.env
      echo "PRIVATE_DNS=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/local-hostname)" >> /tmp/instance.env
      cp /tmp/instance.env /etc/instance.env
  - path: "/tmp/worker-openssl.cnf"
    owner: "root"
    content: |
      [req]
      req_extensions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = CA:FALSE
      keyUsage = nonRepudiation, digitalSignature, keyEncipherment
      subjectAltName = @alt_names
      [alt_names]
      IP.1 = $ENV::WORKER_IP
  - path: "/tmp/ca-key.pem"
    owner: "root"
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEA2N2ZpeNClp83XoIoOfOzOkkjL+BlEbsBnpdYz/CkCXnF+FXp
      DNOWMSWVlmZQMkhhJebexf/uHaq/dMjbrwd4hwfJOe1MeGQ0qYGtCV/Shcpcrw7I
      /yBPeOnxvE9rezb9FpNMJ1wai7Tp08gAZspIZR+HzqtNQoxYuwRvqbb7Wmt6pqgz
      rx2yOeBnIoa7QnYS5bB9w9CCKem9E4Dzx4/kL/ppoeUMPQKSB+4fIrthDX15elBq
      CFGuOzmu2RK85mWewA9YfPMQPz1mGNa5sbJo79QuQ5eAVB3uSHT6hQRwgtRtA2nU
      g8CWxtrmlaP0HVkPqp8x0Lb00yZ+NdgBuW58jQIDAQABAoIBAEbOo9osB5PSTGvJ
      J4U0crJ3Ksv5Akb1viOf2tmaApUtc1wQANW1R/aoBN1kbo7cXwvXA6m2VHLPS0/A
      PSo60DmWazdEqZEtdpxZwLus07nnRrfJpgrW69vY1prbe4Zxf9UdJuI7ClfPLAF/
      7dGh/l02HEt4VvOBi38UhbjuC8eLcjmw6lL9L1ZdJ1PJyLIWjsm/hg0cGk223nwi
      NIY4qdC6ZC1aJmo0QUiUMdV3UTHzVPk1fSR9Ad3rwaDh0tq/fYC4agrdWypYwtVA
      uVPjhFPOsu+s2E1qTlWa0weP4voNKEK7hqIiFjKEwyIs+rS6AU4D/0xO6EqE647R
      ADTW90ECgYEA9JThtMiz6JwKehf2JsoqY3FjIpwxLitaQJoBQAL4HKay89zLfVXt
      mOB877spspjmfw4FapOrdXeYhsI5g1eLdKXV/nLjE85T2lnXeczBh8NBDhYq2AhG
      3toTMpEaQkbVKegdYUA6DwOqbPw7D3Wq21zswPJmOCE6HXCs6Rog1dkCgYEA4v14
      orJaWbaSHoMS+pgIS42vfCrHaePkKcTvE6PkzTC+ukb/hyVba/72jUzN7ETTAE1+
      Jo2s9wxZf8y6UE5jMa9XTL6H1qOjr/78Ay7XwM7vKnAWyDA+ktFnZXyT2AZBIXdH
      Q/y3K8EMX2MwUW7L375bHSR+AC1mBjtW5Sf8p9UCgYEAybR+77kVpiAKA+b++b6A
      dsJsH37wkELwi5Z2sXPBat+Pdc4Bg7v51rpMTujr2n5+mQnXLa3bGWUoRPqos8jf
      GbQqZ04YN51RSiINskVK1cwROqzNaJxq1h7C9lD0dvQzl/v1Pt7ZAsjjJD5f9r/z
      yDU6i2VdJ60/YEgsUZFawwECgYB+sH3+QJFQ9SdExF95YhVvJdtF8BJwtXMJJRNS
      4Oy44XXyPeIsqdsGwb0WTEG6lwc1agr4taZOFKR3QerTG40dlAGjocvrLlYTyrsZ
      g7GDuXufMgRlIxgplZqh+BAESCld5lbuSURqtUqUiqXTLYW4kWQFNfLlYnFJFSGA
      sPrBKQKBgEH6ORjHTdbX6Vi5KnP2lxZZvbGcNvloe+2OF/5dOaJYsYLSwTmrE7UW
      6qI9ylxogWdIemVooTh2HsK4fzdS2cS/Sa8pg8TC08glSWRiX/eU94pAerXN0iIc
      kldmRy8cUhMsxF1YXOAUENnSatZhb9ANR1C7lrSW/3QzWrhhKk1y
      -----END RSA PRIVATE KEY-----
  - path: "/tmp/ca.pem"
    owner: "root"
    content: |
      -----BEGIN CERTIFICATE-----
      MIIC9zCCAd+gAwIBAgIJAN/iBfoi5N44MA0GCSqGSIb3DQEBCwUAMBIxEDAOBgNV
      BAMMB2t1YmUtY2EwHhcNMTYwMzI5MTEzMDQ3WhcNNDMwODE1MTEzMDQ3WjASMRAw
      DgYDVQQDDAdrdWJlLWNhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
      2N2ZpeNClp83XoIoOfOzOkkjL+BlEbsBnpdYz/CkCXnF+FXpDNOWMSWVlmZQMkhh
      Jebexf/uHaq/dMjbrwd4hwfJOe1MeGQ0qYGtCV/Shcpcrw7I/yBPeOnxvE9rezb9
      FpNMJ1wai7Tp08gAZspIZR+HzqtNQoxYuwRvqbb7Wmt6pqgzrx2yOeBnIoa7QnYS
      5bB9w9CCKem9E4Dzx4/kL/ppoeUMPQKSB+4fIrthDX15elBqCFGuOzmu2RK85mWe
      wA9YfPMQPz1mGNa5sbJo79QuQ5eAVB3uSHT6hQRwgtRtA2nUg8CWxtrmlaP0HVkP
      qp8x0Lb00yZ+NdgBuW58jQIDAQABo1AwTjAdBgNVHQ4EFgQUeja+TwOPKVdKQBAB
      KP2FquPxs5YwHwYDVR0jBBgwFoAUeja+TwOPKVdKQBABKP2FquPxs5YwDAYDVR0T
      BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAmyd+JiuepKKra+s+3bkSMSflzBNQ
      jcGCLzH252mJmyrplM7AcMYpLkMMs4i+xzeb5Xhaac8MXa/6ITxoFLuHjNWdBLkB
      juLb1cQqeyP68diH/GGVHGMZJYzoGp4bhJq2slJn8ZrewclnBgJlkYFh1fGazEYY
      3j0KuqMTQnrpAFDoGyuF2UGMKaWULfBHV9BzAg7hvIz6s6V0d6a3qo8tQAlV3JHl
      yd9yyEPw7sIsooZKqmwpGs4Alw5hOcsq7JAEOYYzUythD4dn4aVR/cE7s/4zVG3b
      Rl8zICVsO8et5XDkspKRoa1UYx31tnKN9XnH7du9c3M6KzS5z9IvnTekSQ==
      -----END CERTIFICATE-----
  - path: "/tmp/generate-tls.sh"
    owner: "root"
    permissions: "0700"
    content: |
      #!/bin/bash
      set -x
      SSL_TMP_DIR=/tmp/ssl
      mkdir -p $${SSL_TMP_DIR}
      cp /tmp/ca-key.pem $${SSL_TMP_DIR}/
      cp /tmp/ca.pem  /etc/ssl/certs/
      cp /tmp/ca.pem $${SSL_TMP_DIR}/
      cp /tmp/worker-openssl.cnf $${SSL_TMP_DIR}/
      source /etc/instance.env
      openssl genrsa -out $${SSL_TMP_DIR}/worker-key.pem 2048
      WORKER_IP="$${PRIVATE_IP}" openssl req -new -key $${SSL_TMP_DIR}/worker-key.pem -out $${SSL_TMP_DIR}/worker.csr -subj "/CN=$${PRIVATE_DNS}" -config $${SSL_TMP_DIR}/worker-openssl.cnf
      WORKER_IP="$${PRIVATE_IP}" openssl x509 -req -in $${SSL_TMP_DIR}/worker.csr -CA $${SSL_TMP_DIR}/ca.pem -CAkey $${SSL_TMP_DIR}/ca-key.pem -CAcreateserial -out $${SSL_TMP_DIR}/worker.pem -days 365 -extensions v3_req -extfile $${SSL_TMP_DIR}/worker-openssl.cnf
      mkdir -p /etc/kubernetes
      mv $${SSL_TMP_DIR} /etc/kubernetes/ssl
  - path: "/tmp/install.sh"
    owner: "root"
    permissions: "0700"
    content: |
      #!/bin/bash
      set -x
      mkdir -p /etc/kubernetes/manifests
      cat <<EOF > /etc/kubernetes/manifests/kube-proxy.yaml
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-proxy
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-proxy
          image: quay.io/coreos/hyperkube:v1.5.0_coreos.0
          command:
          - /hyperkube
          - proxy
          - --master=https://kubernetes
          - --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml
          - --proxy-mode=iptables
          securityContext:
            privileged: true
          volumeMounts:
            - mountPath: /etc/ssl/certs
              name: "ssl-certs"
            - mountPath: /etc/kubernetes/worker-kubeconfig.yaml
              name: "kubeconfig"
              readOnly: true
            - mountPath: /etc/kubernetes/ssl
              name: "etc-kube-ssl"
              readOnly: true
        volumes:
          - name: "ssl-certs"
            hostPath:
              path: "/usr/share/ca-certificates"
          - name: "kubeconfig"
            hostPath:
              path: "/etc/kubernetes/worker-kubeconfig.yaml"
          - name: "etc-kube-ssl"
            hostPath:
              path: "/etc/kubernetes/ssl"
      EOF
      cat <<EOF > /etc/kubernetes/worker-kubeconfig.yaml
      apiVersion: v1
      kind: Config
      clusters:
      - name: local
        cluster:
          certificate-authority: /etc/kubernetes/ssl/ca.pem
      users:
      - name: kubelet
        user:
          client-certificate: /etc/kubernetes/ssl/worker.pem
          client-key: /etc/kubernetes/ssl/worker-key.pem
      contexts:
      - context:
          cluster: local
          user: kubelet
        name: kubelet-context
      current-context: kubelet-context
      EOF

manage_etc_hosts: "localhost"

coreos:
  etcd2:
    listen-client-urls: http://0.0.0.0:2379
    proxy: on
  update:
    group: beta
    reboot-strategy: "off"
  fleet:
    metadata: "role=kubernetes-node,project=poseidon,env=${env}"
  units:
    - name: format-var-lib-docker.service
      command: start
      content: |
        [Unit]
        Before=docker.service var-lib-docker.mount
        ConditionPathExists=!/var/lib/docker.btrfs
        [Service]
        Type=oneshot
        ExecStart=/usr/sbin/wipefs -f /dev/xvdb
        ExecStart=/usr/sbin/mkfs.btrfs -f /dev/xvdb
    - name: var-lib-docker.mount
      enable: true
      content: |
        [Unit]
        Before=flanneld.service
        After=format-var-lib-docker.service
        Requires=format-var-lib-docker.service
        [Install]
        RequiredBy=docker.service
        [Mount]
        What=/dev/xvdb
        Where=/var/lib/docker
        Type=btrfs
        Options=loop,discard
    - name: etcd2.service
      command: stop
    - name: etcd-peers.service
      command: start
      content: |
        [Unit]
        Description=Write a file with the etcd peers that we should bootstrap to
        [Service]
        Restart=on-failure
        RestartSec=10
        ExecStartPre=/usr/bin/docker pull cncommerce/etcd-aws-cluster:latest
        ExecStartPre=/usr/bin/docker run -e PROXY_ASG=${proxy_asg} --rm=true -v /etc/sysconfig/:/etc/sysconfig/ cncommerce/etcd-aws-cluster:latest
        ExecStart=/usr/bin/systemctl start etcd2
    - name: fleet.service
      command: start
    - name: flanneld.service
      drop-ins:
        - name: 40-ExecStartPre-symlink.conf
          content: |
            [Service]
            ExecStartPre=/usr/bin/ln -sf /etc/flannel/options.env /run/flannel/options.env
    # Start flannel before Docker
    - name: docker.service
      command: start
      drop-ins:
        - name: 40-flannel.conf
          content: |
            [Unit]
            After=flanneld.service
    # Create hostname-var
    - name: hostname-var.service
      command: start
      content: |
        [Unit]
        Description=Create Hostname Var
        Requires=docker.service
        After=docker.service

        [Service]
        ExecStart=/usr/bin/sh -c "/usr/bin/echo HOSTNAME=$(hostname) >> /etc/hostname-var"
        RemainAfterExit=yes
        Type=oneshot
    - name: instance-env.service
      command: start
      content: |
        [Unit]
        Description=Retrieve instance environment
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/bash -c /tmp/setup-instance-env.sh
    - name: tls-setup.service
      command: start
      content: |
        [Unit]
        Requires=instance-env.service
        After=instance-env.service
        [Service]
        Type=oneshot
        EnvironmentFile=/etc/instance.env
        Environment="HOME=/tmp"
        ExecStart=/usr/bin/bash -c /tmp/generate-tls.sh
    - name: install-k8s.service
      command: start
      content: |
        [Unit]
        Requires=tls-setup.service
        After=tls-setup.service
        [Service]
        Type=oneshot
        EnvironmentFile=/etc/kubernetes.env
        EnvironmentFile=/etc/instance.env
        ExecStart=/usr/bin/bash -c /tmp/install.sh
    # Configure Kubelet service
    - name: kubelet.service
      command: start
      enable: true
      content: |
        [Service]
        Requires=hostname-var.service
        After=hostname-var.service
        EnvironmentFile=/etc/hostname-var
        ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/usr/bin/mkdir -p /var/log/containers
        Environment=KUBELET_VERSION=v1.5.0_coreos.0
        Environment="RKT_OPTS=--volume var-log,kind=host,source=/var/log \
          --mount volume=var-log,target=/var/log \
          --volume dns,kind=host,source=/etc/resolv.conf \
          --mount volume=dns,target=/etc/resolv.conf"
        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=https://kubernetes \
          --register-node=true \
          --allow-privileged=true \
          --node-labels="core=true" \
          --config=/etc/kubernetes/manifests \
          --hostname-override=$${HOSTNAME} \
          --cluster-dns=${kubernetes_dns_service_ip} \
          --cluster-domain=cluster.local \
          --kubeconfig=/etc/kubernetes/worker-kubeconfig.yaml \
          --tls-cert-file=/etc/kubernetes/ssl/worker.pem \
          --tls-private-key-file=/etc/kubernetes/ssl/worker-key.pem \
          --cadvisor-port=4194 \
          --cloud-provider=aws
        Restart=always
        RestartSec=10
        [Install]
        WantedBy=multi-user.target

    # Configure Etcd Apps
    - name: etcdreg.service
      command: start
      enable: true
      content: |
        [Service]
        Requires=hostname-var.service
        After=hostname-var.service
        EnvironmentFile=/etc/hostname-var
        EnvironmentFile=/etc/instance.env
        ExecStart=/bin/sh -c "/usr/bin/etcdctl mkdir kubelb; /usr/bin/etcdctl mk /kubelb/$${HOSTNAME} $${PRIVATE_IP}"
        Restart=always
        RestartSec=10
        [Install]
        WantedBy=multi-user.target
