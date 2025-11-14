#!/usr/bin/env bash
set -euo pipefail

log() { echo "[webconfig] $*"; }

log "Iniciando provisionamento..."

# --- Instala Docker (idempotente) ---
if ! command -v docker >/dev/null 2>&1; then
  log "Instalando Docker..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release

  install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  fi

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable docker
  systemctl start docker || true
  # Adiciona usuário vagrant ao grupo docker (se existir)
  if id vagrant &>/dev/null; then
    usermod -aG docker vagrant || true
  fi
else
  log "Docker já instalado; pulando."
fi

# --- Instala Python e requests (idempotente) ---
if ! command -v python3 >/dev/null 2>&1; then
  log "Instalando Python3 e pip..."
  apt-get update -y
  apt-get install -y python3 python3-pip
fi

# Verifica se 'requests' já está disponível
if python3 - <<'EOF'
try:
    import requests
except ImportError:
    exit(1)
EOF
then
  log "Biblioteca requests já instalada; pulando."
else
  log "Instalando biblioteca requests via pip..."
  pip3 install --no-cache-dir requests
fi

log "Provisionamento concluído."