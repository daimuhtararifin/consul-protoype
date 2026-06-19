FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build
COPY Main.java .
RUN javac Main.java

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /build/Main.class /app/

CMD ["java", "-cp", "/app", "Main"]