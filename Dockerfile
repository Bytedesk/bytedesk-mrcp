# ---- UniMRCP Server Docker Image ----
# The bundled binaries are compiled for Linux x86_64 (ELF, GLIBC 2.2.5+).
# Build on Apple Silicon / ARM hosts:
#   docker buildx build --platform linux/amd64 -t bytedesk/mrcp-server:latest .

FROM --platform=linux/amd64 debian:bullseye-slim

# Install only the GCC/glibc runtime libraries that are NOT bundled in ./lib
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgcc-s1 \
        libstdc++6 \
        uuid-runtime \
    && rm -rf /var/lib/apt/lists/*

# The binary's interpreter (dynamic linker) and rpath point to
# /opt/compiler/gcc-8.2/lib64 and /opt/compiler/gcc-8.2/lib.
# Symlink the system GCC runtime libs and the dynamic linker so the
# loader can find everything at the expected paths.
RUN mkdir -p /opt/compiler/gcc-8.2/lib64 /opt/compiler/gcc-8.2/lib && \
    ln -sf /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2  /opt/compiler/gcc-8.2/lib64/ld-linux-x86-64.so.2  && \
    ln -sf /lib/x86_64-linux-gnu/libgcc_s.so.1          /opt/compiler/gcc-8.2/lib64/libgcc_s.so.1  && \
    ln -sf /usr/lib/x86_64-linux-gnu/libstdc++.so.6     /opt/compiler/gcc-8.2/lib64/libstdc++.so.6

WORKDIR /opt/mrcp-server

# Copy the entire mrcp-server directory into the image.
# .so files in plugin/ are managed by Git LFS; ensure they are present locally
# before building (git lfs pull).
COPY mrcp-server/ .

# Ensure required directories exist and binaries are executable
RUN mkdir -p log var audio && \
    chmod +x bin/unimrcpserver bin/unimrcpclient 2>/dev/null || true

# ---- Ports ----
# 1544  – MRCP (TCP)
# 1554  – RTSP (TCP)
# 5060  – SIP  (UDP + TCP)
# 5000-6000 – RTP media (UDP); expose a representative subset
EXPOSE 1544
EXPOSE 1554
EXPOSE 5060/udp
EXPOSE 5060/tcp
EXPOSE 5000-6000/udp

# ---- Entrypoint ----
# The server is started with working directory = /opt/mrcp-server so that
# relative paths in dirlayout.xml (conf, plugin, log, data) resolve correctly.
CMD ["./bin/unimrcpserver", "-r", "."]
