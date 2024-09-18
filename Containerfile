# Build smbmetrics
FROM --platform=${BUILDPLATFORM:-linux/amd64} docker.io/golang:1.21 AS builder
ARG GIT_VERSION="(unset)"
ARG COMMIT_ID="(unset)"
# these are created by docker because we've used --platform with the buildx command
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd cmd
COPY internal internal

# Build
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} GO111MODULE=on \
    go build -a \
    -ldflags "-X main.Version=${GIT_VERSION} -X main.CommitID=${COMMIT_ID}" \
    -o smbmetrics cmd/main.go

# Use samba-server (with its smb.conf and samba utils) as base image
FROM cp.stg.icr.io/cp/ibm-ceph/samba-server-rhel9:latest
COPY --from=builder /workspace/smbmetrics /bin/smbmetrics

ENTRYPOINT ["/bin/smbmetrics"]
EXPOSE 8080
