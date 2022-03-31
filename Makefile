IMAGE_NAME ?= registry.replicated.com/library/statsd-graphite:latest
ANCHORE_VERSION := v0.8.2

export IMAGE_NAME
export ANCHORE_VERSION

.PHONY: build
build:
	docker build --pull -t $(IMAGE_NAME) .

# Original image currently cannot be built.  This is a quick hack to get dependnecies updated.
# This command will build an image that will be based on the last successully built image.
.PHONY: build-hack
build-hack:
	docker build --pull -f Dockerfile.hack -t $(IMAGE_NAME) .

.PHONY: scan
scan:
	bash scripts/grype_scan.sh

.PHONY: push
push:
	docker push $(IMAGE_NAME)
