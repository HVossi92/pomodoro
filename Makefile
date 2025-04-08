build:
	# Only works on a linux machine, no clue how to get it to work on macos
	docker build --platform linux/amd64 -t pomodoro .

push:
	docker tag pomodoro hvossi92/pomodoro:latest
	docker push hvossi92/pomodoro:latest