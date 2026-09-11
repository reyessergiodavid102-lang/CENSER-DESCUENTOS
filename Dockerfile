FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY logo.svg /usr/share/nginx/html/logo.svg
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

ENV PORT=4137
EXPOSE 4137



