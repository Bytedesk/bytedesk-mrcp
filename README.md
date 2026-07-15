# bytedesk-mrcp

Welcome to the MRCP Server service powered by Baidu Speech.

This MRCP Server integrates both Automatic Speech Recognition (ASR) and Text-to-Speech (TTS) capabilities. You may use either one independently or both together.

**Language:** [English](README.md) | [中文](README.zh.md)

> **Mirror:** [GitHub](https://github.com/Bytedesk/bytedesk-mrcp) | [Gitee](https://gitee.com/bytedesk/bytedesk-mrcp)

## 1. Directory Structure

1. `compiler.tar.gz` — Bundled GCC 8.2 compiler runtime libraries required by the application.
2. `bootstrap.sh` — Script to extract and install GCC 8.2.
3. `mrcp-server/` — Runtime files for the service:
    1. `audio/` — Stores audio recordings of user speech and server-side playback.
    2. `bin/` — Utility programs. `unimrcpserver` is the main server binary.
    3. `conf/` — Configuration files. `unimrcpserver.xml` is the MRCP framework configuration; `mrcp-asr.conf` is the ASR plugin configuration; `mrcp-proxy.conf` is the TTS plugin configuration.
    4. `data/` — Resource files.
    5. `lib/` — Shared libraries required at runtime.
    6. `log/` — Log output directory.
    7. `plugin/` — ASR and TTS shared object (`.so`) plugins.

## 2. Setup Prerequisites

1. First, run `bootstrap.sh` as **root** (or extract manually) to install `compiler.tar.gz` under `/opt/`. After extraction the path should be `/opt/compiler/gcc-8.2/`.
2. Set the server IP in `./conf/unimrcpserver.xml`: change the value of `unimrcpserver → property → ip` to the IP address of the network interface that serves external traffic. The SIP port (default `5060`) may also be adjusted as needed.
3. For high-concurrency scenarios, tune the following parameters in `./conf/unimrcpserver.xml`:
   - `max-connection-count` — Maximum number of connections.
   - RTP port range (default 1000 ports): set `rtp-port-min` to `5000` and `rtp-port-max` to `8000` for 3,000 ports.
4. In `./conf/mrcp-asr.conf`, update:
   - `AUDIO_CONTROLLER_ADDR` — The Bauda service address (the default is currently valid).
   - `AUTH_APPID` and `AUTH_APPKEY` — Credentials obtained from Baidu.
   - Other fields generally do not need adjustment.
5. `./conf/comlog.conf` — Logging configuration. `4` and `16` represent log verbosity levels. Set both to `4` if debug logging is not needed.
6. After setting the server IP in step 2, update `./conf/unimrcpserver_control.conf`: set the listening IP in `_check_cmd_pro` to the same server IP.

## 3. Starting the Server

1. During initial debugging and deployment, start the server in the foreground to see console output:

   ```bash
   ./bin/unimrcpserver -r . &
   ```

2. For production deployment, run as a daemon using the provided `supervise` script:

   ```bash
   ./bin/unimrcpserver_control start
   ./bin/unimrcpserver_control stop
   ./bin/unimrcpserver_control restart
   ```

## 4. Notes

1. When audio saving is enabled, clean up files under the `audio/` directory regularly. Log files under `log/` should also be purged periodically.

## 5. Docker Overview

1. The `docker-compose.yaml` in the repository root is for local demonstration and debugging — it quickly starts the MRCP Server from the current directory.
2. The GitHub Actions workflow at `.github/workflows/mrcp-docker.yml` builds and pushes Docker images; it is **not** intended for local execution.
3. Because the bundled `bin/unimrcpserver` is a Linux x86_64 ELF binary, the Docker image supports **linux/amd64 only**.
4. Large `.so` files under `plugin/` are managed by **Git LFS**. Run `git lfs pull` before building the image to ensure the real files are present locally.

## 6. Running Locally with Docker Compose

1. Prepare your Docker environment. On Apple Silicon machines, enable Buildx and build for the `linux/amd64` platform.
2. First-time image build:

   ```bash
   git lfs pull
   docker compose build
   ```

3. Start the service:

   ```bash
   docker compose up -d
   ```

4. View logs:

   ```bash
   docker compose logs -f mrcp-server
   ```

5. Stop the service:

   ```bash
   docker compose down
   ```

## 7. Overriding Configuration with an External `conf` Directory

1. By default, `mrcp-server/conf` is mounted into the container at `/opt/mrcp-server/conf`.
2. To override with an external directory, create a `conf` folder in the repository root and copy only the files you need to customize.
3. Specify the directory via an environment variable:

   ```bash
   mkdir -p conf
   cp mrcp-server/conf/unimrcpserver.xml conf/
   cp mrcp-server/conf/mrcp-asr.conf conf/

   MRCP_CONF_DIR=./conf docker compose up -d
   ```

4. `docker-compose.yaml` supports the following environment variables:

   ```bash
   MRCP_IMAGE=bytedesk/mrcp
   MRCP_TAG=latest
   MRCP_CONTAINER_NAME=mrcp-server
   MRCP_PORT=1544
   RTSP_PORT=1554
   SIP_PORT=5060
   RTP_PORT_RANGE=5000-6000
   MRCP_CONF_DIR=./conf
   MRCP_LOG_DIR=./docker/log
   MRCP_AUDIO_DIR=./docker/audio
   ```

## 8. Image Build & Release

1. Workflow file: `.github/workflows/mrcp-docker.yml`
2. Triggers:
   - Pushing a tag (e.g. `v1.0.0`)
   - Manually running `workflow_dispatch` from the GitHub Actions UI
3. The workflow performs the following steps:
   - Checks out the repository and pulls Git LFS files
   - Builds a `linux/amd64` Docker image
   - Optionally pushes to Docker Hub and Alibaba Cloud Container Registry
   - Creates a GitHub Release when triggered by a tag
4. Required GitHub Secrets:
   - `DOCKER_HUB_USERNAME`
   - `DOCKER_HUB_ACCESS_TOKEN`
   - `ALIYUN_DOCKER_USERNAME`
   - `ALIYUN_DOCKER_PASSWORD`

## 9. Common Issues & Tips

1. If the build fails on macOS Apple Silicon, use:

   ```bash
   DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build
   ```

2. RTP uses the UDP port range **5000–6000**. When deploying to a cloud host or container platform, ensure this port range is open.
3. If you change the external service IP, SIP port, or RTP port range, remember to update the corresponding settings in both `mrcp-server/conf/unimrcpserver.xml` and `mrcp-server/conf/unimrcpserver_control.conf`.
