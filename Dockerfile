FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY logo.svg /usr/share/nginx/html/logo.svg

RUN printf 'server {\n    listen 10000;\n    listen [::]:10000;\n    server_name _;\n    root /usr/share/nginx/html;\n    index index.html;\n\n    location / {\n        try_files $uri $uri/ /index.html;\n    }\n}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 10000

CMD ["nginx", "-g", "daemon off;"]

