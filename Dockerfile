FROM mashape/kong:0.8.3
MAINTAINER Dinesh Bhat 

ENV KONG_VERSION 0.8.3

VOLUME ["/etc/kong/"]

COPY config.docker/kong.yml /etc/kong/kong.yml

ADD setup.sh setup.sh
RUN chmod +x setup.sh

CMD ./setup.sh && kong start

EXPOSE 8000 8443 8001 7946
