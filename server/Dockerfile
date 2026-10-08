FROM ubuntu:24.04

ARG GODOT_VERSION=4.6
ENV DEBIAN_FRONTEND=noninteractive
ENV ASTRUM_DATA_DIR=/data
ENV ASTRUM_SERVER_PORT=2456

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip \
        libasound2t64 libegl1 libfontconfig1 libgl1 libpulse0 libwayland-client0 \
        libudev1 libx11-6 libxcursor1 libxext6 libxi6 libxinerama1 libxkbcommon0 \
        libxrandr2 libxrender1 \
    && curl -fsSL "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip \
    && unzip /tmp/godot.zip -d /usr/local/bin \
    && mv "/usr/local/bin/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip \
    && apt-get purge -y --auto-remove curl unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY project.godot main.tscn server.gd ./
RUN mkdir -p /data

EXPOSE 2456/tcp
VOLUME ["/data"]
ENTRYPOINT ["godot", "--headless", "--path", "/app"]
