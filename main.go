package main

import (
	"encoding/base64"
	"errors"
	"fmt"
	"log"
	"net/url"
	"os/exec"
	"strings"

	"github.com/apple/pkl-go/pkl"
)

func main() {
	client, err := pkl.NewExternalReaderClient(
		pkl.WithExternalClientResourceReader(shellReader{}),
	)
	if err != nil {
		log.Fatal(err)
	}

	if err := client.Run(); err != nil {
		log.Fatal(err)
	}
}

type shellReader struct{}

func (shellReader) Scheme() string {
	return "shell"
}

func (shellReader) HasHierarchicalUris() bool {
	return false
}

func (shellReader) IsGlobbable() bool {
	return false
}

func (shellReader) ListElements(url.URL) ([]pkl.PathElement, error) {
	return nil, nil
}

func (shellReader) Read(uri url.URL) ([]byte, error) {
	var cmd string
	if encoded, ok := strings.CutPrefix(uri.Opaque, "b64:"); ok {
		decoded, err := base64.StdEncoding.DecodeString(encoded)
		if err != nil {
			return nil, fmt.Errorf("invalid base64 shell command: %w", err)
		}
		cmd = string(decoded)
	} else {
		var err error
		cmd, err = url.PathUnescape(uri.Opaque)
		if err != nil {
			return nil, err
		}
	}
	if cmd == "" {
		return nil, fmt.Errorf("empty shell command")
	}

	out, err := exec.Command("sh", "-c", cmd).Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return nil, fmt.Errorf("command failed: %w: %s", err, strings.TrimSpace(string(exitErr.Stderr)))
		}
		return nil, fmt.Errorf("command failed: %w", err)
	}

	return out, nil
}
