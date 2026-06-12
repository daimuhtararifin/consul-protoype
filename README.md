# Consul Template Architecture Prototype

> Prototype arsitektur injeksi konfigurasi dinamis menggunakan **Consul KV Store** dan **consul-template** sebagai *Single Source of Truth* untuk aplikasi multi-bahasa dan Nginx reverse proxy.

---

## Tech Stack

<p>
  <img src="https://img.shields.io/badge/Consul-F24C53?style=for-the-badge&logo=consul&logoColor=white" alt="Consul"/>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white" alt="Nginx"/>
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Go-00ADD8?style=for-the-badge&logo=go&logoColor=white" alt="Go"/>
  <img src="https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" alt="Java"/>
  <img src="https://img.shields.io/badge/C++-00599C?style=for-the-badge&logo=cplusplus&logoColor=white" alt="C++"/>
</p>

| Komponen | Teknologi | Versi |
|----------|-----------|-------|
| KV Store | HashiCorp Consul | 1.18 |
| Config Injector | consul-template | 0.42.0 |
| Reverse Proxy | Nginx | Alpine |
| Container Runtime | Docker Compose | v2 |
| App 1 | Node.js | 18 |
| App 2 | Go | 1.21 |
| App 3 | Java (Eclipse Temurin) | 21 |
| App 4 | C++ (g++) | Alpine |

---

## Arsitektur — Mode PROD

Semua service aktif. Config bersumber dari Consul KV Store, di-inject ke aplikasi via `consul-template`.

```
   ┌────────────────────────────────────────────────────────────────────┐
   │  consul-seed (berjalan sekali, lalu selesai)                      │
   │  └── Isi Consul KV: config/go-app/*, config/nginx/routes/*, dst.  │
   └───────────────────────────────┬────────────────────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │      Consul Server        │
                    │    KV Store (:8500)       │
                    └──────┬──────────┬─────────┘
                           │          │
          ┌────────────────┘          └────────────────┐
          │  consul-template                           │  consul-template
          │  (di dalam setiap app container)           │  (di dalam nginx container)
          ▼                                            ▼
   ┌─────────────┐                            ┌───────────────────┐
   │ config.env  │                            │    nginx.conf     │
   └──────┬──────┘                            └────────┬──────────┘
          │ source (start.sh)                          │
          ▼                                            ▼
   ┌────────────────────────────────┐        ┌──────────────────────┐
   │  js-app  go-app  java  cpp     │◄───────│   Nginx (port 8088)  │
   │  :8004   :8001   :8003  :8002  │        │   Reverse Proxy      │
   └────────────────────────────────┘        └──────────────────────┘
                                                        ▲
                                                        │
                                                   User Request
                                              (http://localhost:8088/go-app/)
```

**Alur:**
1. `consul-seed` mengisi Consul KV Store dengan data konfigurasi awal, lalu container-nya mati.
2. `consul-template` di dalam setiap container membaca KV Store dan merender file `config.env`.
3. `start.sh` melakukan *source* terhadap `config.env` sehingga nilainya jadi environment variable.
4. Aplikasi membaca environment variable dan berjalan sesuai konfigurasi.
5. Nginx mendapatkan `nginx.conf` yang di-generate dinamis dari `config/nginx/routes/*` di Consul.
6. Jika ada perubahan nilai di Consul KV, `consul-template` otomatis merender ulang dan me-restart aplikasi/reload Nginx.

---

## Arsitektur — Mode DEV

Consul, Nginx, dan consul-seed tidak dijalankan. Aplikasi membaca config langsung dari file `.env` lokal.

```
   ┌──────────────────────────────────────────────────────────┐
   │  docker-compose.dev.yml override:                        │
   │    consul      → dinonaktifkan (profiles: prod-only)     │
   │    consul-seed → dinonaktifkan (profiles: prod-only)     │
   │    nginx       → dinonaktifkan (profiles: prod-only)     │
   └──────────────────────────────────────────────────────────┘

   apps/js-app/.env ──► js-app (:8004)
   apps/go-app/.env ──► go-app (:8001)
 apps/java-app/.env ──► java-app (:8003)
  apps/cpp-app/.env ──► cpp-app (:8002)

   (Tidak ada reverse proxy, akses langsung ke port masing-masing)
```

