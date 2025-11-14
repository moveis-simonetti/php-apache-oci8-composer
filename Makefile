all: build

IMAGE=lojassimonetti/php-apache-oci8-composer
tag=$(shell git branch | grep \* | cut -d ' ' -f2)
TAG=$(shell [[ "$(tag)" == "master" ]] && echo "latest" || echo $(tag))
FILE=Dockerfile

build:
	docker build --file $(FILE) --pull . -t $(IMAGE):$(TAG)

push: build
	docker push $(IMAGE):$(TAG)

build-var:
	make build TAG=$(TAG)-$(var) FILE=$(FILE).$(var)

push-var: build-var
	docker push $(IMAGE):$(TAG)-$(var)
