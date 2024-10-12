FROM openjdk:11-jre

ARG CANAL_DOWNLOAD_NAME canal.adapter
ARG CANAL_COMPONENT_NAME canal-adapter
ARG CANAL_COMPONENT_VERSION 1.1.7
ARG BUILD_DATE
ARG VCS_REF 

ENV CANAL_ADAPTER_DOWNLOAD_URL=https://github.com/alibaba/canal/releases/download/canal-${CANAL_COMPONENT_VERSION}/${CANAL_DOWNLOAD_NAME}-${CANAL_COMPONENT_VERSION}.tar.gz

RUN  mkdir -p /data/canal/${CANAL_COMPONENT_NAME} \
    && curl -fSL "$CANAL_ADAPTER_DOWNLOAD_URL"  -o ${CANAL_DOWNLOAD_NAME}.tar.gz \
    && tar -xzf ${CANAL_DOWNLOAD_NAME}.tar.gz -C /data/canal/${CANAL_COMPONENT_NAME} \
    && rm ${CANAL_DOWNLOAD_NAME}.tar.gz* 

LABEL org.label-schema.vendor="wanghongxing<wanghongxing@gmail.com>" \
    org.label-schema.name="${CANAL_COMPONENT_NAME}" \
    org.label-schema.build-date="${BUILD_DATE}" \
    org.label-schema.description="${CANAL_COMPONENT_NAME}." \
    org.label-schema.url="https://hongxing.tech/" \
    org.label-schema.schema-version="${CANAL_COMPONENT_VERSION}"	\
    org.label-schema.vcs-type="Git" \
    org.label-schema.vcs-ref="${VCS_REF}" \
    org.label-schema.vcs-url="https://github.com/wanghongxing/canal-docker" 

ENV TZ=Asia/Shanghai
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8


WORKDIR /data/canal/${CANAL_COMPONENT_NAME}

ADD scripts/${CANAL_COMPONENT_NAME}.sh /run_scripts/entrypoint.sh
RUN chmod +x /run_scripts/*.sh

ENTRYPOINT ["/run_scripts/entrypoint.sh"]