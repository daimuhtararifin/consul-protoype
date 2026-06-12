FROM golang:1.21-alpine AS builder

WORKDIR /builder
COPY main.go go.mod ./
RUN go build -o server main.go

FROM alpine:latest

RUN apk add --no-cache wget unzip
RUN wget https://releases.hashicorp.com/consul-template/0.42.0/consul-template_0.42.0_linux_amd64.zip && \
    unzip consul-template_0.42.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin/ && \
    rm consul-template_0.42.0_linux_amd64.zip
WORKDIR /app
COPY --from=builder /builder/server /app/server

# Note: config.env.ctmpl dan start.sh di-mount dari shared/ via docker-compose