### Task 0: Install a ubuntu 16.04 server 64-bit
Procedure：
1. Download https://download.virtualbox.org/virtualbox/6.1.14/VirtualBox-6.1.14-140239-Win.exe
2. Download http://releases.ubuntu.com/16.04/ubuntu-16.04.7-server-amd64.iso
3. Install VirtualBox
4. Click on“新建”
5. Choose 4096MB memory， and below default settings， and set disk to 40GB.
6. Back to Main screen and click on “设置”， select “系统”，Move “硬盘” to Top.
7. Click “设置” again and choose “存储”， choose the downloaded Ubuntu image.
8. Back to Main screen and select “启动”
9. Follow the process and set the user password, Language, Timezone, etc
10. Install Openssh

Port Forward：
1.	 Click on “管理“-”全局设定”-“网络
2.	Select “端口转发 and add the rules. 192.168.0.108 is HOST ip.
3.	Set for the VM, “设置-“网络，choose the created NAT network
4.	启动VM，check the ip of the VM 
5.	Set the ip to 192.168.2.4 in Step2 for port forward. And restart VM.

### Task 1: Update system
Make sure openssl-server is installed.
apt-get install openssh-server
 
Update Kernel
Run Below command in VM：
1.	Apt update
2.	Apt upgrade
 
Check the kernel version:
 root@celia-ubuntu:~/gitnodes/go-web-hello-world# cat /proc/version
Linux version 4.4.0-186-generic (buildd@lcy01-amd64-002) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.12) ) #216-Ubuntu SMP Wed Jul 1 05:34:05 UTC 2020



### Task 2: install gitlab-ce version in the host
1.	apt-get install -y curl openssh-server ca-certificates tzdata
2.	apt-get install -y postfix
3.	curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
4.	wget https://mirror.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/xenial/main/g/gitlab-ce/gitlab-ce_13.3.6-ce.0_amd64.deb
5.	dpkg -i gitlab-ce_13.3.6-ce.0_amd64.deb
6.	vim /etc/gitlab/gitlab.rb
# 修改为自己的ip地址或者自己的域名，域名需要做地址解析
external_url 'http://127.0.0.1'
7.	Init configuration:
root@celia-ubuntu:~# gitlab-ctl reconfigure
8.	Access http://127.0.0.1:8080 from HOST web browser.
9.	Set password to “1qazXSW@” and login.


### Task 3: create a demo group/project in gitlab

named demo/go-web-hello-world (demo is group name, go-web-hello-world is project name).

Use golang to build a hello world web app (listen to 8081 port) and check-in the code to mainline.

https://golang.org/<br>
https://gowebexamples.com/hello-world/

Expect source code at http://127.0.0.1:8080/demo/go-web-hello-world

1.	Create a group named demo.
2.	Select “New project” to create a new project named “go-web-hello-world”
3.	Create and put hello.go
root@celia-ubuntu:~/gitnodes/go-web-hello-world# cat hello.go 
package main

import (
    "fmt"
    "net/http"
)
func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Go Web Hello world!\n")
    })

    http.ListenAndServe(":8081", nil)
}
4.	Expect source code at http://127.0.0.1:8080/demo/go-web-hello-world
 

### Task 4: build the app and expose ($ go run) the service to 8081 port

Expect output: 
```
curl http://127.0.0.1:8081
Go Web Hello World!
```
1.	Modify code:
root@celia-ubuntu:~/gitnodes/go-web-hello-world# cat hello.go 
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Go Web Hello world!\n")
    })

    http.ListenAndServe(":8081", nil)
}

2.	Wget https://studygolang.com/dl/golang/go1.15.2.linux-amd64.tar.gz
3.	tar -xzf go1.8.linux-amd64.tar.gz -C /usr/local
4.	配置环境变量
vim ~/.bashrc          Add below at last line
export GOPATH= /opt/go
export GOROOT=/usr/local/go 
export GOARCH=386 
export GOOS=linux 
export GOBIN=$GOROOT/bin/ 
export GOTOOLS=$GOROOT/pkg/tool/ 
export PATH=$PATH:$GOBIN:$GOTOOLS
    
source ~/.bashrc

