FROM alpine:latest

ENV GLIBC_VER=2.31-r0

RUN apk update; apk add --no-cache \
    	ansible \
        bash \
        bind-tools \
        binutils \
        curl \
        findutils \
        git \
        gnupg \
        go \
        jq \
        make \
        ncurses \
        neofetch \
        openssh \
        openssl \
        pciutils \
        procps \
        py3-pip \
        python3 \
        python3-dev \
        terraform \
        vim \
        yq \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        util-linux && \
    rm -rf /var/cache/apk/*

# TFSwitch
# https://tfswitch.warrensbox.com/Install/
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash

# kubectl / helm
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin && \
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod +x get_helm.sh && \
    ./get_helm.sh

# kubectl / helm plugins
RUN    helm plugin install https://github.com/databus23/helm-diff

RUN    git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
       ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx && \
       ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# install glibc compatibility for alpine - required for awscli2
RUN curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk && \
    curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk && \
    apk add --no-cache \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
        glibc-i18n-${GLIBC_VER}.apk && \
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8

# awscli2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws

# aws-iam-authenticator
RUN curl -o aws-iam-authenticator "https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator" && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin

# Copy Utils
COPY Utils /root/Utils

# CFSSL
RUN go install github.com/cloudflare/cfssl/cmd/cfssl@latest && \
    go install github.com/cloudflare/cfssl/cmd/cfssljson@latest

###### Fancy stuff! ##############################################################################################
# Add Banner
COPY motd /etc/motd

# Install Oh My Zsh Installer and Powerlevel10k
# - https://github.com/deluan/zsh-in-docker
# - https://github.com/romkatv/powerlevel10k
COPY zsh-in-docker.sh /tmp
RUN /tmp/zsh-in-docker.sh \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting

COPY p10k.zsh /root/.p10k.zsh

WORKDIR /root

ENTRYPOINT [ "/bin/zsh" ]
