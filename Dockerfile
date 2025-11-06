FROM ubuntu:22.04
LABEL maintainer="donald"
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git
# Clean up the default nginx content directory
RUN rm -Rf /var/www/html/*
RUN git clone https://github.com/FoumaneDonald/carnet_address.git /var/www/html/
EXPOSE 80
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