5.	go run hello.go
6.	curl in another terminal
root@celia-ubuntu:~# curl http://127.0.0.1:8081
Go Web Hello world!
 
Browse in HOST browser.
 
### Task 5: install docker
https://docs.docker.com/install/linux/docker-ce/ubuntu/


用国内的源
Follow guide Ubuntu 18.04 安装 Docker-ce
https://www.runoob.com/docker/ubuntu-docker-install.html

1.	cp /etc/apt/sources.list /etc/apt/sources.list.back
sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list 
apt update
   apt update
2 apt install docker-ce
2.	systemctl enable docker
3.	systemctl start docker
 

### Task 6: run the app in container

build a docker image ($ docker build) for the web app and run that in a container ($ docker run), expose the service to 8082 (-p)

https://docs.docker.com/engine/reference/commandline/build/

Check in the Dockerfile into gitlab

Expect output:
```
curl http://127.0.0.1:8082
Go Web Hello World!
```

1.	配置加速器
Vim /etc/docker/daemon.json
root@celia-ubuntu:~/gitnodes/go-web-hello-world# cat /etc/docker/daemon.json 
{
  "registry-mirrors": ["https://c6j7pq1p.mirror.aliyuncs.com"]
}
Systemctl daemon-reload
Systemctl restart docker

2.	Pull a base image with golang.  
docker pull golang
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
golang              latest              05c8f6d2538a        9 days ago          839MB
3.	Create dockerfile
root@celia-ubuntu:~/gitnodes/go-web-hello-world# cat dockerfile 
FROM golang 
COPY hello.go /root/
CMD ["/usr/local/go/bin/go", "run", "/root/hello.go"]
4.	Build image
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker build -t helloworld:1.0 .
Sending build context to Docker daemon  53.76kB
Step 1/3 : FROM golang
 ---> 05c8f6d2538a
Step 2/3 : COPY hello.go /root/
 ---> Using cache
 ---> b74baeabf410
Step 3/3 : CMD ["/usr/local/go/bin/go", "run", "/root/hello.go"]
 ---> Running in a1e451a1033d
Removing intermediate container a1e451a1033d
 ---> 06ea8a4c0304
Successfully built 06ea8a4c0304
Successfully tagged helloworld:1.0

5.	Run image
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker run -it -p 8083:8081 helloworld:1.0

6.	Open another terminal：
root@celia-ubuntu:~# curl http://127.0.0.1:8083
Go Web Hello world!



### Task 7: push image to dockerhub

tag the docker image using your_dockerhub_id/go-web-hello-world:v0.1 and push it to docker hub (https://hub.docker.com/)

Expect output: https://hub.docker.com/repository/docker/your_dockerhub_id/go-web-hello-world

Docker Hub account:
celiaw/gifthh1986117


1．	Dockroot@celia-ubuntu:~/gitnodes/go-web-hello-world# docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: celiaw
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
root@celia-ubuntu:~/gitnodes/go-web-hello-world# 
root@celia-ubuntu:~/gitnodes/go-web-hello-world# 
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
helloworld          1.0                 06ea8a4c0304        19 minutes ago      839MB
golang              latest              05c8f6d2538a        9 days ago          839MB

2. Docker tag
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker tag helloworld:1.0 celiaw/helloworld:1.0
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
celiaw/helloworld   1.0                 06ea8a4c0304        20 minutes ago      839MB
helloworld          1.0                 06ea8a4c0304        20 minutes ago      839MB
golang              latest              05c8f6d2538a        9 days ago          839MB

3. Docker push
root@celia-ubuntu:~/gitnodes/go-web-hello-world# docker push celiaw/helloworld:1.0
The push refers to repository [docker.io/celiaw/helloworld]
6fa24063cb66: Pushed 
1ba6a3ca6c41: Mounted from library/golang 
d2588c27d938: Mounted from library/golang 
6b6e43b44148: Mounted from library/golang 
17bdf5e22660: Mounted from library/golang 
d37096232ed8: Pushing [==================================================>]  17.85MB
6add0d2b5482: Mounted from library/golang 
4ef54afed780: Waiting 


4. Browse https://hub.docker.com/repository/docker/celiaw/helloworld 