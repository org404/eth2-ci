FROM rustlang/rust:nightly-slim as builder
WORKDIR /usr/src/app

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y musl-tools && \
    rustup target add x86_64-unknown-linux-musl

RUN USER=root cargo new eth2tg
# Copying config/build files
COPY src src
COPY Cargo.toml .
RUN cargo install --target x86_64-unknown-linux-musl --path .

FROM scratch
COPY --from=builder /usr/local/cargo/bin/eth2tg .
CMD ["./eth2tg"]
