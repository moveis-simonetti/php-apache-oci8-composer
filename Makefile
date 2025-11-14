all: build

IMAGE=lojassimonetti/php-apache-oci8-composer
TAG=$(shell git branch | grep \* | cut -d ' ' -f2)
FILE=Dockerfile

build:
	docker build --file $(FILE) --pull . -t $(IMAGE):$(TAG)

push: build
	docker push $(IMAGE):$(TAG)

build-var:
	make build TAG=$(TAG)-$(var) FILE=$(FILE).$(var)

push-var: build-var
	docker push $(IMAGE):$(TAG)-$(var)
