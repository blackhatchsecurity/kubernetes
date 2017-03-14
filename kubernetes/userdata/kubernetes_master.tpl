#cloud-config

write_files:
  #  Setup flannel for kubernetes networking
  - path: /etc/flannel/options.env
    content: |
      FLANNELD_IFACE=$private_ipv4
      FLANNELD_ETCD_ENDPOINTS=http://127.0.0.1:2379
  # WUPIAO BITCH!!!
  - path: /opt/bin/wupiao
    permissions: '0755'
    content: |
      #!/bin/bash
      # [w]ait [u]ntil [p]ort [i]s [a]ctually [o]pen
      [ -n "$1" ] && \
        until curl -o /dev/null -sIf http://$${1}; do \
          sleep 1 && echo .;
        done;
      exit $?
  - path: /etc/systemd/system/etcd2.service.d/30-etcd_peers.conf
    permissions: 0644
    content: |
      [Service]
      # Load the other hosts in the etcd leader autoscaling group from file
      EnvironmentFile=/etc/sysconfig/etcd-peers
  # kube-apiserver pod
  - path: /etc/kubernetes/manifests/apiserver.yaml
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: apiserver
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: apiserver
          image: quay.io/coreos/hyperkube:v1.5.0_coreos.0
          command:
          - /hyperkube
          - apiserver
          - --bind-address=0.0.0.0
          - --etcd-servers=http://127.0.0.1:2379
          - --allow-privileged=true
          - --service-cluster-ip-range=${kubernetes_service_ip_range}
          - --secure-port=443
          - --advertise-address=$private_ipv4
          - --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota
          - --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem
          - --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
          - --client-ca-file=/etc/kubernetes/ssl/ca.pem
          - --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem
          - --cloud-provider=aws
          - --runtime-config=extensions/v1beta1/deployments=true,extensions/v1beta1/daemonsets=true
          ports:
          - containerPort: 443
            hostPort: 443
            name: https
          - containerPort: 8080
            hostPort: 8080
            name: local
          volumeMounts:
          - mountPath: /etc/kubernetes/ssl
            name: ssl-certs-kubernetes
            readOnly: true
          - mountPath: /etc/ssl/certs
            name: ssl-certs-host
            readOnly: true
        volumes:
        - hostPath:
            path: /etc/kubernetes/ssl
          name: ssl-certs-kubernetes
        - hostPath:
            path: /usr/share/ca-certificates
          name: ssl-certs-host
  # kube-proxy pod
  - path: /etc/kubernetes/manifests/proxy.yaml
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: proxy
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: proxy
          image: quay.io/coreos/hyperkube:v1.5.0_coreos.0
          command:
          - /hyperkube
          - proxy
          - --master=http://127.0.0.1:8080
          - --proxy-mode=iptables
          securityContext:
            privileged: true
          volumeMounts:
          - mountPath: /etc/ssl/certs
            name: ssl-certs-host
            readOnly: true
        volumes:
        - hostPath:
            path: /usr/share/ca-certificates
          name: ssl-certs-host
  # kube-podmaster pod
  - path: /etc/kubernetes/manifests/podmaster.yaml
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: podmaster
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: scheduler-elector
          image: gcr.io/google_containers/podmaster:1.1
          command:
          - /podmaster
          - --etcd-servers=http://127.0.0.1:2379
          - --key=scheduler
          - --whoami=$private_ipv4
          - --source-file=/src/manifests/kube-scheduler.yaml
          - --dest-file=/dst/manifests/kube-scheduler.yaml
          volumeMounts:
          - mountPath: /src/manifests
            name: manifest-src
            readOnly: true
          - mountPath: /dst/manifests
            name: manifest-dst
        - name: controller-manager-elector
          image: gcr.io/google_containers/podmaster:1.1
          command:
          - /podmaster
          - --etcd-servers=http://127.0.0.1:2379
          - --key=controller
          - --whoami=$private_ipv4
          - --source-file=/src/manifests/kube-controller-manager.yaml
          - --dest-file=/dst/manifests/kube-controller-manager.yaml
          terminationMessagePath: /dev/termination-log
          volumeMounts:
          - mountPath: /src/manifests
            name: manifest-src
            readOnly: true
          - mountPath: /dst/manifests
            name: manifest-dst
        volumes:
        - hostPath:
            path: /srv/kubernetes/manifests
          name: manifest-src
        - hostPath:
            path: /etc/kubernetes/manifests
          name: manifest-dst
  # kube-controller-manager pod
  - path: /srv/kubernetes/manifests/kube-controller-manager.yaml
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-controller-manager
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-controller-manager
          image: quay.io/coreos/hyperkube:v1.5.0_coreos.0
          command:
          - /hyperkube
          - controller-manager
          - --master=http://127.0.0.1:8080
          - --service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
          - --root-ca-file=/etc/kubernetes/ssl/ca.pem
          - --cloud-provider=aws
          livenessProbe:
            httpGet:
              host: 127.0.0.1
              path: /healthz
              port: 10252
            initialDelaySeconds: 15
            timeoutSeconds: 1
          volumeMounts:
          - mountPath: /etc/kubernetes/ssl
            name: ssl-certs-kubernetes
            readOnly: true
          - mountPath: /etc/ssl/certs
            name: ssl-certs-host
            readOnly: true
        volumes:
        - hostPath:
            path: /etc/kubernetes/ssl
          name: ssl-certs-kubernetes
        - hostPath:
            path: /usr/share/ca-certificates
          name: ssl-certs-host
  # kube-scheduler pod
  - path: /srv/kubernetes/manifests/kube-scheduler.yaml
    content: |
      apiVersion: v1
      kind: Pod
      metadata:
        name: kube-scheduler
        namespace: kube-system
      spec:
        hostNetwork: true
        containers:
        - name: kube-scheduler
          image: quay.io/coreos/hyperkube:v1.5.0_coreos.0
          command:
          - /hyperkube
          - scheduler
          - --master=http://127.0.0.1:8080
          livenessProbe:
            httpGet:
              host: 127.0.0.1
              path: /healthz
              port: 10251
            initialDelaySeconds: 15
            timeoutSeconds: 1
  - path: /etc/kubernetes/skydns-svc.yaml
    content: |
      {"kind": "Service","apiVersion": "v1","metadata": {"name": "kube-dns","namespace": "kube-system","labels": {"k8s-app": "kube-dns","kubernetes.io/cluster-service": "true","kubernetes.io/name": "KubeDNS"}},"spec": {"ports": [{"name": "dns","protocol": "UDP","port": 53,"targetPort": 53},{"name": "dns-tcp","protocol": "TCP","port": 53,"targetPort": 53}],"selector": {"k8s-app": "kube-dns","version": "v17.1"},"clusterIP": "10.3.0.10","type": "ClusterIP","sessionAffinity": "None"}}
  - path: /etc/kubernetes/skydns-rc.yaml
    content: |
      {"kind": "ReplicationController","apiVersion": "v1","metadata": {"name": "kube-dns-v17.1","namespace": "kube-system","labels": {"k8s-app": "kube-dns","kubernetes.io/cluster-service": "true","version": "v17.1"}},"spec": {"replicas": 3,"selector": {"k8s-app": "kube-dns","version": "v17.1"},"template": {"metadata": {"labels": {"k8s-app": "kube-dns","kubernetes.io/cluster-service": "true","version": "v17.1"}},"spec": {"containers": [{"name": "kubedns","image": "gcr.io/google_containers/kubedns-amd64:1.5","args": ["--domain=cluster.local.","--dns-port=10053"],"ports": [{"name": "dns-local","containerPort": 10053,"protocol": "UDP"}, {"name": "dns-tcp-local","containerPort": 10053,"protocol": "TCP"}],"resources": {"limits": {"cpu": "100m","memory": "170Mi"},"requests": {"cpu": "100m","memory": "70Mi"}},"livenessProbe": {"httpGet": {"path": "/healthz","port": 8080,"scheme": "HTTP"},"initialDelaySeconds": 60,"timeoutSeconds": 5,"periodSeconds": 10,"successThreshold": 1,"failureThreshold": 5},"readinessProbe": {"httpGet": {"path": "/readiness","port": 8081,"scheme": "HTTP"},"initialDelaySeconds": 30,"timeoutSeconds": 5,"periodSeconds": 10,"successThreshold": 1,"failureThreshold": 3},"terminationMessagePath": "/dev/termination-log","imagePullPolicy": "IfNotPresent"}, {"name": "dnsmasq","image": "gcr.io/google_containers/kube-dnsmasq-amd64:1.3","args": ["--cache-size=1000","--no-resolv","--server=127.0.0.1#10053"],"ports": [{"name": "dns","containerPort": 53,"protocol": "UDP"}, {"name": "dns-tcp","containerPort": 53,"protocol": "TCP"}],"resources": {},"terminationMessagePath": "/dev/termination-log","imagePullPolicy": "IfNotPresent"}, {"name": "healthz","image": "gcr.io/google_containers/exechealthz-amd64:1.1","args": ["-cmd=nslookup kubernetes.default.svc.cluster.local 127.0.0.1 \u003e/dev/null","-port=8080","-quiet"],"ports": [{"containerPort": 8080,"protocol": "TCP"}],"resources": {"limits": {"cpu": "10m","memory": "50Mi"},"requests": {"cpu": "10m","memory": "50Mi"}},"terminationMessagePath": "/dev/termination-log","imagePullPolicy": "IfNotPresent"}],"restartPolicy": "Always","terminationGracePeriodSeconds": 30,"dnsPolicy": "Default","securityContext": {}}}}}

