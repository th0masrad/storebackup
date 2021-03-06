ARG    BASE_IMAGE="ubuntu"
ARG    BASE_IMAGE_TAG="20.04"
ARG    TARGETOS="linux"
ARG    TARGETARCH="amd64"
ARG    TARGETPLATFORM="${TARGETOS}/${TARGETARCH}"
FROM   --platform=${TARGETPLATFORM} ${BASE_IMAGE}:${BASE_IMAGE_TAG}
# Arguments before the FROM command have to be repeated when reused
ARG    BASE_IMAGE
ARG    BASE_IMAGE_TAG
ARG    TARGETOS
ARG    TARGETARCH
ARG    TARGETPLATFORM

# Re-usable variables during build
ARG    ENTRYPOINT_NAME="docker-entrypoint.sh"
ARG    ENTRYPOINT_LOCAL="dockerimage/${ENTRYPOINT_NAME}"
ARG    ENTRYPOINT_DOCKER="/${ENTRYPOINT_NAME}"
ARG    VOLUME_INPUT="/in"
ARG    VOLUME_OUTPUT="/out"
ARG    VOLUME_STOREBACKUPCONFIGDIR="/storebackup.d"
ARG    IMAGE_BUILD_DATE="Mo 23. Aug 05:23:15 UTC 2021"
ARG    IMAGE_VERSION="tr1.0"
ARG    IMAGE_REVERSION="0"
ARG    IMAGE_AUTHORS="Thomas Raddatz"
ARG    IMAGE_URL="https://hub.docker.com/repository/docker/th0masrad/storebackup/"
ARG    IMAGE_DOCUMENTATION="https://github.com/th0masrad/storebackup#readme"
ARG    IMAGE_SOURCE="https://github.com/th0masrad/storebackup"
ARG    IMAGE_VENDOR="Thomas Raddatz"
ARG    IMAGE_LICENSES="GNU GENERAL PUBLIC LICENSE GPL-v3"
ARG    IMAGE_TITLE="storeBackup-${TARGETOS}_${TARGETARCH}"
ARG    IMAGE_DESCRIPTION="A Docker image for storeBackup, based on ${BASE_IMAGE} ${BASE_IMAGE_TAG}."
ARG    STOREBACKUP_AUTHORS="Heinz-Josef Claes, Francesco Potorti, Arthur Korn, Nikolaus Rath, W. David Shields, Frank Brungräber et al."
ARG    STOREBACKUP_URL="https://savannah.nongnu.org/projects/storebackup/"
ARG    STOREBACKUP_DOCUMENTATION="http://www.nongnu.org/storebackup/"
ARG    STOREBACKUP_SOURCE="https://download.savannah.nongnu.org/releases/storebackup/"
ARG    STOREBACKUP_VENDOR="Heinz-Josef Claes"
ARG    STOREBACKUP_LICENSES="GNU GENERAL PUBLIC LICENSE GPL-v3"
ARG    STOREBACKUP_DESCRIPTION="storeBackup is a backup utility that stores files on other disks. It's able to compress data, and recognize copying and moving of files and directories (deduplication), and unifies the advantages of traditional full and incremental backups. It can handle big image files with block-wise changes efficiently. Depending on its contents, every file is stored only once on disk. Tools for analyzing backup data and restoring are provided. Once archived, files are accessible by mounting file systems (locally, or via Samba or NFS). It is easy to install and configure. Additional features are backup consistency checking, offline backups, and replication of backups."
ARG    STOREBACKUP_STOREBACKUPCONFIGDIR="/etc/storebackup.d"

# annotation labels according to
# https://github.com/opencontainers/image-spec/blob/v1.0.1/annotations.md#pre-defined-annotation-keys
LABEL  org.opencontainers.image.created=${IMAGE_BUILD_DATE} \
       org.opencontainers.image.authors=${IMAGE_AUTHORS} \
       org.opencontainers.image.url=${IMAGE_URL} \
       org.opencontainers.image.documentation=${IMAGE_DOCUMENTATION} \
       org.opencontainers.image.source=${IMAGE_SOURCE} \
       org.opencontainers.image.version=${IMAGE_VERSION} \
       org.opencontainers.image.revision=${IMAGE_REVERSION} \
       org.opencontainers.image.vendor=${IMAGE_VENDOR} \
       org.opencontainers.image.licenses=${IMAGE_LICENSES} \
       org.opencontainers.image.title=${IMAGE_TITLE} \
       org.opencontainers.image.description=${IMAGE_DESCRIPTION} \
