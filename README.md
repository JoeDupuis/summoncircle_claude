# Summoncircle Claude

An extended Docker image based on `claude_oauth` that includes multiple programming languages and development tools.

## Base Image

This image extends `joedupuis/claude_oauth:latest` and adds:

## Languages Included

- **Python** (3.10, 3.11.12, 3.12, 3.13) via pyenv
- **Node.js** (18, 20, 22) via nvm
- **Ruby** (3.2.3, 3.3.8, 3.4.4) via rbenv
- **Go** (1.23.8)
- **Rust** (latest stable)
- **Java** (21) with Gradle
- **Swift** (6.1)
- **LLVM** (latest)
- **Bazel** (via bazelisk)

## Environment Variables

You can switch language versions using the following environment variables:

- `SUMMONCIRCLE_ENV_PYTHON_VERSION` (e.g., "3.12")
- `SUMMONCIRCLE_ENV_NODE_VERSION` (e.g., "20")
- `SUMMONCIRCLE_ENV_RUBY_VERSION` (e.g., "3.3.8")
- `SUMMONCIRCLE_ENV_RUST_VERSION` (e.g., "1.86.0")
- `SUMMONCIRCLE_ENV_GO_VERSION` (e.g., "1.22.5")
- `SUMMONCIRCLE_ENV_SWIFT_VERSION` (e.g., "5.9")

## Usage

```bash
docker run -it \
  -e SUMMONCIRCLE_ENV_PYTHON_VERSION=3.12 \
  -e SUMMONCIRCLE_ENV_NODE_VERSION=20 \
  joedupuis/summoncircle_claude:latest
```

## Additional Features

- GitHub SSH key configured in known_hosts
- All package managers pre-installed (pip, poetry, uv, npm, yarn, pnpm, cargo, etc.)
- Common linters and formatters pre-installed for each language
- Multi-architecture support (amd64 and arm64)

## Building Locally

```bash
# Build for your current architecture
docker build -t summoncircle_claude .

# Build for specific architecture
docker buildx build --platform linux/amd64 -t summoncircle_claude .
docker buildx build --platform linux/arm64 -t summoncircle_claude .
```

## GitHub Actions

The repository includes a GitHub Actions workflow that automatically builds and pushes multi-architecture images to Docker Hub when changes are pushed to the main branch.
