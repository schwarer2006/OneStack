#!/bin/bash
#
# Change Ubuntu hostname (supports modern versions with hostnamectl)
# Author: Erik Schwarz
#
# Usage: ./hostname.sh [fqdn]
# If fqdn is not provided, user will be prompted
#

# Prüfe Root-Rechte
if [[ $EUID -ne 0 ]]; then
    echo "Fehler: Dieses Skript muss mit root-Rechten ausgeführt werden."
    exit 1
fi

# FQDN von der Kommandozeile oder per Eingabe abfragen
if [ "$#" -eq 0 ]; then
    read -p "Neuen vollständigen Hostnamen eingeben (FQDN): " FQDN
else
    FQDN=$1
fi

# FQDN validieren (einfacher Regex-Check)
if ! [[ "$FQDN" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    echo "Fehler: Ungültiger Hostname. Nur Buchstaben, Zahlen, Punkte und Bindestriche sind erlaubt."
    exit 1
fi

# Aktuellen und neuen Hostnamen setzen
OLDHOST=$(hostname)
NEWHOST="${FQDN%%.*}"

# /etc/hosts aktualisieren
sed -i "s/127\.0\.1\.1.*/127.0.1.1\t$FQDN\t$NEWHOST/" /etc/hosts

# /etc/hostname direkt überschreiben (sicherer als `sed`)
echo "$NEWHOST" > /etc/hostname

# Hostnamen sofort ändern
hostnamectl set-hostname "$FQDN"

# Hostnamen-Dienst neustarten, damit die Änderung sofort übernommen wird
systemctl restart systemd-hostnamed

echo "Hostnamen geändert: $OLDHOST → $FQDN"
exit 0
