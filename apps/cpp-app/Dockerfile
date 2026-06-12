# Tahap 1: Compile C++ jadi binary
FROM alpine:latest AS builder

RUN apk add --no-cache g++

WORKDIR /build
COPY main.cpp .
RUN g++ -o server main.cpp -static

# Tahap 2: Image final
FROM alpine:latest

# Install wget dan unzip untuk consul-template
RUN apk add --no-cache wget unzip

# Download & install consul-template 0.42.0
RUN wget https://releases.hashicorp.com/consul-template/0.42.0/consul-template_0.42.0_linux_amd64.zip && \
    unzip consul-template_0.42.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin/ && \
    rm consul-template_0.42.0_linux_amd64.zip

WORKDIR /app
COPY --from=builder /build/server /app/server

# Note: config.env.ctmpl dan start.sh di-mount via docker-compose
