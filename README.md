# Docker Getting Started

## Some Handy Links

[https://hub.docker.com/_/registry](https://hub.docker.com/_/registry)
[https://distribution.github.io/distribution/about/configuration/](https://distribution.github.io/distribution/about/configuration/)

## Docker is free

- Docker cli is free as in freedom and still remains an opensource project
- The folks at Docker are also generous and offer a nice free tier on their Docker Desktop product

## Core Concepts to Cover

### Running a container

- `-d` to daemonize
- `-p` to map ports, left side is host port, right is container port

### Managing Containers

- `docker ps` list all running containers
  - Shows all running containers
  - Notice our container has a randomly generated name, if we dont specify our own name for the container it will get a random one like this
- `docker stop` to stop a container
- `docker ps` wont show the container now
- `docker ps --all` will show all containers, including stopped ones
- `docker start` starts a container
- `docker rm` removes a container that's not currently in use
  - We cant remove a running container we need to stop it
- Lets try run our container with a name we can remember lets use `--name` and call it nginx
- Here we can see the new name
- It will be much easier to manage now
  - `docker stop nginx`
  - `docker rm nginx`

### Building Containers

Ok so lets try package up a little http server which since Docker is written in go lets write our little http server in Go too

Look at this example code

```go
package main

import (
    "fmt"
    "net/http"
)

func helloWorld(w http.ResponseWriter, req *http.Request) {
    name := req.URL.Query().Get("name")
    if name == "" {
        name = "World"
    }
    fmt.Fprintf(w, "Hello %v\n", name)
}

func main() {
    http.HandleFunc("/", helloWorld)
 fmt.Println("Server is running on port 8080")
    http.ListenAndServe(":8080", nil)
}
```

We have a little Hello World function which will print out Hello World as expected but if we pass it our name as a query param (all the parts following this `?` symbol in a url for those who don't know), it will greet us by our name

We use this as the function to handle requests on the `/` path  then we start up our server

Lets run it

```bash
go run main.go
Server is running on port 8080
```

Lets open up another terminal and hit this with our bestie `curl`:

```shell
curl "http://localhost:8080"
Hello World
```

Lets add our name as a query param

```shell
curl "http://localhost:8080?name=CrispyFish"
Hello CrispyFish
```

I feel like this thing........knows me.

Ok so we know this works lets build this and call our app `server`

```shell
go build -o server .
```

And we should have an executable called `server`:

```
ls
server  go.mod  main.go
```

Lets kill our previous server with Control C and start up server

```shell
./server
curl "http://localhost:8080"
Hello World
curl "http://localhost:8080?name=CrispyFish"
Hello CrispyFish
```

Great working as expected

Lets put this in a docker container, lets write out this simple dockerfile

```Dockerfile
FROM golang

COPY main.go /go/src/app/main.go
COPY go.mod /go/src/app/go.mod

WORKDIR /go/src/app

RUN go mod download

RUN go build -o /go/bin/server .

USER nobody

CMD ["/go/bin/server"]
```

We use the `FROM` keyword to select the image we start from

We use the `COPY` keyword to copy over our `go.mod` which has a list of all our dependencies needed for this app and our `main.go` which has all our apps code

We use the `WORKDIR` keyword to change our directory to the one our app is in

We use the `RUN`  key word to run our `go mod download` and to build our server

We then use `USER` to set our user to `nobody` we started off with `root` we don't want to run a container as root its bad security practice

Lastly we use `CMD` to start up our newly built server

We can now use docker build to create our shiny new container

```shell
docker build . -t simpleserver:latest
[+] Building 8.0s (11/11) FINISHED                                    docker:default
 => [internal] load build definition from Dockerfile                            0.0s
 => => transferring dockerfile: 229B                                            0.0s
 => [internal] load metadata for docker.io/library/golang:latest                2.2s
 => [internal] load .dockerignore                                               0.0s
 => => transferring context: 2B                                                 0.0s
 => [1/6] FROM docker.io/library/golang:latest@sha256:8c10f21bec412f08f73aa7b9  0.0s
 => => resolve docker.io/library/golang:latest@sha256:8c10f21bec412f08f73aa7b9  0.0s
 => => sha256:8c10f21bec412f08f73aa7b97ca5ac5f28a39d8a88030a 10.06kB / 10.06kB  0.0s
 => => sha256:606a44533fdbd626261af107d9205bd08ebc24c50e229c2c 2.80kB / 2.80kB  0.0s
 => => sha256:1431234f8c81c5a4920e0081f425c18dff82f1595a4ef65b 2.32kB / 2.32kB  0.0s
 => [internal] load build context                                               0.0s
 => => transferring context: 471B                                               0.0s
 => [2/6] COPY main.go /go/src/app/main.go                                      0.0s
 => [3/6] COPY go.mod /go/src/app/go.mod                                        0.0s
 => [4/6] WORKDIR /go/src/app                                                   0.0s
 => [5/6] RUN go mod download                                                   0.1s
 => [6/6] RUN go build -o /go/bin/server .                                      5.4s
 => exporting to image                                                          0.2s
 => => exporting layers                                                         0.2s
 => => writing image sha256:d613e53740a5075badaa8fe721c74b06138e0db78bc40a9d41  0.0s
 => => naming to docker.io/library/simpleserver:latest
```

Lets run this and map our port

```shell
docker run -d --name test -p 8080:8080 simpleserver:latest
curl "http://localhost:8080"
Hello World
curl "http://localhost:8080?name=CrispyFish"
Hello CrispyFish
```

You just dockerized a go app well done or should I see good **GOING** <-- crickets

Oh you want me to go? Oh ok **Get up and leave**

### Image management

Lets look at our images:

```shell
docker image ls
```

So now we want to push this image to a registry if we wanted to push this to docker hub we would rename it with our username

```shell
docker tag therispyfish/simpleserver:latest
```

But since we are just playing around we can also just use a little local registry which we can run as a docker container too

```shell
docker run -dp 5000:5000 --name registry --restart always registry:2
```

Lets tag our image to got to our new registry:

```shell
docker tag simpleserver:latest localhost:5000/simpleserver:latest
```

And push it real good

```shell
docker push localhost:5000/simpleserver:latest
```

Lets test a pull of our new image

```shell
docker pull localhost:5000/simpleserver:latest
```

Nice so we have a local registry now but if we delete it all our stuff is gone thats no good lets make it persist

### Volumes

```shell
docker volume create registry-data
```

Now lets delete our old registry and start a new one with our volume

```shell
docker stop registry && docker rm registry
```

If you aren't familiar with the `&&` operator it allows us to run multiple commands in one line and only run the next command if the previous one was successful

Just to show what I mean here lets run the registry without the volume

```shell
docker run -dp 5000:5000 --name registry --restart always registry:2
```

And now our pull fails

```shell
docker pull localhost:5000/simpleserver:latest
Error response from daemon: manifest for localhost:5000/simpleserver:latest not found: manifest unknown: manifest unknown
```

The default location for these images is `/var/lib/registry` so lets mount our volume there

```shell
docker run -dp 5000:5000 --name registry --restart always -v registry-data:/var/lib/registry registry:2
```

Then push our image again

```shell
docker push localhost:5000/simpleserver:latest
```

Then delete our registry and start it up again

```shell
docker run -dp 5000:5000 --name registry --restart always -v registry-data:/var/lib/registry registry:2
```

And pull our image again

```shell
docker pull localhost:5000/simpleserver:latest
```

And bada bing bada boom we have our image back

So we can also mount to a local volume, this could be handy if you are using a development container for example, I am curious to see what this registry data looks like so lets create a local folder and mount that into our registry instead

```shell
mkdir registry
docker run -dp 5000:5000 --name registry --restart always -v ./registry:/var/lib/registry registry:2
```

> The path can be relative or absolute

Lets explore our registry data

```shell
ls registry
```

Check it out heres all the layers for our image

```shell
ls registry/docker/registry/v2/repositories/simpleserver/_layers/sha256/
```

### Multi Stage Builds

So now all this works but our image is really big for no reason, lets slim it down with a multi stage build

```shell
docker image ls
```

Our current file goes from this:

```Dockerfile
FROM golang

COPY main.go /go/src/app/main.go
COPY go.mod /go/src/app/go.mod

WORKDIR /go/src/app

RUN go mod download

RUN go build -o /go/bin/server .

USER nobody

CMD ["/go/bin/server"]
```

To this:

```Dockerfile
FROM golang:1.23.5-alpine3.21 AS builder

COPY main.go /go/src/app/main.go
COPY go.mod /go/src/app/go.mod

WORKDIR /go/src/app

RUN go mod download

RUN go build -o /go/bin/server .

FROM scratch

COPY --from=builder /go/bin/server /go/bin/server

CMD ["/go/bin/server"]
```

**What we did:**

1. We call our first image build with it and label it as a builder
2. Then we use FROM scratch this is a special image that is empty
3. We don't need any ssl certs or anything else we can just use this
4. We copy over our built server from our builder image
5. We run it in the same fashion

Lets check the new size:

```shell
docker image ls
```

Now thats a big difference!
