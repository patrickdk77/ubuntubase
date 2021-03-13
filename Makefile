VERSION ?= 20.04
BASE_IMAGE ?= ubuntu
ifdef BASE_IMAGE
	BUILD_ARG = --build-arg BASE_IMAGE=$(BASE_IMAGE):$(VERSION)
#	ifndef NAME
#		NAME = docker.patrickdk.com/ubuntubase-$(subst :,-,${BASE_IMAGE})
#	endif
endif
#else
	NAME ?= docker.patrickdk.com/ubuntubase
#endif
ifdef TAG_ARCH
	# VERSION_ARG = $(VERSION)-$(subst /,-,$(subst :,-,${BASE_IMAGE}))-$(TAG_ARCH)
	VERSION_ARG = $(VERSION)-$(TAG_ARCH)
	LATEST_VERSION = latest-$(TAG_ARCH)
else
	# VERSION_ARG = $(VERSION)-$(subst /,-,$(subst :,-,${BASE_IMAGE}))
	VERSION_ARG = $(VERSION)
	LATEST_VERSION = latest
endif
VERSION_ARG ?= $(VERSION)

.PHONY: all build test tag_latest release ssh

all: build

build:
	docker build -t $(NAME):$(VERSION_ARG) $(BUILD_ARG) --rm image

build-multiarch:
	env NAME=$(NAME) VERSION=$(VERSION_ARG) ./build-multiarch.sh

test:
	env NAME=$(NAME) VERSION=$(VERSION_ARG) ./test/runner.sh

tag-latest:
	docker tag $(NAME):$(VERSION_ARG) $(NAME):$(LATEST_VERSION)

tag-multiarch-latest:
	env NAME=$(NAME) VERSION=$(VERSION) TAG_LATEST=true ./build-multiarch.sh

publish:
	docker push $(NAME):$(VERSION_ARG)

publish-latest:
	docker push $(NAME):$(LATEST_VERSION)

release: test
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION_ARG); then echo "$(NAME) version $(VERSION_ARG) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag by creating an official GitHub release."

ssh: SSH_COMMAND?=
ssh:
	ID=$$(docker ps | grep -F "$(NAME):$(VERSION_ARG)" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container is not running."; exit 1; fi && \
		tools/docker-ssh $$ID ${SSH_COMMAND}

test_release:
	echo test_release
	env

test_master:
	echo test_master
	env
