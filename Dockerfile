FROM mashape/kong:0.8.1
MAINTAINER Dinesh Bhat, dinesh.bhat@hobsons.com

ADD setup.sh setup.sh
RUN chmod +x setup.sh

CMD ./setup.sh && kong start

EXPOSE 8000 8443 8001 7946
