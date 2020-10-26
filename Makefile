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

usage: ## Usage
	@echo '[build:  Builds application image]'