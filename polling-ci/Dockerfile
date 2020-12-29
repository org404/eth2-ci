FROM alpine
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && apk add -U --no-cache git less make docker openssh bash \
 && rm -rf /var/lib/apt/lists/*

COPY . .

# ENTRYPOINT ["dash"]
CMD ["bash", "./custom_ci.sh"]
