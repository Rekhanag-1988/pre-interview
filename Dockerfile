FROM docker.io/centos:7
ARG COMMIT_ID

RUN yum install --assumeyes openssl

RUN yum --assumeyes update && \
	yum install --assumeyes \
	python3 \
	python3-devel
RUN pip3 install flask

COPY source /app

RUN echo $COMMIT_ID > /app/commit_id

EXPOSE 5000

CMD /usr/bin/python3 /app/version.py