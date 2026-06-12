# Tahap 1: Compile kode Java
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
COPY Main.java .
RUN javac Main.java

# Tahap 2: Runtime yang super ringan
FROM eclipse-temurin:21-jre-alpine

# Install wget dan unzip untuk consul-template
RUN apk add --no-cache wget unzip

# Download & install consul-template versi 0.42.0
RUN wget https://releases.hashicorp.com/consul-template/0.42.0/consul-template_0.42.0_linux_amd64.zip && \
    unzip consul-template_0.42.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin/ && \
    rm consul-template_0.42.0_linux_amd64.zip

WORKDIR /app

# Ambil HANYA file Main.class hasil compile dari tahap 1
COPY --from=builder /build/Main.class /app/

# Note: config.env.ctmpl dan start.sh di-mount via docker-compose
