IMAGE_NAME ?= registry.replicated.com/library/statsd-graphite:latest

SHELL := /bin/bash -o pipefail
CURRENT_USER = $(shell id -u -n)

export IMAGE_NAME

.PHONY: build
build:
	docker build --pull -t $(IMAGE_NAME) .

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
