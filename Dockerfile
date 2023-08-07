#FROM node:7.6-alpine
FROM ubuntu:20.04 as builder


ARG NODE_VERSION=12.22.9
ARG NODE_DIST=linux-x64
ARG NODE_HOME=/usr/local/lib/nodejs
ARG NODE_MIRROR=https://registry.npmmirror.com/

ENV PATH ${PATH}:${NODE_HOME}/node-v${NODE_VERSION}-${NODE_DIST}/bin
ENV LANG C.UTF-8
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
#   && apk add git unzip \
RUN sed -i "s@http://.*archive.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list \
   && sed -i "s@http://.*security.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list \
   && export DEBIAN_FRONTEND=noninteractive \
   && apt update -y && apt upgrade -y && apt install -y git unzip wget vim gcc cmake g++ python make openssl  \
   && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
   && dpkg-reconfigure --frontend noninteractive tzdata \
    # 安装 node
   && mkdir -p ${NODE_HOME} && wget -q https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_DIST}.tar.xz && tar -xJf node-v${NODE_VERSION}-${NODE_DIST}.tar.xz -C ${NODE_HOME} && rm -rf node-v${NODE_VERSION}-${NODE_DIST}.tar.xz \
   && ${NODE_HOME}/node-v${NODE_VERSION}-${NODE_DIST}/bin/node -v && node -v && npm -v \
   && npm config set registry ${NODE_MIRROR} \
   && mkdir app \
   && cd app \
   && wget https://github.com/YMFE/yapi/archive/refs/tags/v1.12.0.zip \
   && unzip v1.12.0.zip \
   && cd yapi-1.12.0/ \
   && cp config_example.json ../config.json
# RUN cd /app/yapi-1.12.0/ && cat ../config.json | sed 's/127.0.0.1/10.0.10.3/g' | sed 's/test1/root/g' | sed 's/pass": "root"/pass": "yapi"/g' > ../config.json

RUN cd /app/yapi-1.12.0/ &&  npm install --production --registry $NODE_MIRROR

FROM ubuntu:20.04


ARG NODE_VERSION=12.22.9
ARG NODE_DIST=linux-x64
ARG NODE_HOME=/usr/local/lib/nodejs
ARG NODE_MIRROR=https://registry.npmmirror.com/

ENV PATH ${PATH}:${NODE_HOME}/node-v${NODE_VERSION}-${NODE_DIST}/bin
ENV LANG C.UTF-8

ENV TZ="Asia/Shanghai" HOME="/app"
WORKDIR ${HOME}

COPY --from=builder ${NODE_HOME}/node-v${NODE_VERSION}-${NODE_DIST} ${NODE_HOME}/node-v${NODE_VERSION}-${NODE_DIST}


COPY --from=builder /app/yapi-1.12.0/ /app/
COPY config.json /app/
EXPOSE 3001



CMD ["node","/app/server/app.js"]