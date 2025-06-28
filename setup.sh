#!/bin/bash --login

set -euo pipefail

SUMMONCIRCLE_ENV_PYTHON_VERSION=${SUMMONCIRCLE_ENV_PYTHON_VERSION:-}
SUMMONCIRCLE_ENV_NODE_VERSION=${SUMMONCIRCLE_ENV_NODE_VERSION:-}
SUMMONCIRCLE_ENV_RUST_VERSION=${SUMMONCIRCLE_ENV_RUST_VERSION:-}
SUMMONCIRCLE_ENV_GO_VERSION=${SUMMONCIRCLE_ENV_GO_VERSION:-}
SUMMONCIRCLE_ENV_SWIFT_VERSION=${SUMMONCIRCLE_ENV_SWIFT_VERSION:-}
SUMMONCIRCLE_ENV_RUBY_VERSION=${SUMMONCIRCLE_ENV_RUBY_VERSION:-}

echo "Configuring language runtimes..."

# For Python and Node, always run the install commands so we can install
# global libraries for linting and formatting. This just switches the version.

# For others (e.g. rust), to save some time on bootup we only install other language toolchains
# if the versions differ.

if [ -n "${SUMMONCIRCLE_ENV_PYTHON_VERSION}" ]; then
    echo "# Python: ${SUMMONCIRCLE_ENV_PYTHON_VERSION}"
    pyenv global "${SUMMONCIRCLE_ENV_PYTHON_VERSION}"
fi

if [ -n "${SUMMONCIRCLE_ENV_NODE_VERSION}" ]; then
    echo "# Node.js: ${SUMMONCIRCLE_ENV_NODE_VERSION}"
    nvm alias default "${SUMMONCIRCLE_ENV_NODE_VERSION}"
    nvm use "${SUMMONCIRCLE_ENV_NODE_VERSION}"
    corepack enable
    corepack install -g yarn pnpm npm
fi

if [ -n "${SUMMONCIRCLE_ENV_RUBY_VERSION}" ]; then
    echo "# Ruby: ${SUMMONCIRCLE_ENV_RUBY_VERSION}"
    rbenv global "${SUMMONCIRCLE_ENV_RUBY_VERSION}"
fi

if [ -n "${SUMMONCIRCLE_ENV_RUST_VERSION}" ]; then
    current=$(rustc --version | awk '{print $2}')   # ==> 1.86.0
    echo "# Rust: ${SUMMONCIRCLE_ENV_RUST_VERSION} (default: ${current})"
    if [ "${current}" != "${SUMMONCIRCLE_ENV_RUST_VERSION}" ]; then
        rustup toolchain install --no-self-update "${SUMMONCIRCLE_ENV_RUST_VERSION}"
        rustup default "${SUMMONCIRCLE_ENV_RUST_VERSION}"
        # Pre-install common linters/formatters
        # clippy is already installed
    fi
fi

if [ -n "${SUMMONCIRCLE_ENV_GO_VERSION}" ]; then
    current=$(go version | awk '{print $3}')   # ==> go1.23.8
    echo "# Go: go${SUMMONCIRCLE_ENV_GO_VERSION} (default: ${current})"
    if [ "${current}" != "go${SUMMONCIRCLE_ENV_GO_VERSION}" ]; then
        go install "golang.org/dl/go${SUMMONCIRCLE_ENV_GO_VERSION}@latest"
        "go${SUMMONCIRCLE_ENV_GO_VERSION}" download
        # Place new go first in PATH
        echo "export PATH=$("go${SUMMONCIRCLE_ENV_GO_VERSION}" env GOROOT)/bin:\$PATH" >> /etc/profile
        # Pre-install common linters/formatters
        golangci-lint --version 2>/dev/null || go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    fi
fi

if [ -n "${SUMMONCIRCLE_ENV_SWIFT_VERSION}" ]; then
    current=$(swift --version 2>/dev/null | awk -F'version ' '{print $2}' | awk '{print $1}')   # ==> 6.1
    echo "# Swift: ${SUMMONCIRCLE_ENV_SWIFT_VERSION} (default: ${current})"
    if [ "${current}" != "${SUMMONCIRCLE_ENV_SWIFT_VERSION}" ]; then
        swiftly install --use "${SUMMONCIRCLE_ENV_SWIFT_VERSION}"
    fi
fi