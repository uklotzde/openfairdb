# just manual: https://github.com/casey/just/#readme

# Ignore the .env file that is only used by the web service
set dotenv-load := false

_default:
    @just --list

# Format source code
fmt:
    cargo fmt --all
    cd ofdb-app-clearance && cargo fmt

# Check all crates individually (takes a long time)
check:
    cargo check --locked --all-features --all-targets -p ofdb-boundary
    cargo check --locked --all-features --all-targets -p ofdb-core
    cargo check --locked --all-features --all-targets -p ofdb-entities
    cargo check --locked --all-features --all-targets -p ofdb-gateways

# Run clippy on the workspace (both dev and release profile)
clippy:
    cargo clippy --locked --workspace --all-targets --no-deps --profile dev -- -D warnings --cap-lints warn
    cargo clippy --locked --workspace --all-targets --no-deps --profile release -- -D warnings --cap-lints warn
    cd ofdb-app-clearance && cargo clippy --locked --no-deps --target wasm32-unknown-unknown --all-features --all-targets --profile dev -- -D warnings --cap-lints warn
    cd ofdb-app-clearance && cargo clippy --locked --no-deps --target wasm32-unknown-unknown --all-features --all-targets --profile release -- -D warnings --cap-lints warn

# Fix lint warnings
fix:
    cargo fix --locked --workspace --all-features --all-targets
    cargo clippy --locked --workspace --no-deps --all-features --all-targets --fix
    cd ofdb-app-clearance && cargo fix --locked --target wasm32-unknown-unknown --all-features --all-targets
    cd ofdb-app-clearance && cargo clippy --locked --no-deps --target wasm32-unknown-unknown --all-features --all-targets --fix

# Run tests
test:
    RUST_BACKTRACE=1 cargo test --locked --workspace --all-features -- --nocapture
    RUST_BACKTRACE=1 cd ofdb-app-clearance && cargo test --locked --all-features -- --nocapture

# Set up (and update) tooling
setup:
    # Ignore rustup failures, because not everyone might use it
    rustup self update || true
    # cargo-edit is needed for `cargo upgrade`
    cargo install cargo-edit
    pip install -U pre-commit
    pre-commit autoupdate
    #pre-commit install --hook-type commit-msg --hook-type pre-commit

# Upgrade (and update) dependencies
upgrade:
    cargo update
    cargo upgrade --workspace \
        --exclude ofdb-boundary \
        --exclude ofdb-core \
        --exclude ofdb-entities \
        --exclude ofdb-gateways \
        --exclude libsqlite3-sys \
        --exclude time
    cargo update
    cd ofdb-app-clearance \
        && cargo update \
        && cargo upgrade \
            --exclude ofdb-boundary \
            --exclude ofdb-core \
            --exclude ofdb-entities \
            --exclude time \
        && cargo update
    #cargo minimal-versions check --workspace

# Run pre-commit hooks
pre-commit:
    pre-commit run --all-files