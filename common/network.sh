write /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com 8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
Domains=~.
LLMNR=no
MulticastDNS=no
DNSOverTLS=opportunistic
EOF

write /etc/systemd/system/resolvconf.service << EOF
[Unit]
Description=Link systemd-resolved stub-resolv.conf to /etc/resolv.conf

[Install]
WantedBy=systemd-resolved.service

[Service]
Type=oneshot
ExecStart=/usr/bin/ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
EOF

write /etc/hostname "$HOST_NAME"
run systemctl enable systemd-resolved.service resolvconf.service
