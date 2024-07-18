FROM alpine:3.12.1

RUN apk add --update --no-cache									\
	bash curl vim										\
	mysql-client										\
	mariadb-connector-c-dev									\
    && curl -LO https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64		\
    && chmod a+x jq-linux64 									\
    && mv jq-linux64 /usr/local/bin/jq								\
    && mv /etc/vim/vimrc /etc/vim/vimrc.bak 							\
    && mkdir /labs

# Install python/pip
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools requests

COPY 	mysql_REST.sh 		\
	mysql_REST.py		\
	mysql_k8s_secrets.sh	\
	mysql_file.sh 		\
	uid_entrypoint.sh	\
	/labs/

WORKDIR /labs

# setup entrypoint for default user
RUN chmod g=u /etc/passwd /labs/*
ENTRYPOINT [ "/labs/uid_entrypoint.sh" ]
USER 1001
