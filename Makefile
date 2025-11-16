all: build

IMAGE=lojassimonetti/php-apache-oci8-composer
FILE=Dockerfile

list-names:
	@cat config.json|jq '.[]|.name' --raw-output

build:
ifndef name
	$(error No name was informed throught the "name" parameter)
endif
	docker run --rm \
		`cat config.json | \
			jq '.[]|select(.name == "$(name)")|to_entries|map(select(.key != "variations"))' | \
			jq '.|map(" -e DOCKER_BUILD_" + (.key|ascii_upcase) + "=" + (.value|tostring) + "")|.[]' \
			--raw-output` \
		-v `pwd`:/work -w /work \
		webdevops/go-replace:latest \
			--mode=template ./`cat config.json | \
				jq '.[]|select(.name == "$(name)")|.template|if . == null then "Dockerfile.tmpl" else . end'  --raw-output` \
			-o Dockerfile
	docker build . --pull -t $(IMAGE):$(name)
	rm Dockerfile

push: build
	docker push $(IMAGE):$(TAG)

build-var:
ifndef name
	$(error No variation was informed throught the "var" parameter)
endif
	make build name=$(name)
	docker build --build-arg IMAGE_BASE=$(IMAGE):$(name) --file Dockerfile.$(var) -t $(IMAGE):$(name)-$(var) .

push-var: build-var
	docker push $(IMAGE):$(TAG)-$(var)
