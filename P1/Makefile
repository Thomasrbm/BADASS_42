NAME_HOST   = throbert_host
NAME_ROUTER = throbert_router

all: host router

host:
	docker build -t $(NAME_HOST) -f Dockerfile.host .

router:
	docker build -t $(NAME_ROUTER) -f Dockerfile.router .

run-host: host
	docker run --rm -it $(NAME_HOST) /bin/sh

run-router: router
	docker run --rm -it --privileged $(NAME_ROUTER) /bin/sh

gns3:
	gns3 &

clean-gns3:
	@echo "Stopping all GNS3 containers..."
	-docker ps -q --filter "name=GNS3" | xargs -r docker stop
	@echo "Removing all GNS3 containers..."
	-docker ps -aq --filter "name=GNS3" | xargs -r docker rm
	@echo "Done."

clean-images:
	-docker rmi -f $(NAME_HOST) $(NAME_ROUTER)


clean: clean-gns3 clean-images

re: clean all

.PHONY: all host router run-host run-router gns3 clean-gns3 clean-images clean re