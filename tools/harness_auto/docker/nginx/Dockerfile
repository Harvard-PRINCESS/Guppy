FROM nginx:alpine
COPY ./docker/nginx/htpasswd /etc/nginx/.htpasswd
RUN rm -f /etc/nginx/conf.d/default.conf
COPY ./docker/nginx/server.conf /etc/nginx/conf.d/server.conf

