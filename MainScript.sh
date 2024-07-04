#!/bin/bash
#Получаем внешние адреса хостов
echo "Enter Kalinigrad Ip Address:"
read kaliningrad
echo "Enter Vladivostok Ip Address:"
read vladivostok
#Создаём и перебрасываем ключи для хостов
ssh-keygen -t ecdsa -q -f ~/.ssh/id_ecdsa -N ""
ssh-copy-id -i ~/.ssh/id_ecdsa.pub user@$vladivostok
ssh user@$vladivostok 'ssh-keygen -t ecdsa -q -f ~/.ssh/id_ecdsa -N ""'
scp user@$vladivostok:/home/user/.ssh/id_ecdsa.pub ~/.ssh/id_ecdsanew.pub
cat ~/.ssh/id_ecdsanew.pub >> ~/.ssh/authorized_keys
#Устанавливаем зону
sudo timedatectl set-timezone Europe/Kaliningrad
ssh user@$vladivostok 'sudo timedatectl set-timezone Asia/Vladivostok'
#Получаем приватные адреса хостов
vladivostok_loc=$(ssh user@$vladivostok "ip addr show dev eth0" | grep -w inet | awk '{print $2}' | rev | cut -d '/' -f 2 | rev)
kaliningrad_loc=$(ip addr show dev eth0 | grep -w inet | awk '{print $2}' | rev | cut -d '/' -f 2 | rev)
#Создаём GRE туннель
sudo ip link add grelan type gretap local $kaliningrad_loc remote $vladivostok_loc
sudo ip link set grelan up
sudo ip addr add 192.168.0.1/24 dev grelan
ssh user@$vladivostok "sudo ip link add grelan type gretap local $vladivostok_loc remote $kaliningrad_loc"
ssh user@$vladivostok "sudo ip link set grelan up"
ssh user@$vladivostok "sudo ip addr add 192.168.0.2/24 dev grelan"
#Добавляем адреса в /etc/hosts
echo "$kaliningrad kaliningrad" | sudo tee -a /etc/hosts
echo "192.168.0.1 kaliningrad-grelan" | sudo tee -a /etc/hosts
echo "$vladivostok vladivostok" | sudo tee -a /etc/hosts
echo "192.168.0.2 vladivostok-grelan" | sudo tee -a /etc/hosts
ssh user@$vladivostok "echo \"$kaliningrad kaliningrad\" | sudo tee -a /etc/hosts"
ssh user@$vladivostok "echo \"192.168.0.1 kaliningrad-grelan\" | sudo tee -a /etc/hosts"
ssh user@$vladivostok "echo \"$vladivostok vladivostok\" | sudo tee -a /etc/hosts"
ssh user@$vladivostok "echo \"192.168.0.2 vladivostok-grelan\" | sudo tee -a /etc/hosts"
#Настраиваем NAT, проброс портов 
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2222 -j DNAT --to-destination 192.168.0.2:22
sudo iptables -t nat -A POSTROUTING -s 192.168.0.2 -o eth1 -j MASQUERADE
sudo sysctl net.ipv4.ip_forward=1
sudo sysctl -p
echo "200 custom" | sudo tee -a /etc/iproute2/rt_tables
sudo ip rule add from 192.168.0.1 lookup custom
sudo ip route add default via 192.168.0.2 dev grelan table custom metric 1
ssh user@$vladivostok "sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE"
ssh user@$vladivostok "sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2222 -j DNAT --to-destination 192.168.0.1:22"
ssh user@$vladivostok "sudo iptables -t nat -A POSTROUTING -s 192.168.0.1 -o eth1 -j MASQUERADE"
ssh user@$vladivostok "echo \"200 custom\" | sudo tee -a /etc/iproute2/rt_tables"
ssh user@$vladivostok "sudo ip rule add from 192.168.0.2 lookup custom"
ssh user@$vladivostok "sudo ip route add default via 192.168.0.1 dev grelan table custom metric 1"
ssh user@$vladivostok "sudo sysctl net.ipv4.ip_forward=1"
ssh user@$vladivostok "sudo sysctl -p"
#Скрипт пункта 8 уже в директории с текущим скриптом
