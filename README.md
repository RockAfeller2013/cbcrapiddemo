```mermaid
flowchart TB
    User["User (Browser / SSH)"]

    subgraph Host["Docker VM Host (192.168.1.37)"]
        Portainer["Portainer\n:9443 / :9000"]
        Guac["Apache Guacamole\n(VNC Gateway)"]
        Caldera["Caldera Server\n:8888 / :7010-7012"]
        Kali["Kali Container\nSSH :2222"]
        
        subgraph Net["Docker Network: my-net2 (bridge)"]
            Win1["Windows 11 #1\nCBC + SandCat"]
            Win2["Windows 11 #2\nCBC + SandCat"]
            CalderaNet["caldera-server\nDNS: caldera-server.my-net2"]
            KaliNet["kali-rolling"]
        end
    end

    Internet["Internet\n(Carbon Black Cloud)"]
    LAN["Local LAN\n(192.168.1.0/24)"]

    User -->|HTTPS :9443| Portainer
    User -->|HTTP :8888| Caldera
    User -->|VNC via Guac| Guac
    User -->|SSH :2222| Kali

    Win1 <-->|Agent comms| CalderaNet
    Win2 <-->|Agent comms| CalderaNet
    KaliNet <-->|Red team ops| Win1
    KaliNet <-->|Red team ops| Win2

    Win1 -->|HTTPS 443| Internet
    Win2 -->|HTTPS 443| Internet

    Win1 -. BLOCK .-> LAN
    Win2 -. BLOCK .-> LAN
    KaliNet -. BLOCK .-> LAN
    CalderaNet -. BLOCK .-> LAN