# non-standard labels
       org.storebackup.authors=${STOREBACKUP_AUTHORS} \
       org.storebackup.url=${STOREBACKUP_URL} \
       org.storebackup.documentation=${STOREBACKUP_DOCUMENTATION} \
       org.storebackup.source=${STOREBACKUP_SOURCE} \
       org.storebackup.vendor=${STOREBACKUP_VENDOR} \
       org.storebackup.licenses=${STOREBACKUP_LICENSES} \
       org.storebackup.description=${STOREBACKUP_DESCRIPTION}

ENV    TIMEZONE="Etc/UTC"

# Install base environment
COPY   ${ENTRYPOINT_LOCAL} ${ENTRYPOINT_DOCKER}

VOLUME ["${VOLUME_INPUT}", "${VOLUME_OUTPUT}", "${VOLUME_STOREBACKUPCONFIGDIR}"]

HEALTHCHECK --interval=300s --timeout=10s --start-period=60s --retries=1 CMD /docker-entrypoint.sh health-check

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD    ["continous"]


RUN    echo "######################################" \
    && echo "apt-get update" \
    && echo "######################################" \
    && apt-get update \
    && echo \
    \
    && echo "######################################" \
    && echo "apt-get upgrade" \
    && echo "######################################" \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --assume-yes \
    && echo \
    \
    && echo "######################################" \
    && echo "apt-get install" \
    && echo "######################################" \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests --assume-yes  \
        cron \
        storebackup \
        tzdata \
        xz-utils \
    && echo \
    \
    && echo "######################################" \
    && echo "Image Info" \
    && echo "######################################" \
    && echo "org.opencontainers.image.created=${IMAGE_BUILD_DATE}"           > /image_info \
    && echo "org.opencontainers.image.authors=${IMAGE_AUTHORS}"             >> /image_info \
    && echo "org.opencontainers.image.url=${IMAGE_URL}"                     >> /image_info \
    && echo "org.opencontainers.image.documentation=${IMAGE_DOCUMENTATION}" >> /image_info \
    && echo "org.opencontainers.image.source=${IMAGE_SOURCE}"               >> /image_info \
    && echo "org.opencontainers.image.version=${IMAGE_VERSION}"             >> /image_info \
    && echo "org.opencontainers.image.revision=${IMAGE_REVERSION}"          >> /image_info \
    && echo "org.opencontainers.image.vendor=${IMAGE_VENDOR}"               >> /image_info \
    && echo "org.opencontainers.image.licenses=${IMAGE_LICENSES}"           >> /image_info \
    && echo "org.opencontainers.image.title=${IMAGE_TITLE}"                 >> /image_info \
    && echo "org.opencontainers.image.description=${IMAGE_DESCRIPTION}"     >> /image_info \
    && echo "org.storebackup.authors=${STOREBACKUP_AUTHORS}"                >> /image_info \
    && echo "org.storebackup.url=${STOREBACKUP_URL}"                        >> /image_info \
    && echo "org.storebackup.documentation=${STOREBACKUP_DOCUMENTATION}"    >> /image_info \
    && echo "org.storebackup.source=${STOREBACKUP_SOURCE}"                  >> /image_info \
    && echo "org.storebackup.vendor=${STOREBACKUP_VENDOR}"                  >> /image_info \
    && echo "org.storebackup.licenses=${STOREBACKUP_LICENSES}"              >> /image_info \
    && echo "org.storebackup.description=${STOREBACKUP_DESCRIPTION}"        >> /image_info \
    && echo \
    \
    && echo "######################################" \
    && echo "storeBackup.d" \
    && echo "######################################" \
    && rmdir -v "${STOREBACKUP_STOREBACKUPCONFIGDIR}" \
    && ln -sv "${VOLUME_STOREBACKUPCONFIGDIR}" "${STOREBACKUP_STOREBACKUPCONFIGDIR}" \
    && echo \
    \
    && echo "######################################" \
    && echo "apt-get autoremove" \
    && echo "######################################" \
    && apt-get autoremove \
    && echo \
    \
    && echo "######################################" \
    && echo "apt-get clean" \
    && echo "######################################" \
    && apt-get clean \
    && echo \
    \
    && echo "######################################" \
    && echo "rm" \
    && echo "######################################" \
    && rm -rfv /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/* ~/.[^.] ~/.??* ~/* \
    && find /etc/cron.*/* \! \( -name storebackup -o -name .placeholder -o -name 0anacron \) -exec echo rm -rfv {} + \ 
    && echo \
    \
    && echo "######################################" \
    && echo "Done:" \
    && echo "######################################" \
    && cat /image_info
