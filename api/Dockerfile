FROM golang:1.18-bullseye as base

RUN adduser \
  --no-create-home \
  --uid 65532 \
  nonroot

WORKDIR $GOPATH/src/app/

COPY src/go.mod .
COPY src/go.sum .

RUN go mod download
RUN go mod verify

COPY src/*.go .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/binary .

FROM alpine:latest

COPY --from=base /etc/passwd /etc/passwd
COPY --from=base /etc/group /etc/group

COPY --from=base /app/binary /app

USER nonroot:nonroot

ENTRYPOINT [ "./app" ]
