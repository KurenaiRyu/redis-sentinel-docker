FROM redis:5.0.5
MAINTAINER Kurenai

#RUN apk add --no-cache \
#        curl \
#        bash

ADD docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

EXPOSE 26379

ENTRYPOINT ["/docker-entrypoint.sh"]
