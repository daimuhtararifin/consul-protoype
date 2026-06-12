FROM nginx:alpine

# Install wget dan unzip
RUN apk add --no-cache wget unzip

# Download & Install consul-template versi 0.42.0
RUN wget https://releases.hashicorp.com/consul-template/0.42.0/consul-template_0.42.0_linux_amd64.zip && \
    unzip consul-template_0.42.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin/ && \
    rm consul-template_0.42.0_linux_amd64.zip

# Hapus config Nginx bawaan
RUN rm /etc/nginx/nginx.conf

# Copy template dan script
COPY nginx.conf.ctmpl /etc/nginx/nginx.conf.ctmpl
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Eksekusi start script
CMD ["/start.sh"]
