IMAGE_NAME ?= registry.replicated.com/library/statsd-graphite:latest
ANCHORE_VERSION := v0.8.2

export IMAGE_NAME
export ANCHORE_VERSION

.PHONY: scan
scan: export POLICY_FAILURE = true
scan: export TIMEOUT = 6000
scan: export POLICY_BUNDLE_PATH = ./policy-bundle.json
scan: export DOCKERFILE_PATH = ./Dockerfile
scan:
	bash scripts/inline_scan.sh
