IMAGE_NAME ?= registry.replicated.com/library/statsd-graphite:latest

SHELL := /bin/bash -o pipefail
CURRENT_USER = $(shell id -u -n)

export IMAGE_NAME

.PHONY: build
build:
	docker build --pull -t $(IMAGE_NAME) .

# Original image currently cannot be built.  This is a quick hack to get dependnecies updated.
# This command will build an image that will be based on the last successully built image.
.PHONY: build-hack
build-hack:
	docker build --no-cache -f Dockerfile.hack -t $(IMAGE_NAME) .

.PHONY: scan
scan:
	bash scripts/grype_scan.sh

.PHONY: push
push:
	docker push $(IMAGE_NAME)

.PHONY: build-ttl.sh
build-ttl.sh:
	docker build -t ttl.sh/${CURRENT_USER}/statsd-graphite:12h .
	docker push ttl.sh/${CURRENT_USER}/statsd-graphite:12h

.PHONY: build-hack-ttl.sh
build-hack-ttl.sh:
	docker build -f Dockerfile.hack -t ttl.sh/${CURRENT_USER}/statsd-graphite:12h .
	docker push ttl.sh/${CURRENT_USER}/statsd-graphite:12h
