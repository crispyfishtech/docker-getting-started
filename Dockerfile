FROM golang

COPY main.go /go/src/app/main.go
COPY go.mod /go/src/app/go.mod

WORKDIR /go/src/app

RUN go mod download

RUN go build -o /go/bin/server .

USER nobody

CMD ["/go/bin/server"]
