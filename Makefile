GRAV_VERSION=1.7.37.1
.PHONY:build
help:
	@echo "make build: build the container image"
	@echo "make run-dev: run the container image after setting all correct permissions"
	@echo "make clean: remove the container image, preserving user and backup data"
	@echo "to update grav, build a new container image, and restart the systemd service"

build:
	podman build -t grav:$(GRAV_VERSION) --build-arg GRAV_VERSION=$(GRAV_VERSION) .

push:
	podman tag localhost/grav:$(GRAV_VERSION) quay.io/manue/container-grav:$(GRAV_VERSION)
	podman push quay.io/manue/container-grav:$(GRAV_VERSION)

grav-admin.zip:
	curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/1.7.37.1

grav-admin/user/config/system.yaml: grav-admin.zip
	test -f grav-admin/user/config/system.yaml || unzip grav-admin.zip "grav-admin/user/*"
	touch $@

user: grav-admin/user/config/system.yaml
	test -f user/config/system.yaml || cp -r grav-admin/user .
	podman unshare chown -R 33:33 user

backup:
	mkdir backup
	podman unshare chown -R 33:33 backup

initial-setup: user backup

run-dev: initial-setup
	podman run --publish 8000:80 --volume ./user:/var/www/html/user:Z \
		--volume ./backup:/var/www/html/backup:Z \
		--name grav localhost/grav

#TODO: add target to generate systemd service with --new flag so that containers are always
# recreated from image when the service is started

.PHONY: clean
clean:
	- podman stop --time 1 grav
	- podman rm grav
	- rm grav-admin.zip


