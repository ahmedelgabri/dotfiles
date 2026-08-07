BINARY_NAME=next-prayer

export BIN ?= ./bin/${BINARY_NAME}

export GOBIN ?= /usr/local/bin/

VERSION=$(shell git rev-parse --short HEAD)

GO_FLAGS=-ldflags "-w -s -X main.version=$(VERSION)"

all: build

release: test tidy build

build:
	go build ${GO_FLAGS} -o ${BIN} ./cmd/next-prayer

run:
	./bin/${BINARY_NAME}

install:
	go install ${GO_FLAGS} ./cmd/next-prayer

test:
	go test -coverprofile=coverage.out ./...

cov: | test
	go tool cover -html=coverage.out

lint:
	go vet ./...

tidy:
	go mod tidy

format:
	goimports -w ./
