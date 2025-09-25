#!/bin/bash

SKRIPT_KATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MILJO_KATALOG="$SKRIPT_KATALOG/../.env"

if [[ ! -d "$MILJO_KATALOG" ]]; then
    echo "Feil: .env katalog ikke funnet på $MILJO_KATALOG"
    exit 1
fi

if [[ -f "$MILJO_KATALOG/HOST.txt" ]]; then
    TAILSCALE_VERT=$(cat "$MILJO_KATALOG/HOST.txt" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
    echo "Feil: HOST.txt ikke funnet i .env katalog"
    exit 1
fi

if [[ -f "$MILJO_KATALOG/USER.txt" ]]; then
    BRUKER=$(cat "$MILJO_KATALOG/USER.txt" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
    echo "Feil: USER.txt ikke funnet i .env katalog"
    exit 1
fi

if [[ -f "$MILJO_KATALOG/RPI_PRIVATE.txt" ]]; then
    PRIVAT_NOKKELFIL="$MILJO_KATALOG/RPI_PRIVATE.txt"
else
    echo "Feil: RPI_PRIVATE.txt ikke funnet i .env katalog"
    exit 1
fi

TS_AUTH_TOKEN=""
if [[ -f "$MILJO_KATALOG/TS_AUTH.txt" ]]; then
    TS_AUTH_TOKEN=$(cat "$MILJO_KATALOG/TS_AUTH.txt" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

LOKAL_VERT="10.0.0.99"

TEMP_NOKKEL=$(mktemp)
cp "$PRIVAT_NOKKELFIL" "$TEMP_NOKKEL"
chmod 600 "$TEMP_NOKKEL"

rydd_opp() {
    rm -f "$TEMP_NOKKEL"
}

trap rydd_opp EXIT

sett_opp_tailscale() {
    if [[ -z "$TS_AUTH_TOKEN" ]]; then
        echo "Ingen Tailscale auth token funnet i TS_AUTH.txt"
        echo "Kjør: sudo tailscale up"
        return 1
    fi
    
    echo "Setter opp Tailscale med auth token..."
    if ! command -v tailscale >/dev/null 2>&1; then
        echo "Tailscale ikke installert. Installerer..."
        curl -fsSL https://tailscale.com/install.sh | sh
    fi
    
    sudo tailscale up --authkey="$TS_AUTH_TOKEN"
    return $?
}

bestem_vert() {
    echo "Finner beste tilkoblingsmetode..."
    
    if command -v tailscale >/dev/null 2>&1; then
        if tailscale status >/dev/null 2>&1; then
            echo "Tailscale kjører"
            if ping -c 1 -W 2 "$TAILSCALE_VERT" >/dev/null 2>&1; then
                echo "Tailscale vert $TAILSCALE_VERT er tilgjengelig"
                return 0
            else
                echo "Tailscale vert $TAILSCALE_VERT er ikke tilgjengelig"
            fi
        else
            echo "Tailscale er installert men kjører ikke"
            if [[ -n "$TS_AUTH_TOKEN" ]]; then
                echo "Forsøker å starte Tailscale med auth token..."
                if sett_opp_tailscale; then
                    if ping -c 1 -W 2 "$TAILSCALE_VERT" >/dev/null 2>&1; then
                        echo "Tailscale oppsett vellykket, vert tilgjengelig"
                        return 0
                    fi
                fi
            fi
        fi
    else
        echo "Tailscale ikke installert"
        if [[ -n "$TS_AUTH_TOKEN" ]]; then
            echo "Installerer og setter opp Tailscale..."
            if sett_opp_tailscale; then
                if ping -c 1 -W 2 "$TAILSCALE_VERT" >/dev/null 2>&1; then
                    echo "Tailscale oppsett vellykket, vert tilgjengelig"
                    return 0
                fi
            fi
        fi
    fi
    
    echo "Faller tilbake til lokalt nettverk"
    if ping -c 1 -W 2 "$LOKAL_VERT" >/dev/null 2>&1; then
        echo "Lokal vert $LOKAL_VERT er tilgjengelig"
        return 1
    else
        echo "Lokal vert $LOKAL_VERT er ikke tilgjengelig"
        return 2
    fi
}

bestem_vert
VERT_RESULTAT=$?

case $VERT_RESULTAT in
    0)
        VERT="$TAILSCALE_VERT"
        TILKOBLINGSTYPE="Tailscale"
        ;;
    1)
        VERT="$LOKAL_VERT"
        TILKOBLINGSTYPE="Local Network"
        ;;
    2)
        echo "Feil: Kan ikke nå Raspberry Pi via Tailscale eller lokalt nettverk"
        echo "Sørg for at:"
        echo "1. Raspberry Pi er påslått"
        echo "2. Du er koblet til samme lokale nettverk, eller"
        echo "3. Tailscale er riktig konfigurert på begge enheter"
        exit 1
        ;;
esac

echo
echo "Kobler til Raspberry Pi via $TILKOBLINGSTYPE..."
echo "Vert: $VERT"
echo "Bruker: $BRUKER"
echo "Bruker privat nøkkel fra: $PRIVAT_NOKKELFIL"
echo

ssh -i "$TEMP_NOKKEL" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$BRUKER@$VERT"

SSH_AVSLUTNINGSKODE=$?
if [ $SSH_AVSLUTNINGSKODE -ne 0 ]; then
    echo
    echo "SSH tilkobling feilet (avslutningskode: $SSH_AVSLUTNINGSKODE)"
    echo
    echo "Dette kan være på grunn av:"
    echo "1. Den offentlige nøkkelen er ikke i ~/.ssh/authorized_keys på Raspberry Pi"
    echo "2. SSH tjenesten kjører ikke på Raspberry Pi" 
    echo "3. Brukeren '$BRUKER' eksisterer ikke på Raspberry Pi"
    if [[ "$TILKOBLINGSTYPE" == "Tailscale" ]]; then
        echo "4. Tailscale tilkoblingsproblemer"
    else
        echo "4. Lokale nettverks tilkoblingsproblemer"
    fi
    echo
    echo "Feilsøkingssteg:"
    echo "1. Sjekk SSH tjeneste: sudo systemctl status ssh (på Pi)"
    if [[ "$TILKOBLINGSTYPE" == "Tailscale" ]]; then
        echo "2. Sjekk Tailscale: tailscale status (på begge maskiner)"
        echo "3. Prøv lokalt nettverk: ping $LOKAL_VERT"
    else
        echo "2. Sjekk lokalt nettverk: ping $LOKAL_VERT"
        echo "3. Prøv Tailscale hvis tilgjengelig: ping $TAILSCALE_VERT"
    fi
    echo "4. Bekreft bruker eksisterer: id $BRUKER (på Pi)"
    echo
    echo "Offentlig nøkkel innhold (legg dette til ~/.ssh/authorized_keys på Pi):"
    if [[ -f "$MILJO_KATALOG/RPI_PUBLIC.txt" ]]; then
        echo "----------------------------------------"
        cat "$MILJO_KATALOG/RPI_PUBLIC.txt"
        echo "----------------------------------------"
    fi
fi