FROM golang 
COPY hello.go /root/
CMD ["/usr/local/go/bin/go", "run", "/root/hello.go"]

