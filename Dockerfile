FROM kalilinux/kali-rolling

RUN apt update -y

# Kali rolling already updates the repo def with latest keys
RUN apt install -y \
  python3 \
  python3-pip \
  git \
  seclists \
  curl \
  dnsrecon \
  enum4linux \
  feroxbuster \
  gobuster \
  impacket-scripts \
  nbtscan \
  nikto \
  nmap \
  onesixtyone \
  oscanner \
  redis-tools \
  smbclient \
  smbmap \
  snmp \
  sslscan \
  sipvicious \
  tnscmd10g \
  whatweb

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:$PATH"

WORKDIR /app

COPY pyproject.toml poetry.lock* ./
RUN poetry config virtualenvs.create false && \
  poetry install --no-interaction --no-ansi

COPY . .
RUN poetry install --no-interaction --no-ansi

CMD ["python3", "-m", "hacklas-recon"]
