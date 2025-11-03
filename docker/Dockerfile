# Folosește imaginea oficială Nginx
FROM nginx:latest

# Șterge fișierele default
RUN rm -rf /usr/share/nginx/html/*

# Copiază aplicația ta în folderul Nginx
COPY *.html /usr/share/nginx/html/
COPY *.css /usr/share/nginx/html/

# Expune portul 80
EXPOSE 80

# Rulează Nginx
CMD ["nginx", "-g", "daemon off;"]
