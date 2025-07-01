FROM joedupuis/claude_oauth:latest

USER root

ENV LANG="C.UTF-8"
ENV HOME=/root

### Additional packages for all languages ###

RUN apt-get update \
    && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        binutils \
        sudo \
        bzr \
        default-libmysqlclient-dev \
        dnsutils \
        gettext \
        git-lfs \
        gnupg2 \
        inotify-tools \
        iputils-ping \
        jq \
        libc6 \
        libc6-dev \
        libcurl4-openssl-dev \
        libdb-dev \
        libedit2 \
        libgcc-13-dev \
        libgcc1 \
        libgdbm-compat-dev \
        libgdbm-dev \
        libgdiplus \
        libgssapi-krb5-2 \
        libncursesw5-dev \
        libnss3-dev \
        libpq-dev \
        libpsl-dev \
        libpython3-dev \
        libstdc++-13-dev \
        libunwind8 \
        libuuid1 \
        libxml2-dev \
        libz3-dev \
        make \
        moreutils \
        netcat-openbsd \
        pkg-config \
        protobuf-compiler \
        python3-pip \
        rsync \
        software-properties-common \
        sqlite3 \
        swig3.0 \
        tzdata \
        unixodbc-dev \
        unzip \
        uuid-dev \
        zip \
        zlib1g \
        cmake \
        ccache \
        ninja-build \
        nasm \
        yasm \
        gawk \
        lsb-release \
        pipx \
        ca-certificates \
        iptables \
        docker.io \
        docker-compose \
    && rm -rf /var/lib/apt/lists/*

# Add claude user to docker group
RUN usermod -aG docker claude

### Additional Ruby versions (needs root for /opt/rbenv) ###

RUN export PATH="/opt/rbenv/bin:$PATH" && eval "$(rbenv init -)" && \
    RBENV_ROOT=/opt/rbenv /opt/rbenv/bin/rbenv install --force 3.3.8 && \
    RBENV_ROOT=/opt/rbenv /opt/rbenv/bin/rbenv install --force 3.2.3

### JAVA (needs root for apt-get) ###

ARG JAVA_VERSION=21
ARG GRADLE_VERSION=8.14
ARG GRADLE_DOWNLOAD_SHA256=61ad310d3c7d3e5da131b76bbf22b5a4c0786e9d892dae8c1658d4b484de3caa

ENV GRADLE_HOME=/opt/gradle
RUN apt-get update && apt-get install -y --no-install-recommends \
        openjdk-${JAVA_VERSION}-jdk \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LO "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle-${GRADLE_VERSION}-bin.zip" | sha256sum --check - \
    && unzip gradle-${GRADLE_VERSION}-bin.zip \
    && rm gradle-${GRADLE_VERSION}-bin.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle

### GO (needs root for /usr/local) ###

ARG GO_VERSION=1.23.8

ENV PATH=/usr/local/go/bin:$HOME/go/bin:$PATH
RUN mkdir /tmp/go \
    && cd /tmp/go \
    && ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') \
    && curl -O https://dl.google.com/go/go${GO_VERSION}.linux-${ARCH}.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-${ARCH}.tar.gz \
    && rm -rf /tmp/go

### BAZEL (needs root for /usr/local/bin) ###

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/') \
    && curl -L --fail https://github.com/bazelbuild/bazelisk/releases/download/v1.26.0/bazelisk-linux-${ARCH} -o /usr/local/bin/bazelisk \
    && chmod +x /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

### LLVM ###

RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"

### Setup scripts ###

COPY setup.sh /usr/local/bin/setup.sh
COPY entrypoint.sh /usr/local/bin/summoncircle-entrypoint
RUN chmod +x /usr/local/bin/setup.sh && \
    chmod +x /usr/local/bin/summoncircle-entrypoint

# Add GitHub to known hosts
RUN mkdir -p /home/claude/.ssh && \
    ssh-keyscan -t rsa github.com >> /home/claude/.ssh/known_hosts && \
    chown -R claude:claude /home/claude/.ssh

# Switch to claude user for language installations
USER claude
ENV HOME=/home/claude

### PYTHON ###

ARG PYENV_VERSION=v2.5.5
ARG PYTHON_VERSION=3.11.12

# Install pyenv
ENV PYENV_ROOT=/home/claude/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH
RUN git -c advice.detachedHead=0 clone --branch ${PYENV_VERSION} --depth 1 https://github.com/pyenv/pyenv.git "${PYENV_ROOT}" \
    && cd ${PYENV_ROOT} && src/configure && make -C src \
    && pyenv install 3.10 3.11.12 3.12 3.13 \
    && pyenv global ${PYTHON_VERSION}

# Install pipx for common global package managers
ENV PIPX_BIN_DIR=/home/claude/.local/bin
ENV PATH=$PIPX_BIN_DIR:$PATH
RUN pipx install poetry uv \
    && for pyv in $(ls ${PYENV_ROOT}/versions/); do \
        ${PYENV_ROOT}/versions/$pyv/bin/pip install --upgrade pip ruff black mypy pyright isort; \
    done
ENV UV_NO_PROGRESS=1

### NODE ###

ARG NVM_VERSION=v0.40.2
ARG NODE_VERSION=22

ENV NVM_DIR=/home/claude/.nvm
ENV COREPACK_DEFAULT_TO_LATEST=0
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV COREPACK_ENABLE_AUTO_PIN=0
ENV COREPACK_ENABLE_STRICT=0
RUN git -c advice.detachedHead=0 clone --branch ${NVM_VERSION} --depth 1 https://github.com/nvm-sh/nvm.git "${NVM_DIR}" \
    && echo "prettier\neslint\ntypescript" > $NVM_DIR/default-packages \
    && . $NVM_DIR/nvm.sh \
    && nvm install 18 \
    && nvm install 20 \
    && nvm install 22 \
    && nvm alias default $NODE_VERSION \
    && corepack enable \
    && corepack install -g yarn pnpm npm

### SWIFT ###

ARG SWIFT_VERSION=6.1

RUN mkdir /tmp/swiftly \
    && cd /tmp/swiftly \
    && curl -O https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz \
    && tar zxf swiftly-$(uname -m).tar.gz \
    && ./swiftly init --quiet-shell-followup -y \
    && bash -lc "swiftly install --use ${SWIFT_VERSION}" \
    && rm -rf /tmp/swiftly

### RUST ###

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y --profile minimal \
    && . "/home/claude/.cargo/env" \
    && rustup show

# Add all language paths to PATH for the claude user
RUN echo 'export PYENV_ROOT="/home/claude/.pyenv"' >> /home/claude/.bashrc && \
    echo 'export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"' >> /home/claude/.bashrc && \
    echo 'eval "$(pyenv init - bash)"' >> /home/claude/.bashrc && \
    echo 'export NVM_DIR="/home/claude/.nvm"' >> /home/claude/.bashrc && \
    echo 'source $NVM_DIR/nvm.sh' >> /home/claude/.bashrc && \
    echo '. /home/claude/.local/share/swiftly/env.sh' >> /home/claude/.bashrc && \
    echo 'export PATH="/home/claude/.cargo/bin:$PATH"' >> /home/claude/.bashrc && \
    echo 'export PIPX_BIN_DIR="/home/claude/.local/bin"' >> /home/claude/.bashrc && \
    echo 'export PATH="$PIPX_BIN_DIR:$PATH"' >> /home/claude/.bashrc

ENTRYPOINT ["/usr/local/bin/summoncircle-entrypoint"]