.PHONY: build run shell clean

USER_UID := $(shell id -u)
USER_GID := $(shell id -g)
BRAINSTORM_PORT := $(shell bash -c 'echo $$((49152 + RANDOM % 16383))')

build:
	docker build --build-arg USER_UID=$(USER_UID) --build-arg USER_GID=$(USER_GID) --no-cache -t opencode-cli .

# Development targets: use local directories (./homebase, ./workspace, ./secrets)
# For regular use, prefer: bin/opencode-docker (uses ~/.opencode-docker/)

run:
	docker run --rm -it \
		--read-only \
		--tmpfs /tmp:exec,size=512m \
		--cap-drop ALL \
		--security-opt seccomp=unconfined \
		--memory=2g \
		--cpus=2 \
		-p $(BRAINSTORM_PORT):$(BRAINSTORM_PORT) \
		-e BRAINSTORM_PORT=$(BRAINSTORM_PORT) \
		-e BRAINSTORM_HOST=0.0.0.0 \
		-v $(shell pwd)/homebase:/app:rw \
		-v $(shell pwd)/config:/app/.config/opencode:ro \
		-v $(shell pwd)/workspace:/workspace:rw \
		-v $(shell pwd)/secrets:/run/secrets:ro \
		opencode-cli /workspace

shell:
	docker run --rm -it \
		--read-only \
		--tmpfs /tmp:exec,size=512m \
		--cap-drop ALL \
		--security-opt seccomp=unconfined \
		--memory=2g \
		--cpus=2 \
		-p $(BRAINSTORM_PORT):$(BRAINSTORM_PORT) \
		-e BRAINSTORM_PORT=$(BRAINSTORM_PORT) \
		-e BRAINSTORM_HOST=0.0.0.0 \
		-v $(shell pwd)/homebase:/app:rw \
		-v $(shell pwd)/config:/app/.config/opencode:ro \
		-v $(shell pwd)/workspace:/workspace:rw \
		-v $(shell pwd)/secrets:/run/secrets:ro \
		--entrypoint /bin/bash \
		opencode-cli

clean:
	docker rmi opencode-cli || true
