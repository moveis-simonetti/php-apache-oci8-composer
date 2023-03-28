all: build

IMAGE=lojassimonetti/php-apache-oci8-composer
tag=$(shell git branch | grep \* | cut -d ' ' -f2)
TAG=$(shell [[ "$(tag)" == "master" ]] && echo "latest" || echo $(tag))

build:
	docker build . -t $(IMAGE):$(TAG)

push: build
	docker push $(IMAGE):$(TAG)

