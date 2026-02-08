run:
	docker stop jupyter-collab || true
	docker build -t jupyter-collab .
	docker run -it --rm -p 8888:8888 jupyter-collab

host:
	ssh -R 9999:127.0.0.1:8888 root@64.176.68.246