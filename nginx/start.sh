#!/bin/sh

echo "Step 1: Render nginx.conf pertama kali dari Consul..."
consul-template \
  -consul-addr=consul:8500 \
  -template="/etc/nginx/nginx.conf.ctmpl:/etc/nginx/nginx.conf" \
  -once

echo "Step 2: Nginx config siap, mulai Nginx..."
nginx

echo "Step 3: Watch perubahan Consul, reload Nginx kalau ada update..."
exec consul-template \
  -consul-addr=consul:8500 \
  -template="/etc/nginx/nginx.conf.ctmpl:/etc/nginx/nginx.conf:nginx -s reload"
