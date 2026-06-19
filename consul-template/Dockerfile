FROM alpine:3.20

ARG CONSUL_TEMPLATE_VERSION=0.42.0

RUN apk add --no-cache ca-certificates curl docker-cli unzip && \
    curl -fsSLo /tmp/consul-template.zip \
      "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip" && \
    unzip /tmp/consul-template.zip -d /usr/local/bin && \
    rm /tmp/consul-template.zip

WORKDIR /consul-template

COPY consul-template.hcl /consul-template/consul-template.hcl
COPY reload.sh /consul-template/reload.sh
COPY templates /consul-template/templates

RUN chmod +x /consul-template/reload.sh

CMD ["consul-template", "-config=/consul-template/consul-template.hcl"]