**Alur:**
1. Docker Compose membaca `docker-compose.dev.yml` sebagai override.
2. Service consul, consul-seed, dan nginx dinonaktifkan via `profiles`.
3. Setiap aplikasi langsung menggunakan `env_file` untuk membaca file `.env` lokal sebagai konfigurasi.
4. `volumes` dan `depends_on` yang merujuk ke Consul di-reset (`!reset []`) agar tidak error.

---

## Struktur Direktori

```
consul_prototype/
├── README.md
├── docker-compose.yml              # Mode PROD (Consul + consul-template + Apps + Nginx)
├── docker-compose.dev.yml          # Mode DEV  (Apps only, pakai .env lokal)
│
├── consul/
│   └── seed.sh                     # Script otomatis mengisi Consul KV Store
│
├── shared/                         # File yang dipakai semua app (DRY principle)
│   ├── config.env.ctmpl            # Template consul-template (parameterized)
│   └── start.sh                    # Script: source config.env → jalankan app
│
├── apps/
│   ├── js-app/
│   │   ├── Dockerfile
│   │   ├── main.js                 # HTTP server (Node.js built-in http module)
│   │   └── .env                    # Config lokal untuk mode DEV
│   │
│   ├── go-app/
│   │   ├── Dockerfile              # Multi-stage build
│   │   ├── main.go                 # HTTP server (net/http)
│   │   ├── go.mod
│   │   └── .env
│   │
│   ├── java-app/
│   │   ├── Dockerfile              # Multi-stage build (JDK → JRE)
│   │   ├── Main.java               # HTTP server (com.sun.net.httpserver)
│   │   └── .env
│   │
│   └── cpp-app/
│       ├── Dockerfile              # Multi-stage build (g++ → alpine)
│       ├── main.cpp                # HTTP server (raw socket)
│       └── .env
│
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf.ctmpl            # Template Nginx (routing di-generate dari Consul)
│   └── start.sh                    # Script: render config → start nginx → watch
│
└── docs/
    └── consul_prototype_complete.md
```

---

## Consul KV Schema

Semua konfigurasi disimpan di Consul KV Store dengan format path berikut:

```
config/
├── go-app/
│   ├── APP_NAME    = "go-app"
│   ├── APP_PORT    = "8001"
│   └── LOG_LEVEL   = "debug"
├── cpp-app/
│   ├── APP_NAME    = "cpp-app"
│   ├── APP_PORT    = "8002"
│   └── LOG_LEVEL   = "info"
├── java-app/
│   ├── APP_NAME    = "java-app"
│   ├── APP_PORT    = "8003"
│   └── LOG_LEVEL   = "warn"
├── js-app/
│   ├── APP_NAME    = "js-app"
│   ├── APP_PORT    = "8004"
│   └── LOG_LEVEL   = "debug"
└── nginx/
    ├── domain      = "prototype.local"
    └── routes/
        ├── go-app   = "go-app:8001"
        ├── cpp-app  = "cpp-app:8002"
        ├── java-app = "java-app:8003"
        └── js-app   = "js-app:8004"
```

---

## Port Mapping

| Service | Container Port | Host Port | Keterangan |
|---------|:--------------:|:---------:|------------|
| Consul UI | 8500 | 8500 | Dashboard + HTTP API |
| JS App | 8004 | 8004 | Direct access |
| Go App | 8001 | 8001 | Direct access |
| Java App | 8003 | 8003 | Direct access |
| C++ App | 8002 | 8002 | Direct access |
| Nginx | 8080 | 8088 | Reverse proxy (single entry point) |

---

## Cara Menjalankan

### Mode PROD (dengan Consul)

```bash
# Build dan jalankan semua services
docker compose up -d --build

# Verifikasi semua container berjalan
docker compose ps
```

**Endpoint yang tersedia:**

| URL | Deskripsi |
|-----|-----------|
| `http://localhost:8500` | Consul Dashboard (UI) |
| `http://localhost:8088/js-app/` | JS App via Nginx |
| `http://localhost:8088/go-app/` | Go App via Nginx |
| `http://localhost:8088/java-app/` | Java App via Nginx |
| `http://localhost:8088/cpp-app/` | C++ App via Nginx |
| `http://localhost:8001` | Go App (direct) |
| `http://localhost:8002` | C++ App (direct) |
| `http://localhost:8003` | Java App (direct) |
| `http://localhost:8004` | JS App (direct) |

### Mode DEV (tanpa Consul)

