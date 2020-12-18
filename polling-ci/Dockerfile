FROM alpine
RUN apk --update add git less openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

WORKDIR /git
COPY . .

ENTRYPOINT ["/bin/sh"]
CMD ["./custom_ci.sh"]
