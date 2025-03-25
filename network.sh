#!/bin/bash
# Netzwerk-Konfigurationsskript für Ubuntu (mit Netplan-Unterstützung)
# Autor: Erik Schwarz , modifiziert für Netplan und bessere Fehlerbehandlung

# Prüfe, ob das Skript als Root ausgeführt wird
if [[ $EUID -ne 0 ]]; then
    echo "Dieses Skript muss als root/sudo ausgeführt werden."
    exit 1
fi

# Prüfe die Anzahl der Parameter
if [ $# -lt 2 ]; then
    echo "Usage: $0 <interface> <static|dhcp> [IP-Adresse]"
    exit 1
fi

# Setze Variablen
IFNAME=$1
IFTYPE=$2
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"

# Prüfe, ob die Netzwerkschnittstelle existiert
if ! ip link show "$IFNAME" &>/dev/null; then
    echo "Fehler: Schnittstelle $IFNAME existiert nicht."
    exit 1
fi

# Prüfe, ob der Benutzer eine statische Adresse konfiguriert
if [ "$IFTYPE" == "static" ]; then
    if [ $# -ne 3 ]; then
        echo "Fehler: Bei einer statischen Konfiguration muss eine IP-Adresse angegeben werden."
        exit 1
    fi
    IFADDRESS=$3

    # Prüfe, ob die IP-Adresse gültig ist
    if ! [[ "$IFADDRESS" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Fehler: Ungültige IP-Adresse $IFADDRESS."
        exit 1
    fi

    # Schreibe die neue Netplan-Konfiguration
    cat > "$NETPLAN_CONFIG" <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFNAME:
      addresses:
        - $IFADDRESS/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
EOL

elif [ "$IFTYPE" == "dhcp" ]; then
    cat > "$NETPLAN_CONFIG" <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFNAME:
      dhcp4: true
EOL
else
    echo "Fehler: Ungültiger Typ. Verwende 'static' oder 'dhcp'."
    exit 1
fi

# Anwenden der Netzwerkkonfiguration
netplan apply

echo "Netzwerkkonfiguration für $IFNAME erfolgreich aktualisiert."
