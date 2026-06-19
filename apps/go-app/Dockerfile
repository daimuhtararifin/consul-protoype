FROM golang:1.21-alpine AS builder

WORKDIR /builder
COPY main.go go.mod ./
RUN go build -o server main.go

FROM alpine:3.20

WORKDIR /app
COPY --from=builder /builder/server /app/server

CMD ["/app/server"]