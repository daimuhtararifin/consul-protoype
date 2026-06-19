consul {
  address = "consul:8500"
}

wait {
  min = "2s"
  max = "5s"
}

template {
  source      = "/consul-template/templates/go-app.env.ctmpl"
  destination = "/rendered/go-app/config.env"
  perms       = 0644
  command     = "/consul-template/reload.sh app go-app"
}

template {
  source      = "/consul-template/templates/cpp-app.env.ctmpl"
  destination = "/rendered/cpp-app/config.env"
  perms       = 0644
  command     = "/consul-template/reload.sh app cpp-app"
}

template {
  source      = "/consul-template/templates/java-app.env.ctmpl"
  destination = "/rendered/java-app/config.env"
  perms       = 0644
  command     = "/consul-template/reload.sh app java-app"
}

template {
  source      = "/consul-template/templates/js-app.env.ctmpl"
  destination = "/rendered/js-app/config.env"
  perms       = 0644
  command     = "/consul-template/reload.sh app js-app"
}

template {
  source      = "/consul-template/templates/nginx.conf.ctmpl"
  destination = "/rendered/nginx/nginx.conf"
  perms       = 0644
  command     = "/consul-template/reload.sh nginx nginx-proxy"
}