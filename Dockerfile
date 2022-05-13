FROM google/cloud-sdk:385.0.0-slim as build

# Build target arch passed by BuildKit
ARG TARGETARCH

# Install deps
RUN apt-get update && \
  apt-get install -y -o APT::Install-Recommends=false -o APT::Install-Suggests=false \
  gzip libtool autoconf automake

# Download helm
ENV HELM_VERSION 3.8.2
RUN curl -o /tmp/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz -L0 "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
  && tar -zxvf /tmp/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz -C /tmp \
  && mv /tmp/linux-${TARGETARCH}/helm /usr/local/bin/helm

# Download stern
ENV STERN_VERSION 1.21.0
RUN curl -o /tmp/stern_${STERN_VERSION}_linux_${TARGETARCH}.tar.gz -LO "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_${TARGETARCH}.tar.gz" \
  && tar -zxvf /tmp/stern_${STERN_VERSION}_linux_${TARGETARCH}.tar.gz -C /tmp \
  && mv /tmp/stern /usr/local/bin/stern

# Download jq
ENV JQ_VERSION 1.6
RUN curl -o /tmp/jq-${JQ_VERSION}.tar.gz -L0 "https://github.com/stedolan/jq/archive/refs/tags/jq-${JQ_VERSION}.tar.gz" \
  && tar -zxvf /tmp/jq-${JQ_VERSION}.tar.gz -C /tmp

ENV ONIGURUMA_VERSION 6.9.7.1
RUN curl -o /tmp/oniguruma-${ONIGURUMA_VERSION}.tar.gz -L0 "https://github.com/kkos/oniguruma/archive/refs/tags/v${ONIGURUMA_VERSION}.tar.gz" \
  && tar -zxvf /tmp/oniguruma-${ONIGURUMA_VERSION}.tar.gz -C /tmp

# Compile JQ
RUN cd /tmp/jq-jq-${JQ_VERSION} \
  && rmdir modules/oniguruma \
  && mv /tmp/oniguruma-${ONIGURUMA_VERSION} /tmp/jq-jq-${JQ_VERSION}/modules/oniguruma \
  && autoreconf -fi \
  && ./configure --with-oniguruma=builtin --disable-maintainer-mode \
  && make LDFLAGS=-all-static -j4 \
  && mv jq /usr/local/bin/jq

# Cleanup unwanted files to keep the image light
RUN apt-get clean -q && apt-get autoremove --purge \
  && rm -rf /var/lib/apt/lists/*

FROM google/cloud-sdk:385.0.0-slim

LABEL org.opencontainers.image.source https://github.com/sparkfabrik/docker-aws-tools

# Build target arch passed by BuildKit
ARG TARGETARCH

# Install deps
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y -o APT::Install-Recommends=false -o APT::Install-Suggests=false \
  unzip vim

# Install aws-cli (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
RUN curl -o "/tmp/awscliv2.zip" -L0  "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  && unzip /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install \
  && rm -rf /tmp/aws /tmp/awscliv2.zip

# Download kubectl
RUN curl -o /usr/local/bin/kubectl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" \
  && chmod +x /usr/local/bin/kubectl

# Download kubens
RUN curl -o /usr/local/bin/kubens -LO "https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens" \
  && chmod +x /usr/local/bin/kubens

# Copy helm from previous stage
COPY --from=build /usr/local/bin/helm /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm

# Copy stern from previous stage
COPY --from=build /usr/local/bin/stern /usr/local/bin/stern
RUN chmod +x /usr/local/bin/stern

# Copy compiled jq from previous stage
COPY --from=build /usr/local/bin/jq /usr/local/bin/jq
RUN chmod +x /usr/local/bin/jq

# Overwrite kubens with custom kubens script (we don't have namespace list permission)
COPY scripts/kubens /usr/local/bin/kubens
RUN chmod +x /usr/local/bin/kubens

# Save history
ENV HISTFILE=/root/dotfiles/.bash_history
RUN mkdir mkdir -p /root/dotfiles

# Final settings
RUN echo "PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '" >> /etc/profile \
  && echo "source <(kubectl completion bash)" >> /etc/profile \
  && echo "alias k=\"kubectl\"" >> /etc/profile \
  && echo "source <(helm completion bash)" >> /etc/profile

# Cleanup unwanted files to keep the image light
RUN apt-get clean -q && apt-get autoremove --purge \
  && rm -rf /var/lib/apt/lists/*

# Entrypoint configuration
RUN mkdir -p /docker-entrypoint.d
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY scripts/docker-entrypoint.d /docker-entrypoint.d
RUN chmod +x /docker-entrypoint.sh \
  && find /docker-entrypoint.d -type f -exec chmod +x {} +

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "bash", "-il" ]
