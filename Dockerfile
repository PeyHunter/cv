# CI runs ./build.sh first, so dist/ already holds the finished files.
# The image only serves them; it never compiles anything.
FROM docker.io/library/nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY dist/cv.html dist/cv.pdf /usr/share/nginx/html/
EXPOSE 80
