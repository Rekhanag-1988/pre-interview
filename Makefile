#!/usr/bin/env make

.DEFAULT_GOAL := usage
BRANCH :=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT_ID :=$(shell git rev-parse HEAD)
REGISTRY :=docker.io

# test: ## runs simple test

login: ## login to docker-registry
	@docker login ${REGISTRY} --username ${user} --password ${password}

build: ## Builds application image
	@docker build --tag rekhanagyalakurthi/pre-interview:${TAG} --build-arg COMMIT_ID=${COMMIT_ID} .

deploy: ## runs the given docker image
	@ docker run --rm --detach --port 80:5000 --env APP_VERSION=${TAG} --name pre-interview rekhanagyalakurthi/pre-interview:${TAG}

usage: ## Usage
	@echo '[build:  Builds application image]'