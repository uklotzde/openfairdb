# FIXME: Trunk installation
# Use prebuild release binary as soon as it is available for musl.
# See: https://trunkrs.dev/

# Dockerfile for creating a statically-linked Rust application using Docker's
# multi-stage build feature. This also leverages the docker build cache to
# avoid re-downloading dependencies if they have not changed between builds.


###############################################################################
# Define global ARGs for all stages

# clux/muslrust: /usr/src
# ekidd/rust-musl-builder: /home/rust/src
ARG WORKDIR_ROOT=/usr/src

ARG PROJECT_NAME=openfairdb

ARG BUILD_TARGET=x86_64-unknown-linux-musl

ARG BUILD_MODE=release

ARG BUILD_BIN=${PROJECT_NAME}


###############################################################################
# 1st Build Stage
# The tag of the base image must match the version in the file rust-toolchain!
# Available images can be found at https://hub.docker.com/r/clux/muslrust/tags/
FROM docker.io/clux/muslrust:stable AS build

# Import global ARGs
ARG WORKDIR_ROOT
ARG PROJECT_NAME
ARG BUILD_TARGET
ARG BUILD_MODE
ARG BUILD_BIN

WORKDIR ${WORKDIR_ROOT}

# Docker build cache: Create and build an empty dummy project with all
# external dependencies to avoid redownloading them on subsequent builds
# if unchanged.
RUN USER=root \
    cargo new --bin ${PROJECT_NAME}
WORKDIR ${WORKDIR_ROOT}/${PROJECT_NAME}

RUN USER=root cargo new --lib ofdb-application \
    && \
    USER=root cargo new --lib ofdb-boundary \
    && \
    USER=root cargo new --lib ofdb-core \
    && \
    USER=root cargo new --lib ofdb-db-sqlite \
    && \
    USER=root cargo new --lib ofdb-db-tantivy \
    && \
    USER=root cargo new --lib ofdb-entities \
    && \
    USER=root cargo new --lib ofdb-frontend-api \
    && \
    USER=root cargo new --lib ofdb-gateways \
    && \
    USER=root cargo new --lib ofdb-webserver

COPY [ \
    "Cargo.toml", \
    "Cargo.lock", \
    "./" ]
COPY [ \
    "ofdb-application/Cargo.toml", \
    "./ofdb-application/" ]
COPY [ \
    "ofdb-boundary/Cargo.toml", \
    "./ofdb-boundary/" ]
COPY [ \
    "ofdb-core/Cargo.toml", \
    "ofdb-core/benches", \
    "./ofdb-core/" ]
COPY [ \
    "ofdb-db-sqlite/Cargo.toml", \
    "./ofdb-db-sqlite/" ]
COPY [ \
    "ofdb-db-tantivy/Cargo.toml", \
    "./ofdb-db-tantivy/" ]
COPY [ \
    "ofdb-entities/Cargo.toml", \
    "./ofdb-entities/" ]
COPY [ \
    "ofdb-frontend-api/Cargo.toml", \
    "./ofdb-frontend-api/" ]
COPY [ \
    "ofdb-gateways/Cargo.toml", \
    "./ofdb-gateways/" ]
COPY [ \
    "ofdb-webserver/Cargo.toml", \
    "./ofdb-webserver/" ]

# Build the dummy project(s), then delete all build artefacts that must(!) not be cached
RUN cargo build --${BUILD_MODE} --target ${BUILD_TARGET} --workspace \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/${PROJECT_NAME}* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/${PROJECT_NAME}-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_application-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_boundary-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_core-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_db_sqlite-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_db_tantivy-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_entities-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_frontend_api-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_gateways-* \
    && \
    rm -f ./target/${BUILD_TARGET}/${BUILD_MODE}/deps/ofdb_webserver-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/${PROJECT_NAME}-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-application-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-boundary-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-core-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-db-sqlite-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-db-tantivy-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-entities-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-gateways-* \
    && \
    rm -rf ./target/${BUILD_TARGET}/${BUILD_MODE}/.fingerprint/ofdb-webserver-*

# Copy all project (re-)sources that are required for building (ordered alphabetically)
COPY [ \
    "openapi.yaml", \
    "./" ]
COPY [ \
    "ofdb-app-clearance", \
    "./ofdb-app-clearance/" ]
COPY [ \
    "ofdb-application/src", \
    "./ofdb-application/src/" ]
COPY [ \
    "ofdb-boundary/src", \
    "./ofdb-boundary/src/" ]
COPY [ \
    "ofdb-core/src", \
    "./ofdb-core/src/" ]
COPY [ \
    "ofdb-db-sqlite/src", \
    "./ofdb-db-sqlite/src/" ]
COPY [ \
    "ofdb-db-sqlite/migrations", \
    "./ofdb-db-sqlite/migrations/" ]
COPY [ \
    "ofdb-db-tantivy/src", \
    "./ofdb-db-tantivy/src/" ]
COPY [ \
    "ofdb-entities/src", \
    "./ofdb-entities/src/" ]
COPY [ \
    "ofdb-frontend-api/src", \
    "./ofdb-frontend-api/src/" ]
COPY [ \
    "ofdb-gateways", \
    "./ofdb-gateways/" ]
COPY [ \
    "ofdb-webserver/build.rs", \
    "./ofdb-webserver/build.rs" ]
COPY [ \
    "ofdb-webserver/src", \
    "./ofdb-webserver/src/" ]
COPY [ \
    "src", \
    "./src/" ]

# Test and build the actual project
RUN cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-application \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-boundary \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-core \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-db-sqlite \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-db-tantivy \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-entities \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-frontend-api \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-gateways \
    && \
    cargo check --${BUILD_MODE} --target ${BUILD_TARGET} --package ofdb-webserver \
    && \
    cargo test --${BUILD_MODE} --target ${BUILD_TARGET} --workspace \
    && \
    cargo build --${BUILD_MODE} --target ${BUILD_TARGET} --bin ${BUILD_BIN} \
    && \
    strip ./target/${BUILD_TARGET}/${BUILD_MODE}/${BUILD_BIN}

# Switch back to the root directory
#
# NOTE(2019-08-30, uklotzde): Otherwise copying from the build image fails
# during all subsequent builds of the 2nd stage with an unchanged 1st stage
# image. Tested with podman 1.5.x on Fedora 30.
WORKDIR /


###############################################################################
# 2nd Build Stage
FROM scratch

# Import global ARGs
ARG WORKDIR_ROOT
ARG PROJECT_NAME
ARG BUILD_TARGET
ARG BUILD_MODE
ARG BUILD_BIN

ARG DATA_VOLUME="/volume"

ARG EXPOSE_PORT=8080

# Copy the statically-linked executable into the minimal scratch image
COPY --from=build [ \
    "${WORKDIR_ROOT}/${PROJECT_NAME}/target/${BUILD_TARGET}/${BUILD_MODE}/${BUILD_BIN}", \
    "./entrypoint" ]

EXPOSE ${EXPOSE_PORT}

VOLUME [ ${DATA_VOLUME} ]

# Bind the exposed port to Rocket that is used as the web framework
ENV ROCKET_PORT ${EXPOSE_PORT}

ENTRYPOINT [ "./entrypoint" ]
