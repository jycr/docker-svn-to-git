FROM openjdk:8-jre-alpine

ENV SUBGIT_VERSION=3.3.1

COPY entrypoint.sh /entrypoint.sh

RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		bash \
		bzip2 \
		curl \
		git \
		gzip \
		pv \
		subversion \
		unzip \
		xz \
	&& curl \
		--progress-bar \
		--location \
		--fail \
		--show-error \
		--output subgit.zip \
		"https://subgit.com/download/subgit-${SUBGIT_VERSION}.zip" \
	&& unzip subgit.zip \
	&& rm *.zip \
	&& mv subgit-* subgit \
	&& chmod +x /entrypoint.sh \
	&& mkdir -p \
		/svn_dumps \
		/svn_repo \
		/git_repo

#COPY svn_dumps /svn_dumps

VOLUME ["/svn_dumps"]


ENTRYPOINT ["/entrypoint.sh"]
