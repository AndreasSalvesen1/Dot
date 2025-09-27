#!/bin/bash

SKRIPT_KATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MILJO_KATALOG="$SKRIPT_KATALOG/../.env"

if [[ ! -d "$MILJO_KATALOG" ]]; then
  exit 1
fi

if [[ -f "$MILJO_KATALOG/HOST.txt" ]]; then
  TAILSCALE_VERT=$(cat "$MILJO_KATALOG/HOST.txt" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
  exit 1
fi

if [[ -f "$MILJO_KATALOG/USER.txt" ]]; then
  BRUKER=$(cat "$MILJO_KATALOG/USER.txt" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
else
  exit 1
fi

if [[ -f "$MILJO_KATALOG/RPI_PRIVATE.txt" ]]; then
  PRIVAT_NOKKELFIL="$MILJO_KATALOG/RPI_PRIVATE.txt"
else
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
    return 1
  fi

  if ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh
  fi

  sudo tailscale up --authkey="$TS_AUTH_TOKEN"
  return $?
}

bestem_vert() {
  if command -v tailscale >/dev/null 2>&1; then
    if tailscale status >/dev/null 2>&1; then
      if ping -c 1 -W 2 "$TAILSCALE_VERT" >/dev/null 2>&1; then
        return 0
      fi
    else
      if [[ -n "$TS_AUTH_TOKEN" ]]; then
        if sett_opp_tailscale; then
          if ping -c 1 -W 2 "$TAILSCALE_VERT" >/dev/null 2>&1; then
            return 0
          fi
        fi
      fi
    fi
  else
    if [[ -n "$TS_AUTH_TOKEN" ]]; then
      if sett_opp_tailscale; then
        if ping -c 1 -W 2 "$TAILSCALE_VERT" >/dev/null 2>&1; then
          return 0
        fi
      fi
    fi
  fi

  if ping -c 1 -W 2 "$LOKAL_VERT" >/dev/null 2>&1; then
    return 1
  else
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
    exit 1
    ;;
esac

ssh -i "$TEMP_NOKKEL" \
  -o LogLevel=ERROR \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "$BRUKER@$VERT"

SSH_AVSLUTNINGSKODE=$?
if [ $SSH_AVSLUTNINGSKODE -ne 0 ]; then
  if [[ -f "$MILJO_KATALOG/RPI_PUBLIC.txt" ]]; then
    cat "$MILJO_KATALOG/RPI_PUBLIC.txt" >/dev/null
  fi
fi
