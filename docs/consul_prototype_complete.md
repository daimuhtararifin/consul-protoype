# Consul Prototype — Project Documentation (Complete)

> Dokumen ini adalah **satu-satunya sumber kebenaran (single source of truth)** untuk project prototype ini. Semua keputusan desain, spesifikasi teknis, dan langkah pengerjaan ada di sini.
>
> **Catatan:** Dokumen ini merupakan gabungan dari `consul_prototype_docs.md` dan konsep `consul-template` yang diminta oleh Mas Sukma.

---

## Daftar Isi

1. [Tujuan Project](#1-tujuan-project)
2. [Requirement dari Mentor](#2-requirement-dari-mentor)
3. [Arsitektur Prototype](#3-arsitektur-prototype)
4. [Struktur Direktori (Final)](#4-struktur-direktori-final)
5. [Technology Stack](#5-technology-stack)
6. [Spesifikasi Komponen](#6-spesifikasi-komponen)
7. [Consul KV Schema](#7-consul-kv-schema)
8. [Docker Compose Design](#8-docker-compose-design)
9. [Consul Template — Detail Teknis](#9-consul-template--detail-teknis)
10. [Cara Menjalankan](#10-cara-menjalankan)
11. [Checklist Pengerjaan](#11-checklist-pengerjaan)
12. [Demo Script (untuk Mas Sukma)](#12-demo-script-untuk-mas-sukma)
13. [Referensi](#13-referensi)

---

## 1. Tujuan Project

Membuktikan bahwa **Centralized Config Management menggunakan Consul** bisa menggantikan file `.env` statis di deployment simulator CMS — tanpa mengubah kode aplikasi.

### Apa yang Dibuktikan

| # | Klaim | Cara Membuktikan |
|:-:|-------|-----------------|
| 1 | Consul bisa diakses dari **4 bahasa** (Go, C++, Java, JS) | Bikin 4 dummy app, masing-masing baca config dari Consul |
| 2 | Mode **dev** tetap bisa pakai file `.env` | Jalankan dengan `docker-compose.dev.yml` |
| 3 | Mode **prod** wajib baca dari Consul | Jalankan dengan `docker-compose.yml` (pakai `consul-template`) |
| 4 | **Kode app sama persis** untuk dev dan prod | Satu source code, gak ada `if env == prod` di dalamnya |
| 5 | **`consul-template`** bisa generate file config dari Consul KV | Config `.env` app + `nginx.conf` di-render otomatis dari data di Consul |

---

## 2. Requirement dari Mentor

```
1. Cari tools key value store (support SDK atau API untuk Golang, C++, Java, JS)
   → Hasil riset: Consul (lihat kv_store_analysis.md)

2. Bikin prototype untuk multi environment:
   - dev boleh baca dari file .env
   - integration/prod harus baca dari Consul
```

### Keputusan Desain

| Keputusan | Alasan |
|-----------|--------|
| Tool: **Consul** | Punya `consul-template` — render config file dari KV store tanpa ubah kode app |
| Injector: **consul-template** (bukan envconsul) | Keputusan final Mas Sukma — satu tool untuk semua (app + Nginx) |
| Prototype: **project terpisah** | Instruksi Mas Sukma — beda dari `ansible_airgapped` |
| App: **dummy app, bukan simulator asli** | Cukup buktikan mekanisme baca config, gak perlu logic bisnis |
| Setiap app: **sangat simpel** | Cuma baca 3 env var (`APP_NAME`, `APP_PORT`, `LOG_LEVEL`) → print → listen HTTP |

---

## 3. Arsitektur Prototype

### Mode PROD (baca dari Consul)

```
┌──────────────────────────────────────────────────────────────────┐
│                        Docker Network                             │
│                      (consul_prototype)                           │
│                                                                   │
│  ┌──────────────┐                                                │
│  │    Consul     │ ← Port 8500 (UI + API)                        │
│  │   Server      │                                                │
│  │  (KV Store)   │                                                │
│  └──────┬───────┘                                                │
│         │                                                         │
│    consul-template membaca KV, render file .env & nginx.conf      │
│         │                                                         │
│    ┌────┴──────────────────────────────────┐                     │
│    │   consul-template (render .env file)  │                     │
│    ├──────────┬──────────┬────────┬────────┤                     │
│    │  Go App  │ C++ App  │Java App│ JS App │                     │
│    │  :8001   │  :8002   │ :8003  │ :8004  │                     │
│    └──────────┴──────────┴────────┴────────┘                     │
│                                                                   │
│    ┌───────────────────────────────────────┐                     │
│    │  consul-template (render nginx.conf)  │                     │
│    ├───────────────────────────────────────┤                     │
│    │  Nginx Reverse Proxy  :8080           │                     │
│    │  (nginx.conf di-generate otomatis)     │                     │
│    └───────────────────────────────────────┘                     │
└──────────────────────────────────────────────────────────────────┘

Semua pakai consul-template:
  - App (Go/C++/Java/JS) → consul-template render .env file → start.sh source & jalankan app
  - Nginx                → consul-template render nginx.conf → nginx reload otomatis

Flow: Consul KV → consul-template → render config.env → start.sh source → App baca ENV VAR
      Consul KV → consul-template → render nginx.conf → Nginx reload
```

### Mode DEV (baca dari file .env)

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Network                          │
│                                                              │
│  (CONSUL TIDAK DIJALANKAN)                                  │
│                                                              │
│  ┌──────────┬──────────┬──────────┬──────────┐              │
│  │          │          │          │          │              │
│  │  Go App  │  C++ App │ Java App │  JS App  │              │
│  │  :8001   │  :8002   │  :8003   │  :8004   │              │
│  │          │          │          │          │              │
│  └──────────┴──────────┴──────────┴──────────┘              │
│       ↑          ↑          ↑          ↑                    │
│    .env        .env       .env       .env                   │
│  (file lokal) (file lokal)(file lokal)(file lokal)          │
└─────────────────────────────────────────────────────────────┘

Flow: File .env → Docker Compose env_file → ENV VAR → App baca sama persis
```

---

## 4. Struktur Direktori (Final)

```
consul_prototype/
│
├── README.md                        # Overview singkat + cara jalankan
├── docker-compose.yml               # MODE PROD — Consul + consul-template + 4 app + nginx
├── docker-compose.dev.yml           # MODE DEV  — override, 4 app pakai .env
│
├── consul/
│   └── seed.sh                      # Script otomatis isi data ke Consul KV
│
├── shared/                          # ★ File yang dipakai SEMUA app (DRY)
│   ├── config.env.ctmpl             # 1 template untuk semua app (parameterized)
│   └── start.sh                     # 1 start script untuk semua app
│
├── apps/
│   ├── go-app/
│   │   ├── Dockerfile               # Build app + install consul-template
│   │   ├── go.mod
│   │   ├── main.go                  # HTTP server, baca 3 env var
│   │   └── .env                     # Config dev (fallback tanpa Consul)
│   │
│   ├── cpp-app/
│   │   ├── Dockerfile               # Multi-stage build + consul-template
│   │   ├── main.cpp                 # HTTP server (socket), baca 3 env var
│   │   └── .env
│   │
│   ├── java-app/
│   │   ├── Dockerfile
│   │   ├── Main.java                # HTTP server (com.sun.net), baca 3 env var
│   │   └── .env
│   │
│   └── js-app/
│       ├── Dockerfile
│       ├── main.js                  # HTTP server (http module), baca 3 env var
│       └── .env
│
├── nginx/                           # Nginx punya template sendiri (beda format)
│   ├── Dockerfile                   # Nginx + consul-template binary
│   ├── nginx.conf.ctmpl             # Template Nginx (Go template syntax)
│   └── start.sh                     # Script: jalankan consul-template + nginx
│
└── docs/
    └── consul_prototype_complete.md  # ← DOKUMEN INI
```

### Kenapa Strukturnya Gini?

| Keputusan | Alasan |
|-----------|--------|
| **`shared/`** | 1 template + 1 script untuk semua app — **DRY**, gak duplikasi 4x |
| **1 docker-compose.yml + 1 override** | Best practice Docker — gak perlu duplikasi, cukup override yang beda |
| **Setiap app punya `.env` sendiri** | Biar tiap app bisa punya config dev yang berbeda |
| **`consul/seed.sh`** | Otomasi — gak perlu masukin KV satu-satu manual lewat CLI |
| **`nginx/` terpisah dari `shared/`** | Nginx punya template format beda (`nginx.conf`), bukan `.env` |
| **Tidak ada `Makefile`/`script/`** | Prototype simpel, cukup pakai `docker compose` langsung |

> [!TIP]
> **Kenapa gak pakai build tool per bahasa (Maven, npm, CMake)?**
> Karena app-nya super simpel (1 file). Semua compile/run dilakukan di dalam Dockerfile — gak perlu setup toolchain di host.

---

## 5. Technology Stack

| Komponen | Teknologi | Versi | Catatan |
|----------|-----------|-------|---------|
| KV Store | HashiCorp Consul | 1.18.x | Mode dev (single node) |
| Config Injector | consul-template | 0.42.x | Render file config dari Consul KV → `.env` app + `nginx.conf` |
| Reverse Proxy | Nginx | 1.25 | Config di-generate otomatis oleh consul-template |
| Container Runtime | Docker + Compose | v2 | Yang udah terinstall di laptop |
| Go App | Go | 1.21+ | Pakai `net/http` bawaan |
| C++ App | g++ (GCC) | 12+ | Pakai socket POSIX (tanpa library external) |
| Java App | OpenJDK | 17+ | Pakai `com.sun.net.httpserver` bawaan |
| JS App | Node.js | 18+ | Pakai modul `http` bawaan |

> [!NOTE]
> Semua app **tidak pakai library/framework external**. Murni standard library bawaan masing-masing bahasa. Ini supaya Dockerfile-nya ringan dan gak perlu download dependency.

---

## 6. Spesifikasi Komponen

### 6.1 Setiap App Harus...

Keempat app (Go, C++, Java, JS) harus punya behavior yang **identik**:

1. **Baca 3 environment variable:**

   | Env Var | Deskripsi | Contoh Value |
   |---------|-----------|:------------:|
   | `APP_NAME` | Nama service | `go-app` |
   | `APP_PORT` | Port HTTP yang di-listen | `8001` |
   | `LOG_LEVEL` | Level logging | `debug` |

2. **Jalankan HTTP server** di port `APP_PORT`

3. **Endpoint `GET /`** mengembalikan JSON:
   ```json
   {
     "service": "go-app",
     "port": "8001",
     "log_level": "debug",
     "config_source": "environment variable",
     "message": "Config loaded successfully!"
   }
   ```

4. **Print log saat startup:**
   ```
   [GO-APP] Starting on port 8001 (log_level=debug)
   ```

### 6.2 Consul Server

- Image: `hashicorp/consul:1.18`
- Mode: `-dev -client=0.0.0.0`
- Port: `8500` (UI + HTTP API)
- Data: di-seed otomatis oleh `consul/seed.sh`

### 6.3 consul-template (Berjalan di Dalam Container App & Nginx)

- Diinstall di setiap Dockerfile (app + nginx)
- Untuk app: render `config.env.ctmpl` → `config.env`, lalu `start.sh` source file tersebut
- Untuk nginx: render `nginx.conf.ctmpl` → `nginx.conf`, lalu reload Nginx
- Flag: `-exec` (jalankan command setelah render)
- **Otomatis watch**: kalau KV berubah → re-render → restart app / reload Nginx

**File `shared/config.env.ctmpl` (1 file, dipakai semua app):**

```
APP_NAME={{ keyOrDefault (printf "config/%s/APP_NAME" (env "SERVICE_NAME")) "unknown" }}
APP_PORT={{ keyOrDefault (printf "config/%s/APP_PORT" (env "SERVICE_NAME")) "8000" }}
LOG_LEVEL={{ keyOrDefault (printf "config/%s/LOG_LEVEL" (env "SERVICE_NAME")) "info" }}
```

> [!NOTE]
> **Kenapa bisa 1 template untuk 4 app?**
> `env "SERVICE_NAME"` membaca env var `SERVICE_NAME` yang di-set di `docker-compose.yml` per app.
> Jadi template yang sama menghasilkan output berbeda tergantung app yang menjalankannya.
> Contoh: kalau `SERVICE_NAME=go-app`, maka `printf "config/%s/APP_NAME"` jadi `config/go-app/APP_NAME`.

**File `shared/start.sh` (1 file, dipakai semua app):**

```bash
#!/bin/sh
set -a
. /app/config.env
set +a
exec "$@"
```

- `set -a` → semua variable yang di-source otomatis jadi environment variable
- `exec "$@"` → jalankan command dari argumen (misal `/app/server` atau `node /app/main.js`)

---

## 7. Consul KV Schema

### Penamaan Key

Pattern: `config/{app-name}/{VARIABLE_NAME}`

```
config/go-app/APP_NAME     → "go-app"
config/go-app/APP_PORT     → "8001"
config/go-app/LOG_LEVEL    → "debug"

config/cpp-app/APP_NAME    → "cpp-app"
config/cpp-app/APP_PORT    → "8002"
config/cpp-app/LOG_LEVEL   → "info"

config/java-app/APP_NAME   → "java-app"
config/java-app/APP_PORT   → "8003"
config/java-app/LOG_LEVEL  → "warn"

config/js-app/APP_NAME     → "js-app"
config/js-app/APP_PORT     → "8004"
config/js-app/LOG_LEVEL    → "debug"
```

### Seed Script (`consul/seed.sh`)

```bash
#!/bin/bash
# Tunggu Consul siap
until consul kv put health/check ready 2>/dev/null; do
  echo "Waiting for Consul..."
  sleep 2
done
consul kv delete health/check

echo "Seeding Consul KV Store..."

# Go App
consul kv put config/go-app/APP_NAME "go-app"
consul kv put config/go-app/APP_PORT "8001"
consul kv put config/go-app/LOG_LEVEL "debug"

# C++ App
consul kv put config/cpp-app/APP_NAME "cpp-app"
consul kv put config/cpp-app/APP_PORT "8002"
consul kv put config/cpp-app/LOG_LEVEL "info"

# Java App
consul kv put config/java-app/APP_NAME "java-app"
consul kv put config/java-app/APP_PORT "8003"
consul kv put config/java-app/LOG_LEVEL "warn"

# JS App
consul kv put config/js-app/APP_NAME "js-app"
consul kv put config/js-app/APP_PORT "8004"
consul kv put config/js-app/LOG_LEVEL "debug"

echo "✅ Seeding complete!"
consul kv get -recurse config/
```

---

## 8. Docker Compose Design

### `docker-compose.yml` (Mode PROD)

```yaml
services:
  consul:
    image: hashicorp/consul:1.18
    container_name: consul-server
    command: agent -dev -client=0.0.0.0
    ports:
      - "8500:8500"
    healthcheck:
      test: ["CMD", "consul", "info"]
      interval: 5s
      timeout: 3s
      retries: 5

  consul-seed:
    image: hashicorp/consul:1.18
    container_name: consul-seed
    depends_on:
      consul:
        condition: service_healthy
    volumes:
      - ./consul/seed.sh:/seed.sh
    entrypoint: /bin/sh
    command: /seed.sh
    environment:
      - CONSUL_HTTP_ADDR=consul:8500

  go-app:
    build: ./apps/go-app
    container_name: go-app
    depends_on:
      consul-seed:
        condition: service_completed_successfully
    environment:
      - SERVICE_NAME=go-app
    volumes:
      - ./shared/config.env.ctmpl:/app/config.env.ctmpl:ro
      - ./shared/start.sh:/app/start.sh:ro
    command: >
      consul-template -consul-addr=consul:8500
      -template="/app/config.env.ctmpl:/app/config.env"
      -exec="/app/start.sh /app/server"
    ports:
      - "8001:8001"

  cpp-app:
    build: ./apps/cpp-app
    container_name: cpp-app
    depends_on:
      consul-seed:
        condition: service_completed_successfully
    environment:
      - SERVICE_NAME=cpp-app
    volumes:
      - ./shared/config.env.ctmpl:/app/config.env.ctmpl:ro
      - ./shared/start.sh:/app/start.sh:ro
    command: >
      consul-template -consul-addr=consul:8500
      -template="/app/config.env.ctmpl:/app/config.env"
      -exec="/app/start.sh /app/server"
    ports:
      - "8002:8002"

  java-app:
    build: ./apps/java-app
    container_name: java-app
    depends_on:
      consul-seed:
        condition: service_completed_successfully
    environment:
      - SERVICE_NAME=java-app
    volumes:
      - ./shared/config.env.ctmpl:/app/config.env.ctmpl:ro
      - ./shared/start.sh:/app/start.sh:ro
    command: >
      consul-template -consul-addr=consul:8500
      -template="/app/config.env.ctmpl:/app/config.env"
      -exec="/app/start.sh java -cp /app Main"
    ports:
      - "8003:8003"

  js-app:
    build: ./apps/js-app
    container_name: js-app
    depends_on:
      consul-seed:
        condition: service_completed_successfully
    environment:
      - SERVICE_NAME=js-app
    volumes:
      - ./shared/config.env.ctmpl:/app/config.env.ctmpl:ro
      - ./shared/start.sh:/app/start.sh:ro
    command: >
      consul-template -consul-addr=consul:8500
      -template="/app/config.env.ctmpl:/app/config.env"
      -exec="/app/start.sh node /app/main.js"
    ports:
      - "8004:8004"
```

### `docker-compose.dev.yml` (Override Mode DEV)

```yaml
services:
  # Consul TIDAK dijalankan di dev
  consul:
    profiles: ["prod-only"]
  consul-seed:
    profiles: ["prod-only"]

  go-app:
    env_file: ./apps/go-app/.env
    command: /app/server

  cpp-app:
    env_file: ./apps/cpp-app/.env
    command: /app/server

  java-app:
    env_file: ./apps/java-app/.env
    command: java -cp /app Main

  js-app:
    env_file: ./apps/js-app/.env
    command: node /app/main.js
```

### File `.env` per App (Contoh `apps/go-app/.env`)

```env
APP_NAME=go-app
APP_PORT=8001
LOG_LEVEL=debug
```

---

## 9. Consul Template — Detail Teknis

### Apa itu Consul Template?

`consul-template` adalah tool resmi dari HashiCorp yang fungsinya: **merender file konfigurasi secara dinamis** berdasarkan data yang ada di Consul KV Store, lalu **menjalankan perintah otomatis** (misalnya reload Nginx atau restart app) kalau ada perubahan.

Di prototype ini, consul-template dipakai untuk **semua komponen**:

| Komponen | Template Input | Output File | Aksi Setelah Render |
|----------|---------------|-------------|---------------------|
| 4 App (Go/C++/Java/JS) | `config.env.ctmpl` | `config.env` | `start.sh` source env & jalankan app |
| Nginx | `nginx.conf.ctmpl` | `nginx.conf` | `nginx -s reload` |

### Apa yang Dilakukan di Prototype Ini

Nginx akan jadi **reverse proxy** untuk 4 app kita. Tapi routing config-nya **bukan hardcode** — melainkan di-generate otomatis dari data di Consul KV.

Kalau data di Consul berubah (misal port app berubah), `consul-template` otomatis tulis ulang `nginx.conf` dan reload Nginx.

### KV Schema Tambahan untuk Nginx

Tambahkan di `consul/seed.sh`:

```bash
# Nginx routing config
consul kv put config/nginx/domain "prototype.local"
consul kv put config/nginx/routes/go-app "go-app:8001"
consul kv put config/nginx/routes/cpp-app "cpp-app:8002"
consul kv put config/nginx/routes/java-app "java-app:8003"
consul kv put config/nginx/routes/js-app "js-app:8004"
```

### File Template: `nginx/nginx.conf.ctmpl`

```nginx
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name {{ keyOrDefault "config/nginx/domain" "localhost" }};

        # Route: /go → Go App
        location /go/ {
            proxy_pass http://{{ keyOrDefault "config/nginx/routes/go-app" "go-app:8001" }}/;
        }

        # Route: /cpp → C++ App
        location /cpp/ {
            proxy_pass http://{{ keyOrDefault "config/nginx/routes/cpp-app" "cpp-app:8002" }}/;
        }

        # Route: /java → Java App
        location /java/ {
            proxy_pass http://{{ keyOrDefault "config/nginx/routes/java-app" "java-app:8003" }}/;
        }

        # Route: /js → JS App
        location /js/ {
            proxy_pass http://{{ keyOrDefault "config/nginx/routes/js-app" "js-app:8004" }}/;
        }

        # Health check
        location /health {
            return 200 '{"status":"ok"}';
            add_header Content-Type application/json;
        }
    }
}
```

**Penjelasan syntax:**
- `{{ key "..." }}` → ambil value dari Consul KV
- `{{ keyOrDefault "..." "fallback" }}` → sama, tapi ada default kalau key belum ada

### File: `nginx/start.sh`

```bash
#!/bin/sh
# Render template pertama kali
consul-template \
  -consul-addr="consul:8500" \
  -template="/etc/nginx/nginx.conf.ctmpl:/etc/nginx/nginx.conf:nginx -s reload" \
  -once

# Jalankan nginx di foreground
nginx -g "daemon off;" &

# Jalankan consul-template untuk watch perubahan
consul-template \
  -consul-addr="consul:8500" \
  -template="/etc/nginx/nginx.conf.ctmpl:/etc/nginx/nginx.conf:nginx -s reload"
```

### File: `nginx/Dockerfile`

```dockerfile
FROM nginx:1.25-alpine

# Install consul-template
RUN wget https://releases.hashicorp.com/consul-template/0.39.1/consul-template_0.39.1_linux_amd64.zip && \
    unzip consul-template_0.39.1_linux_amd64.zip && \
    mv consul-template /usr/local/bin/ && \
    rm consul-template_0.39.1_linux_amd64.zip

COPY nginx.conf.ctmpl /etc/nginx/nginx.conf.ctmpl
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
```

### Tambahan di `docker-compose.yml` (Mode PROD)

```yaml
  nginx:
    build: ./nginx
    container_name: nginx-proxy
    depends_on:
      consul-seed:
        condition: service_completed_successfully
    ports:
      - "8080:80"
```

### Tambahan di `docker-compose.dev.yml` (Override Mode DEV)

```yaml
  nginx:
    profiles: ["prod-only"]  # Nginx + consul-template gak jalan di dev
```

### Cara Test consul-template

```bash
# Lewat Nginx (proxy)
curl http://localhost:8080/go/     # → forward ke Go App
curl http://localhost:8080/js/     # → forward ke JS App
curl http://localhost:8080/health  # → {"status":"ok"}

# Live change — ubah routing di Consul
docker exec consul-server consul kv put config/nginx/routes/go-app "go-app:9999"
# → consul-template otomatis tulis ulang nginx.conf & reload
# → request berikutnya ke /go/ akan forward ke port 9999
```

---

## 10. Cara Menjalankan

### Mode PROD (Consul)
```bash
# Jalankan semua (Consul + seed + 4 app)
docker compose up --build

# Buka Consul UI
# http://localhost:8500

# Test setiap app
curl http://localhost:8001   # Go
curl http://localhost:8002   # C++
curl http://localhost:8003   # Java
curl http://localhost:8004   # JS
```

### Mode DEV (File .env)
```bash
# Jalankan tanpa Consul — app baca dari .env
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build

# Test (hasil sama persis!)
curl http://localhost:8001   # Go
curl http://localhost:8002   # C++
curl http://localhost:8003   # Java
curl http://localhost:8004   # JS
```

### Verifikasi Config Berubah (Demo Live)
```bash
# 1. Ubah config di Consul (via CLI)
docker exec consul-server consul kv put config/js-app/LOG_LEVEL "error"

# 2. consul-template otomatis re-render config.env & restart app
# 3. Test lagi
curl http://localhost:8004
# → log_level sekarang "error"
```

---

## 11. Checklist Pengerjaan

### Phase 1: Foundation
- [ ] Buat `docker-compose.yml` (Consul server + healthcheck + seed)
- [ ] Buat `consul/seed.sh` dengan semua KV data
- [ ] Buat `shared/config.env.ctmpl` (1 parameterized template)
- [ ] Buat `shared/start.sh` (1 shared start script)
- [ ] Test: `docker compose up consul consul-seed` → cek UI di `:8500`

### Phase 2: Apps (satu-satu)
- [ ] **JS App** (paling gampang, mulai dari sini)
  - [ ] `apps/js-app/main.js`
  - [ ] `apps/js-app/Dockerfile` (install consul-template)
  - [ ] `apps/js-app/.env`
  - [ ] Test mode prod (consul-template)
  - [ ] Test mode dev (.env)
- [ ] **Go App**
  - [ ] `apps/go-app/main.go` + `go.mod`
  - [ ] `apps/go-app/Dockerfile`
  - [ ] `apps/go-app/.env`
  - [ ] Test mode prod & dev
- [ ] **Java App**
  - [ ] `apps/java-app/Main.java`
  - [ ] `apps/java-app/Dockerfile`
  - [ ] `apps/java-app/.env`
  - [ ] Test mode prod & dev
- [ ] **C++ App** (paling ribet Dockerfile-nya)
  - [ ] `apps/cpp-app/main.cpp`
  - [ ] `apps/cpp-app/Dockerfile`
  - [ ] `apps/cpp-app/.env`
  - [ ] Test mode prod & dev

### Phase 3: Nginx (consul-template untuk file config)
- [ ] `nginx/nginx.conf.ctmpl`
- [ ] `nginx/start.sh`
- [ ] `nginx/Dockerfile`
- [ ] Tambah KV nginx di `seed.sh`
- [ ] Tambah service `nginx` di `docker-compose.yml`
- [ ] Test: `curl http://localhost:8080/go/`
- [ ] Test: ubah routing di Consul → Nginx auto-reload

### Phase 4: Integration & Polish
- [ ] Test `docker compose up` (semua 4 app + Nginx + Consul berjalan bareng)
- [ ] Test `docker compose -f ... -f ... up` (mode dev)
- [ ] Test live config change (ubah KV → app restart otomatis)
- [ ] Tulis `README.md` (cara jalankan + screenshot)
- [ ] Demo ke Mas Sukma 🎬

---

## 12. Demo Script (untuk Mas Sukma)

### Act 1: "Ini Consul" (2 menit)
1. `docker compose up -d consul consul-seed`
2. Buka browser → `http://localhost:8500`
3. Tunjukin KV Store → `config/go-app/`, `config/cpp-app/`, dst
4. *"Ini tempat terpusat nyimpen config semua service, mas."*

### Act 2: "Mode PROD — App Baca dari Consul" (3 menit)
1. `docker compose up --build`
2. `curl http://localhost:8001` → tunjukin JSON response Go
3. `curl http://localhost:8004` → tunjukin JSON response JS
4. *"Semua app baca config dari Consul via consul-template, tanpa ubah kode app."*

### Act 3: "Live Config Change" (2 menit)
1. `docker exec consul-server consul kv put config/js-app/LOG_LEVEL error`
2. Tunjukin log terminal → consul-template re-render config.env & restart app
3. `curl http://localhost:8004` → `log_level` berubah jadi `"error"`
4. *"Config berubah di Consul, app langsung ikut berubah tanpa deploy ulang."*

### Act 4: "Mode DEV — Tetap Bisa Pakai .env" (2 menit)
1. `docker compose down`
2. `docker compose -f docker-compose.yml -f docker-compose.dev.yml up`
3. `curl http://localhost:8001` → hasilnya sama, tapi sumber config dari file `.env`
4. *"Developer di lokal gak perlu jalanin Consul. Cukup pakai file .env biasa."*

### Act 5: "Nginx consul-template — File Config Otomatis" (3 menit)
1. `curl http://localhost:8080/go/` → tunjukin Nginx forward ke Go App
2. Buka Consul UI → tunjukin key `config/nginx/routes/go-app`
3. Ubah value via CLI: `docker exec consul-server consul kv put config/nginx/domain "simulator.cms.local"`
4. Tunjukin log Nginx → `consul-template` tulis ulang config & reload
5. *"Ini juga consul-template, tapi untuk Nginx. Dia nge-render file nginx.conf dari data Consul. Kalau routing berubah, Nginx auto-reload."*

### Kemungkinan Pertanyaan
| Pertanyaan | Jawaban |
|-----------|---------|
| "Kalau Consul mati gimana?" | App tetap jalan dengan config terakhir. Tapi gak bisa update config sampai Consul hidup lagi. Di production, Consul jalan cluster 3 node (HA). |
| "Kenapa consul-template bukan SDK langsung?" | Biar gak perlu ubah kode app C++ yang bukan kita yang develop. consul-template render file config, app tinggal baca ENV VAR biasa. |
| "Bedanya sama Spring Cloud Config?" | Consul lebih general (polyglot — Go, C++, Java, JS). Spring Cloud Config khusus Java ecosystem. |
| "Kenapa gak pakai envconsul?" | Keputusan Mas Sukma — consul-template lebih fleksibel karena bisa render file apapun (`.env`, `.conf`, `.yaml`). Satu tool untuk semua kebutuhan. |

---

## 13. Referensi

| Resource | Link |
|----------|------|
| Consul Official Docs | https://developer.hashicorp.com/consul/docs |
| Consul Docker Image | https://hub.docker.com/r/hashicorp/consul |
| consul-template GitHub | https://github.com/hashicorp/consul-template |
| consul-template Releases | https://releases.hashicorp.com/consul-template/ |
| Riset KV Store (artifact sebelumnya) | `kv_store_analysis.md` |
| Panduan Consul (artifact sebelumnya) | `consul_guide.md` |
| Contoh Implementasi (artifact sebelumnya) | `consul_implementation_example.md` |