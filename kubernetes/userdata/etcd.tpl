#cloud-config

write_files:
  - path: /etc/systemd/system/etcd2.service.d/30-etcd_peers.conf
    permissions: 0644
    content: |
      [Service]
      # Load the other hosts in the etcd leader autoscaling group from file
      EnvironmentFile=/etc/sysconfig/etcd-peers

coreos:
  etcd2:
    advertise-client-urls: http://$private_ipv4:2379
    initial-advertise-peer-urls: http://$private_ipv4:2380
    listen-client-urls: http://0.0.0.0:2379
    listen-peer-urls: http://$private_ipv4:2380
  update:
    group: beta
    reboot-strategy: "etcd-lock"
  fleet:
    metadata: "role=etcd,project=poseidon,env=${env}"
  units:

    - name: etcd-peers.service
      command: start
      content: |
        [Unit]
        Description=Write a file with the etcd peers that we should bootstrap to
        [Service]
        Restart=on-failure
        RestartSec=10
        ExecStartPre=/usr/bin/docker pull monsantoco/etcd-aws-cluster:latest
        ExecStartPre=/usr/bin/docker run --rm=true -v /etc/sysconfig/:/etc/sysconfig/ cncommerce/etcd-aws-cluster:latest
        ExecStart=/usr/bin/systemctl start etcd2

    - name: fleet.service
      command: start
    - name: etcd2.service
      command: start