```bash
# Jalankan aplikasi dengan file .env lokal, tanpa Consul dan Nginx
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

### Menghentikan Semua Services

```bash
docker compose down
```

---

## Cara Kerja consul-template

### Shared Template (DRY)

Semua 4 aplikasi menggunakan **satu file template** yang sama (`shared/config.env.ctmpl`). Diferensiasi dilakukan melalui environment variable `SERVICE_NAME` yang di-set di `docker-compose.yml` per service.

```
APP_NAME={{ keyOrDefault (printf "config/%s/APP_NAME" (env "SERVICE_NAME")) "unknown" }}
APP_PORT={{ keyOrDefault (printf "config/%s/APP_PORT" (env "SERVICE_NAME")) "8000" }}
LOG_LEVEL={{ keyOrDefault (printf "config/%s/LOG_LEVEL" (env "SERVICE_NAME")) "info" }}
```

Contoh: ketika `SERVICE_NAME=go-app`, template di atas merender menjadi:
```env
APP_NAME=go-app
APP_PORT=8001
LOG_LEVEL=debug
```

### Lifecycle di Dalam Container

```
consul-template start
    │
    ├── Watch Consul KV (key: config/<SERVICE_NAME>/*)
    │
    ├── Render config.env.ctmpl → config.env
    │
    ├── Exec: start.sh <app command>
    │       │
    │       ├── source config.env (set environment variables)
    │       └── exec <app command> (misal: node main.js)
    │
    └── Jika KV berubah → re-render → restart app otomatis
```

---

## Live Config Change

Fitur utama prototype ini: perubahan konfigurasi di Consul KV **otomatis ter-propagasi** ke semua aplikasi tanpa intervensi manual.

### Skenario: Mengubah LOG_LEVEL secara Dinamis

Berikut adalah alur yang terjadi di balik layar ketika konfigurasi diubah (misalnya `LOG_LEVEL` dari `debug` menjadi `fatal`):

```
1. User mengubah nilai di Consul
   (via UI Dashboard atau curl PUT)
              │
              ▼
2. Consul Server menyimpan nilai baru
   (config/go-app/LOG_LEVEL = "fatal")
              │
              ▼
3. consul-template (di dalam container go-app)
   mendeteksi perubahan pada path KV yang dia-watch
              │
              ▼
4. consul-template merender ulang config.env.ctmpl → config.env
   Isi file /app/config.env terupdate: LOG_LEVEL=fatal
              │
              ▼
5. consul-template menghentikan (KILL) proses aplikasi yang lama
   lalu mengeksekusi ulang command (-exec)
              │
              ▼
6. start.sh berjalan kembali:
   - source /app/config.env (membaca nilai baru)
   - exec /app/server       (menjalankan aplikasi dengan env baru)
```

**Hasilnya:** Aplikasi merespon dengan `log_level` yang baru tanpa perlu re-build image atau re-deploy container, downtime hanya ~1-2 detik selama proses restart.

### Cara Mendemonstrasikan

Gunakan 2 terminal untuk melihat perubahannya secara real-time:

**Terminal 1 (Monitor API):**
```bash
# Lakukan request setiap 1 detik
watch -n1 curl -s http://localhost:8088/go-app/
```

**Terminal 2 (Ubah Config):**
```bash
# Ubah config via Consul HTTP API
curl -X PUT http://localhost:8500/v1/kv/config/go-app/LOG_LEVEL -d "fatal"
```
*Perhatikan Terminal 1, respons JSON akan berubah dari "debug" ke "fatal" secara otomatis.*

Perubahan juga bisa dilakukan dengan mudah melalui UI di `http://localhost:8500` → menu **Key/Value**.

---

## Catatan Teknis

- **consul-template** di-install di dalam setiap Docker image (bukan sebagai sidecar container) karena ini adalah prototype sederhana.
- **Nginx** menggunakan `start.sh` terpisah dari `shared/start.sh` karena flow-nya berbeda: render config → start nginx → watch & reload.
- **Multi-stage build** digunakan untuk Go, Java, dan C++ agar image final tetap kecil (hanya berisi binary + consul-template).
- **`keyOrDefault`** digunakan di template sebagai fallback jika key belum tersedia di Consul saat pertama kali dirender.
- **`!reset`** syntax di `docker-compose.dev.yml` digunakan untuk menghapus `depends_on` dan `volumes` dari file compose utama saat mode DEV.

---

## Referensi

- [HashiCorp Consul Documentation](https://developer.hashicorp.com/consul/docs)
- [consul-template GitHub](https://github.com/hashicorp/consul-template)
- [consul-template Configuration](https://github.com/hashicorp/consul-template/blob/main/docs/configuration.md)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
