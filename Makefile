export GO111MODULE=on

VERSION=$(shell date +"%Y.%m.%d")

BUILD=$(shell git rev-parse HEAD)
BASEDIR=./dist

LDFLAGS=-ldflags "-s -w -X main.build=${BUILD} -buildid=${BUILD}"
GCFLAGS=-gcflags=all=-trimpath=$(shell echo ${HOME})
ASMFLAGS=-asmflags=all=-trimpath=$(shell echo ${HOME})

GOFILES=`go list -buildvcs=false ./...`
GOFILESNOTEST=`go list -buildvcs=false ./... | grep -v test`

# Make Directory to store executables
$(shell mkdir -p ${BASEDIR})

# Define the output directory
OUTPUT_DIR := ~/.sliver-client/aliases/ligolo-ng

# Define the source files
AGENT_SRC := cmd/agent/main.go
PROXY_SRC := cmd/proxy/main.go

# Define the alias.json file
ALIAS_JSON := alias.json

# Default target
all: linux windows move
	@chmod +x ${BASEDIR}/*

mac: lint
	@env CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -trimpath ${LDFLAGS} ${GCFLAGS} ${ASMFLAGS} -o ${BASEDIR}/ligolo-ng-proxy-darwin_amd64 cmd/proxy/main.go
	@env CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -trimpath ${LDFLAGS} ${GCFLAGS} ${ASMFLAGS} -o ${BASEDIR}/ligolo-ng-agent-darwin_amd64 cmd/agent/main.go

# Compile for Linux
linux: lint
	GOOS=linux GOARCH=amd64 go build -o ${BASEDIR}/ligolo-ng-agent-linux-amd64 $(AGENT_SRC)
	GOOS=linux GOARCH=386 go build -o ${BASEDIR}/ligolo-ng-agent-linux-386 $(AGENT_SRC)
	GOOS=linux GOARCH=amd64 go build -o ${BASEDIR}/ligolo-ng-proxy-linux-amd64 $(PROXY_SRC)

# Compile for Windows
windows: lint
	GOOS=windows GOARCH=amd64 go build -o ${BASEDIR}/ligolo-ng-agent-windows-amd64.exe $(AGENT_SRC)
	GOOS=windows GOARCH=386 go build -o ${BASEDIR}/ligolo-ng-agent-windows-386.exe $(AGENT_SRC)
	GOOS=windows GOARCH=amd64 go build -o ${BASEDIR}/ligolo-ng-proxy-windows-amd64.exe $(PROXY_SRC)

# Move the compiled files and alias.json
move:
	mkdir -p $(OUTPUT_DIR)
	cp ${BASEDIR}/ligolo-ng-agent-linux-amd64 $(OUTPUT_DIR)
	cp ${BASEDIR}/ligolo-ng-agent-linux-386 $(OUTPUT_DIR)
	cp ${BASEDIR}/ligolo-ng-agent-windows-amd64.exe $(OUTPUT_DIR)
	cp ${BASEDIR}/ligolo-ng-agent-windows-386.exe $(OUTPUT_DIR)
	cp ${BASEDIR}/ligolo-ng-proxy-linux-amd64 $(OUTPUT_DIR)
	cp ${BASEDIR}/ligolo-ng-proxy-windows-amd64.exe $(OUTPUT_DIR)
	cp $(ALIAS_JSON) $(OUTPUT_DIR)

tidy:
	@go mod tidy

update: tidy
	@go get -v -d ./...
	@go get -u all

dep: ## Get the dependencies
	@go install github.com/goreleaser/goreleaser
	@go install github.com/securego/gosec/v2/cmd/gosec@latest

lint: ## Lint the files
	@env CGO_ENABLED=0 go fmt ${GOFILES}
	@env CGO_ENABLED=0 go vet ${GOFILESNOTEST}

security:
	@gosec -tests ./...

release:
	@goreleaser release --config .github/goreleaser.yml

clean:
	@rm -rf ${BASEDIR}
	rm -f ligolo-ng-agent-linux-amd64 ligolo-ng-agent-linux-386 ligolo-ng-agent-windows-amd64.exe ligolo-ng-agent-windows-386.exe
	rm -f ligolo-ng-proxy-linux-amd64 ligolo-ng-proxy-linux-386 ligolo-ng-proxy-windows-amd64.exe ligolo-ng-proxy-windows-386.exe
	rm -rf $(OUTPUT_DIR)

terminal_proxy:
	go run cmd/proxy/main.go -selfcert

terminal_agent:
	go run cmd/agent/main.go -connect localhost:11601 -ignore-cert

.PHONY: all linux windows tidy update dep lint security release clean terminal move
