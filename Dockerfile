FROM amazon/aws-cli:2.5.7 as build

# Build target arch passed by BuildKit
ARG TARGETARCH

# Install deps
RUN yum install -y tar gzip libtool make autoconf automake git

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
RUN yum clean all \
  && rm -rf /var/cache/yum

FROM amazon/aws-cli:2.5.7

LABEL org.opencontainers.image.source https://github.com/sparkfabrik/docker-aws-tools

# Build target arch passed by BuildKit
ARG TARGETARCH

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

# Final settings
RUN echo "PS1='\[\033[1;36m\]\u\[\033[1;31m\]@\[\033[1;32m\]\h:\[\033[1;35m\]\w\[\033[1;31m\]\$\[\033[0m\] '" >> /etc/profile \
  && echo "source <(kubectl completion bash)" >> /etc/profile \
  && echo "alias k=\"kubectl\"" >> /etc/profile \
  && echo "source <(helm completion bash)" >> /etc/profile

# Entrypoint configuration
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "bash", "-il" ]
