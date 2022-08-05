# AWS DevOps Tooling

---
A quickstart Docker Container for DevOps on AWS.

**Base Image:** 
- alpine:latest

**Tooling included:**
- ansible 
- **awscli2**
- bash 
- bind-tools 
- binutils 
- curl 
- findutils 
- git 
- gnupg 
- go 
- **helm**
- jq 
- **kubectl**
- make 
- ncurses 
- neofetch 
- openssh 
- openssl 
- pciutils 
- procps 
- py3-pip 
- python3 
- python3-dev 
- **terraform** 
- tfswitch 
- util-linux
- vim 
- yq 
- zsh 
- zsh-autosuggestions 
- zsh-syntax-highlighting 

# Docker Build

---
Build your Docker image using the following command:
```shell
docker build -t aws-devops-toolkit:latest .
```

## Start an interactive container:
```shell
docker run -it --rm \
    --name aws-devops-toolkit \
    aws-devops-toolkit:latest
```

## Start an interactive container, and mount both current and ~/.ssh directories:
```shell
docker run -it --rm \
		--name aws-devops-toolkit \
		-v $(pwd)/:/root/aws-devops-toolkit/ \
		-v ~/.ssh/:/root/.ssh/ \
		aws-devops-toolkit:latest
```

## Opening extra session to Docker Container:
```shell
# From a separated shell
docker exec -it aws-devops-toolkit /bin/zsh
```

# Makefile

---
Run `make`
```shell
# Available options:
build                Build aws-devops-toolkit image with "tag:latest"
run                  Run aws-devops-toolkit container from "tag:latest"
```

# License

---
GNUv3 - General Public License version 3
