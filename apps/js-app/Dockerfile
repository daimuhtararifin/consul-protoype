FROM node:18-alpine

# Install wget dan unzip untuk download consul-template
RUN apk add --no-cache wget unzip

# Download & Install consul-template versi 0.42.0
RUN wget https://releases.hashicorp.com/consul-template/0.42.0/consul-template_0.42.0_linux_amd64.zip && \
    unzip consul-template_0.42.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin/ && \
    rm consul-template_0.42.0_linux_amd64.zip

# Setup working directory
WORKDIR /app

# Copy source code app
COPY main.js /app/main.js

# Note: file config.env.ctmpl dan start.sh TIDAK di-copy ke sini, 
# karena nanti akan di-mount dari folder shared/ lewat docker-compose.yml
