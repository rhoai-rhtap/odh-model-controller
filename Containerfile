# Build the manager binary
FROM registry.access.redhat.com/ubi8/go-toolset@sha256:4ec05fd5b355106cc0d990021a05b71bbfb9231e4f5bdc0c5316515edf6a1c96 as builder
#rhoai-2.13-1

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
#COPY api/ api/
COPY controllers/ controllers/

# Build
USER root
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager main.go

FROM registry.redhat.io/ubi8/ubi-minimal:latest AS runtime

ARG CI_CONTAINER_VERSION
ARG USER=2000

LABEL com.redhat.component="odh-model-controller-container" \
      name="managed-open-data-hub/odh-model-controller-rhel8" \
      version="${CI_CONTAINER_VERSION}" \
      git.url="${CI_ODH_MODEL_CONTROLLER_UPSTREAM_URL}" \
      git.commit="${CI_ODH_MODEL_CONTROLLER_UPSTREAM_COMMIT}" \
      summary="odh-model-controller" \
      io.openshift.expose-services="" \
      io.k8s.display-name="odh-model-controller" \
      maintainer="['managed-open-data-hub@redhat.com']" \
      description="The controller removes the need for users to perform manual steps when deploying their models" \
      com.redhat.license_terms="https://www.redhat.com/licenses/Red_Hat_Standard_EULA_20191108.pdf"

WORKDIR /
COPY --from=builder /workspace/manager .
USER ${USER}

ENTRYPOINT ["/manager"]

