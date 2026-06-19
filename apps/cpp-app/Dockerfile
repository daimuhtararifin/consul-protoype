FROM alpine:3.20 AS builder

RUN apk add --no-cache g++

WORKDIR /build
COPY main.cpp .
RUN g++ -o server main.cpp -static

FROM alpine:3.20

WORKDIR /app
COPY --from=builder /build/server /app/server

CMD ["/app/server"]