coreos:
  etcd2:
    listen-client-urls: "http://0.0.0.0:2379"
    proxy: on
  update:
    group: beta
    reboot-strategy: "off"
  fleet:
    metadata: "role=kubernetes-master,project=poseidon,env=${env}"
  units:
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
            ExecStartPre=/usr/bin/curl -X PUT -d "value={\"Network\":\"10.2.0.0/16\",\"Backend\":{\"Type\":\"vxlan\"}}" "http://127.0.0.1:2379/v2/keys/coreos.com/network/config"
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
    # Configure Kubelet service
    - name: kubelet.service
      command: start
      enable: true
      content: |
        [Service]
        Requires=hostname-var.service
        After=hostname-var.service
        ExecStartPre=/usr/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/usr/bin/mkdir -p /var/log/containers

        Environment=KUBELET_VERSION=v1.5.0_coreos.0
        Environment="RKT_OPTS=--volume var-log,kind=host,source=/var/log \
          --mount volume=var-log,target=/var/log \
          --volume dns,kind=host,source=/etc/resolv.conf \
          --mount volume=dns,target=/etc/resolv.conf"

        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=http://127.0.0.1:8080 \
          --register-schedulable=false \
          --allow-privileged=true \
          --config=/etc/kubernetes/manifests \
          --cloud-provider=aws \
          --cluster-dns=${kubernetes_dns_service_ip} \
          --cluster-domain=cluster.local \
          --cadvisor-port=4194 \
        Restart=always
        RestartSec=10
        [Install]
        WantedBy=multi-user.target

    # Create kube-system namespace
    - name: kube-system-ns.service
      command: start
      content: |
        [Unit]
        Description=Create kube-system Namespace
        Requires=kubelet.service
        After=kubelet.service

        [Service]
        ExecStartPre=/opt/bin/wupiao 127.0.0.1:8080
        ExecStart=/usr/bin/curl -H "Content-Type: application/json" -XPOST -d'{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"kube-system"}}' "http://127.0.0.1:8080/api/v1/namespaces"
        RemainAfterExit=yes
        Type=oneshot
    # Create kube-system SkyDNS
    - name: kube-system-skydns.service
      command: start
      content: |
        [Unit]
        Description=Create SkyDNS service
        Requires=kube-system-ns.service
        After=kube-system-ns.service

        [Service]
        ExecStartPre=/opt/bin/wupiao 127.0.0.1:8080
        ExecStart=/usr/bin/curl -H "Content-Type: application/json" -XPOST -d @/etc/kubernetes/skydns-svc.yaml "http://127.0.0.1:8080/api/v1/namespaces/kube-system/services"
        ExecStart=/usr/bin/curl -H "Content-Type: application/json" -XPOST -d @/etc/kubernetes/skydns-rc.yaml "http://127.0.0.1:8080/api/v1/namespaces/kube-system/replicationcontrollers"
        RemainAfterExit=yes
        Type=oneshot
