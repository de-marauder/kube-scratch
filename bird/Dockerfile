# Lightweight base image for building making sure the golang version matches that of the code in go.mod
FROM golang:1.22-alpine AS builder

# Set necessary environment variables for Go
ENV CGO_ENABLED=0 \
  GOOS=linux \
  GOARCH=amd64

# Set working directory inside the container
WORKDIR /app

# Copy go.mod to enable dependency caching
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy the entire project into the container
COPY . .

# Build the Go app with optimizations (strip debug info, small binary size)
RUN go build -ldflags="-w -s" -o /app/server .

# Final stage - start with a minimal base image
FROM gcr.io/distroless/static-debian11

# Set working directory in the final image
WORKDIR /app

# Copy the Go binary from the builder stage
COPY --from=builder /app/server /app/server

# Set a non-root user for security (UID 1001)
USER 1001

# Expose the port that the API will use
EXPOSE 4201

# Expose the BIRD_API_HOST_NAME as an environment variable
ENV BIRD_API_HOST=localhost

# Expose the BIRD_API_HOST_PORT as an environment variable
ENV BIRD_API_HOST_PORT=4201

# Command to run the Go binary
CMD ["/app/server"]
