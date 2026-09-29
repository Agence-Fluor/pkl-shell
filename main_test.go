package main

import (
	"encoding/base64"
	"net/url"
	"strings"
	"testing"
)

func TestShellReader(t *testing.T) {
	uri, err := url.Parse("shell:printf%20hello%3B%20printf%20warning%20%3E%262")
	if err != nil {
		t.Fatal(err)
	}

	out, err := (shellReader{}).Read(*uri)
	if err != nil {
		t.Fatal(err)
	}
	if string(out) != "hello" {
		t.Fatalf("stdout = %q, want %q", out, "hello")
	}
}

func TestShellReaderBase64(t *testing.T) {
	command := "printf '%s' 'é # ? % /'"
	uri, err := url.Parse("shell:b64:" + base64.StdEncoding.EncodeToString([]byte(command)))
	if err != nil {
		t.Fatal(err)
	}

	out, err := (shellReader{}).Read(*uri)
	if err != nil {
		t.Fatal(err)
	}
	if string(out) != "é # ? % /" {
		t.Fatalf("stdout = %q, want %q", out, "é # ? % /")
	}
}

func TestShellReaderFailure(t *testing.T) {
	uri, err := url.Parse("shell:printf%20failure%20%3E%262%3B%20exit%207")
	if err != nil {
		t.Fatal(err)
	}

	_, err = (shellReader{}).Read(*uri)
	if err == nil || !strings.Contains(err.Error(), "exit status 7") || !strings.Contains(err.Error(), "failure") {
		t.Fatalf("error = %v, want exit status and stderr", err)
	}
}
