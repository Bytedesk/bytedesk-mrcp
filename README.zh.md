# bytedesk-mrcp

欢迎使用百度语音提供的mrcpserver服务

本MRCP Server端，集成了语音识别(ASR)和语音合成(TTS)两种能力，用户可分别单独使用某一种或同时使用。

**Language:** [English](README.md) | [中文](README.zh.md)

> **Mirror:** [GitHub](https://github.com/Bytedesk/bytedesk-mrcp) | [Gitee](https://gitee.com/bytedesk/bytedesk-mrcp)

一 目录结构介绍

1. compiler.tar.gz, 本程序运行依赖的百度内部自带的gcc-8.2编译器库文件
2. bootstrap.sh: 解压安装gcc-8.2的脚本
3. mrcp_server: 目录下存放本程序运行文件
    1. audio：用来保存用户说话和服务端下发播报的音频。
    2. bin: 一些工具程序。其中的unimrcpserver就是我们要启动的服务。
    3. conf: 配置文件。unimrcpserver.xml为mrcp框架的配置文件；mrcp-asr.conf为ASR插件运行的配置文件,mrcp-proxy.conf为TTS插件运行的配置文件。
    4. data: 一些资源文件。
    5. lib: 程序运行依赖的库文件。
    6. log: 日志输出。
    7. plugin：包含ASR和TTS的so库。

二 运行准备

1. 首先要使用root权限执行bootstrap.sh，将compiler.tar.gz解压安装到/opt/目录,也可手动解压.
    确认解压完后路径是形如：/opt/compiler/gcc-8.2/的形式。
2. 本server ip可以在./conf/unimrcpserver.xml文件中将unimrcpserver->property->ip的值修改为本机对外服务网口的IP，sip端口5060可酌情修改。
3. ./conf/unimrcpserver.xml文件中, 高并发时需要修改的参数有：max-connection-count表示最大连接数，需要时请修改;
   rtp端口范围默认1000，必要时需要修改：rtp-port-min为5000，修改rtp-port-max为8000，表示共3千个端口
4. ./conf/mrcp-asr.conf中修改AUDIO_CONTROLLER_ADDR的值为要连接的百度服务地址(默认值当前有效),
    AUTH_APPID和AUTH_APPKEY修改为用户向百度申请的值.
    其它字段基本不用调整！
5. ./conf/comlog.conf是日志相关配置，一般地不需要修改。4和16代表日志打印等级，如不需要debug日志调试，可都设为4
6. 根据在第2中手动修改的server ip，在./conf/unimrcpserver_control.conf文件，将其中的_check_cmd_pro中的启动监听的ip值设置为相应的server ip;

三 启动方法

1. 一般的，在调试部署初期，可以使用如下命令启动程序：./bin/unimrcpserver -r . &，可查看输出，方便定位问题。
2. 做为服务程序运行时，建议使用提供的supervise以守护进程的形式启动. 使用./bin/unimrcpserver_control start/stop/restart进行程序的启动/停止/重启

四 说明

1. 开启音频保存后，audio目录下的文件请定时清理。log目录下的日志也需要定时清理

五 Docker 使用说明

默认镜像为阿里云仓库（国内访问最快）：`registry.cn-hangzhou.aliyuncs.com/bytedesk/mrcp`

Docker Hub 镜像地址：`bytedesk/mrcp`，可通过环境变量切换：
```bash
MRCP_IMAGE=bytedesk/mrcp docker compose up -d
```

注意事项：
- 由于仓库内自带的 bin/unimrcpserver 为 Linux x86_64 ELF 二进制，Docker 镜像仅支持 **linux/amd64**。
- plugin 目录下的大型 .so 文件通过 Git LFS 管理，本地构建前请先执行 `git lfs pull`。
- 镜像已在 Dockerfile 中预置了 gcc 运行时库和动态链接器的 symlink，无需额外执行 bootstrap.sh。

六 快速启动（从镜像仓库拉取运行）

`docker-compose.yaml` 默认配置为拉取阿里云镜像直接运行。

1. 准备配置文件目录（镜像内置了默认配置，外部覆盖需要完整配置文件）：

```bash
mkdir -p conf docker/log docker/audio
cp mrcp-server/conf/unimrcpserver.xml conf/
cp mrcp-server/conf/mrcp-asr.conf conf/
# 编辑 conf/unimrcpserver.xml 修改 IP 地址
# 编辑 conf/mrcp-asr.conf 修改 AUTH_APPID / AUTH_APPKEY
```

> ⚠️ **重要**：如果使用外部 conf 目录挂载，必须包含完整的配置文件（至少 `unimrcpserver.xml`、`mrcp-asr.conf`、`dirlayout.xml`），否则容器将因缺少配置而启动失败。

2. 拉取并启动：

```bash
docker compose up -d
```

3. 查看日志：

```bash
docker compose logs -f mrcp-server
```

4. 停止服务：

```bash
docker compose down
```

七 本地构建镜像运行

如需修改源码或插件后自行构建，取消 `docker-compose.yaml` 中 `build:` 段的注释：

```yaml
    # ---- 如需本地构建，取消以下注释 ----
    build:
      context: .
      dockerfile: Dockerfile
      platforms:
        - linux/amd64
```

然后执行：

```bash
git lfs pull
docker compose build
docker compose up -d
```

> Apple Silicon 机器上如果构建失败，请使用：
> ```bash
> DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build
> ```

八 使用外部 conf 覆盖内置配置

1. 默认会把 mrcp-server/conf 挂载到容器内的 /opt/mrcp-server/conf。
1. 如果希望使用外部目录覆盖配置，可以在仓库根目录创建 conf 目录，并复制需要修改的配置文件。
1. 然后通过环境变量指定该目录：

```bash
mkdir -p conf
cp mrcp-server/conf/unimrcpserver.xml conf/
cp mrcp-server/conf/mrcp-asr.conf conf/

MRCP_CONF_DIR=./conf docker compose up -d
```

1. docker-compose.yaml 同时支持以下环境变量：

```bash
MRCP_IMAGE=registry.cn-hangzhou.aliyuncs.com/bytedesk/mrcp
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

九 镜像打包与发布

1. 工作流文件：.github/workflows/mrcp-docker.yml
1. 触发方式：
    - 推送标签 v1.0.0
    - 在 GitHub Actions 页面手动执行 workflow_dispatch
1. 工作流会执行以下动作：
    - checkout 仓库并拉取 Git LFS 文件
    - 构建 linux/amd64 Docker 镜像
    - 按需推送到 Docker Hub 和阿里云镜像仓库
    - 在标签发布时创建 GitHub Release
1. 需要预先配置的 GitHub Secrets：
    - DOCKER_HUB_USERNAME
    - DOCKER_HUB_ACCESS_TOKEN
    - ALIYUN_DOCKER_USERNAME
    - ALIYUN_DOCKER_PASSWORD

十 常见注意事项

1. 如果在 macOS Apple Silicon 上本地构建失败，请改用：

```bash
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build
```

1. RTP 使用 5000-6000/udp 端口范围，部署到云主机或容器平台时需要同步放通该端口段。
1. 如果修改了对外服务 IP、SIP 端口或 RTP 范围，请同步检查 mrcp-server/conf/unimrcpserver.xml 和 mrcp-server/conf/unimrcpserver_control.conf 中的相关配置。
