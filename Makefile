IMAGE_NAME = hvossi92/pomodoro
TIMESTAMP := $(shell date +%Y%m%d%H%M%S)

build:
	docker build --platform linux/amd64 -t pomodoro .

push:
	docker tag pomodoro $(IMAGE_NAME):$(TIMESTAMP)
	docker push $(IMAGE_NAME):$(TIMESTAMP)
	docker tag $(IMAGE_NAME):$(TIMESTAMP) $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):latest