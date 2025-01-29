FROM golang


WORKDIR /go/src/app

COPY go.mod .
RUN go mod download
COPY main.go .

RUN go build -o /go/bin/server .

USER nobody

CMD ["/go/bin/server"]
