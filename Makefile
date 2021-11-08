all: build

IMAGE=lojassimonetti/php-apache-oci8-composer
TAG=$(shell git branch | grep \* | cut -d ' ' -f2)

build:
	docker build . -t $(IMAGE):$(TAG)

push: build
	docker push $(IMAGE):$(TAG)

