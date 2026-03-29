# Carbon Black Cloud - Rapid Demo / Proof of Concept or Proof of Value


- This docker compose file sets up a Carbon Black Cloud demo evnruonment using,  2xWindows 11 with Carbon Black Sensor and Caldera Sensor automatically installed, Apache Gucamole configred to access the Windows conatiners via VNC, a Kali container, Portainer for container visability and Caldera as a container all on the same Docker host.

This enables a rapid, automated, repeatable, and thorough demo to showcase lateral movement and the full capabilities of Carbon Black Cloud. This is also realativley safe to as it blocks access to the inernet accept CBC and your priviate LAB. But, if you dont know what you are doing, nothing is safe is it.. 

Includeds;

- 2 x Windows 11 with Carbon Black Sensor installed to your registration key and Caldera SandCat sensor.
- Portainer for container managment
- Caldera Container
- Kali Container (WIP) and Exploit
- Container Firewall rules to block all traffic to local network and only allow access to Carbon Black Cloud IPs
- Apache Guacamole (WIP)

-     Limitations: Copy and Paste is diffcult to do, Docker isn't really suitable for User GUI access.

[youtube demo link]

# Network Diagram

# Setup VMware Workstation with Debian VM

First, you need to setup a VM with Docker installed inside it, you can do this your self, this part isnt't documented here, I am using Proxmox as it is easier to use opensource and automatic script. You can also download VMware workstation and setup a Docker VM.

HowTo: Download VMware Workstation Pro and VMware Fusion Pro for FREE. - https://www.detectx.com.au/howto-download-vmware-workstation-pro-and-vmware-fusion-pro-for-free/

## Setup Docker VM

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/vm/docker-vm.sh)"
```

## Insall Docker inside Debian

```
# Update packages
sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Optional: run Docker without sudo
sudo usermod -aG docker "$USER"
newgrp docker

# Test
docker run hello-world
```

### Setup SSH into Docker VM

```
dpkg --configure -a
apt update && apt install -y openssh-server && mkdir -p /var/run/sshd && sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && /usr/sbin/sshd -D &
sudo passwd root

ssh-keygen -R 192.168.1.37

username: root
Password: root
```

```
apt intall -y curl
docker compose version || apt install -y docker-compose-plugin
```

## Block these containers from access your internal network, I doint care if it reachouts to the internet, you can update the rules to be more restrective if you wish.

- https://github.com/RockAfeller2013/proxmox_helperscripts/blob/main/docker/firewall.md


## Portainer
```
docker volume create portainer_data

docker run -d \
  --name portainer \
  --restart=always \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

https://192.168.1.37:9443/#!/init/admin

```
## Setu Container network called my-net2

```
docker network create my-net2
--network my-net2
docker run -it --network my-net2 ping web
```

## OEM Folder

- Create a OEM Folder and add the CBC Sensor and install.bat and update with your Sensor key and Windows Licensing if you wish. These files will be copied to the Windows machine automattaly and the install.bat will be excueted upon first boot of windows. 
- /sensor/installer_vista_win7_win8-64-4.1.0.5463.msi
- /install.bat - https://github.com/RockAfeller2013/proxmox_helperscripts/blob/main/docker/dockur/windows/oem/install.bat

## Windows 11

```
docker run -d   --network my-net2 --name windows7   -e "VERSION=11"   -p 8007:8006   --device=/dev/kvm   --device=/dev/net/tun   --cap-add NET_ADMIN   -v /root/oem:/oem  docker.io/dockurr/windows:latest
docker logs -f --tail 50 windows7

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' windows7

```
- Connect to windows7 via VNC http://192.168.1.37:8007

## Caldera

```
git clone https://github.com/mitre/caldera.git --recursive 
cd caldera

docker build --build-arg WIN_BUILD=true . -t caldera:server

docker run -d --network my-net2 \
  -p 7010:7010 \
  -p 7011:7011/udp \
  -p 7012:7012 \
  -p 8888:8888 \
  -v /root/caldera:/data \
  --name caldera-server \
  caldera:server \
  --insecure

docker logs -f caldera-server
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' caldera-server

# DNS is caldera-server.my-net2
```

- Access Caldera UI from host

```
Username: admin
Password: admin

http://192.168.1.37:8888

```
## Kali minmal headless 

```
bash <(curl -fsSL https://raw.githubusercontent.com/RockAfeller2013/proxmox_helperscripts/main/docker/kali/kalidockerbuild.sh)
ssh root@192.168.1.37 -p 2222
```
# Destroy and clean up 

```
docker rm -f windows7
docker rm -f caldera-server
docker rm -f kali-rolling && docker rmi -f kali-rolling-custom docker.io/kalilinux/kali-rolling && docker volume rm kali-data 

docker network rm my-net2
docker volume prune -f
docker system prune -a --volumes -f
docker image prune -a
docker system prune -a
docker system df

```

```mermaid
flowchart TB
    User["User (Browser / SSH)"]

    subgraph Host["Docker VM Host 192.168.1.37"]
        Portainer["Portainer\n9443 / 9000"]
        Guac["Apache Guacamole\nVNC Gateway"]
        Caldera["Caldera Server\n8888 / 7010-7012"]
        Kali["Kali Container\nSSH 2222"]
        
        subgraph Net["Docker Network my-net2 bridge"]
            Win1["Windows 11 #1\nCBC + SandCat"]
            Win2["Windows 11 #2\nCBC + SandCat"]
            CalderaNet["caldera-server\nDNS caldera-server.my-net2"]
            KaliNet["kali-rolling"]
        end
    end

    Internet["Internet\nCarbon Black Cloud"]
    LAN["Local LAN\n192.168.1.0/24"]

    User -->|HTTPS 9443 admin admin| Portainer
    User -->|HTTP 8888 admin admin| Caldera
    User -->|HTTPS 8443 guacadmin guacadmin| Guac
    User -->|SSH 2222 admin admin| Kali

    Win1 -->|Agent comms| CalderaNet
    CalderaNet -->|Agent comms| Win1

    Win2 -->|Agent comms| CalderaNet
    CalderaNet -->|Agent comms| Win2

    KaliNet -->|Red team ops| Win1
    Win1 -->|Red team ops| KaliNet

    KaliNet -->|Red team ops| Win2
    Win2 -->|Red team ops| KaliNet

    Win1 -->|HTTPS 443| Internet
    Win2 -->|HTTPS 443| Internet

    Win1 -. BLOCK .-> LAN
    Win2 -. BLOCK .-> LAN
    KaliNet -. BLOCK .-> LAN
    CalderaNet -. BLOCK .-> LAN

