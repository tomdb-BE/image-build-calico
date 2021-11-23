SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META ?= -multiarch-build$(shell date +%Y%m%d)
ORG ?= rancher
UBI_IMAGE ?= registry.access.redhat.com/ubi8/ubi-minimal:latest
GOLANG_VERSION ?= v1.16.10b7-multiarch
TAG ?= v3.20.2$(BUILD_META)

K3S_ROOT_VERSION ?= v0.10.1
CNI_PLUGINS_VERSION ?= v1.0.1

ifneq ($(DRONE_TAG),)
TAG := $(DRONE_TAG)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

.PHONY: image-build
image-build:
	DOCKER_BUILDKIT=1 docker build --no-cache \
		--build-arg ARCH=$(ARCH) \
                --build-arg CNI_IMAGE=$(ORG)/hardened-cni-plugins:$(CNI_PLUGINS_VERSION)$(BUILD_META) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
                --build-arg GO_IMAGE=$(ORG)/hardened-build-base:$(GOLANG_VERSION) \
                --build-arg UBI_IMAGE=$(UBI_IMAGE) \
		--build-arg K3S_ROOT_VERSION=$(K3S_ROOT_VERSION) \
		--tag $(ORG)/hardened-calico:$(TAG) \
		--tag $(ORG)/hardened-calico:$(TAG)-$(ARCH) \
		.

.PHONY: image-push
image-push:
	docker push $(ORG)/hardened-calico:$(TAG)-$(ARCH)

.PHONY: image-manifest
image-manifest:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-calico:$(TAG) \
		$(ORG)/hardened-calico:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-calico:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-calico:$(TAG)
