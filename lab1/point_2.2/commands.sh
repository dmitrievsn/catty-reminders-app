wget -qO- https://gist.github.com/lawrenceching/41244a182307940cc15b45e3c4997346/raw/0576ea85d898c965c3137f7c38f9815e1233e0d1/install-frp-as-systemd-service.sh | sudo bash

PROXY=course.prafdin.ru
TOKEN=devops
ID=dmitriev

sudo tee /etc/frp/frpc.toml > /dev/null <<EOF3
serverAddr = "$PROXY"
serverPort = 7000
auth.method = "token"
auth.token = "$TOKEN"
[[proxies]]
name = "hook-$ID"
type = "http"
localPort = 8080
customDomains = ["webhook.$ID.$PROXY"]
[[proxies]]
name = "app-$ID"
type = "http"
localPort = 8181
customDomains = ["app.$ID.$PROXY"]
EOF3

sudo systemctl start frpc

echo "Адрес для проверки: webhook.$ID.$PROXY"
wget -qO- https://gist.githubusercontent.com/prafdin/b9ff40c8bc6dc8c55ca7ac911e278ecc/raw/ea80e83e6a36220e2e9ccdaca8fde49ee888f2ab/main.py | python3
