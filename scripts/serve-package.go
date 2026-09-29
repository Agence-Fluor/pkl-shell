package main

import (
	"log"
	"net"
	"net/http"
	"os"
)

func main() {
	if len(os.Args) != 3 {
		log.Fatal("usage: serve-package <directory> <address-file>")
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		log.Fatal(err)
	}
	if err := os.WriteFile(os.Args[2], []byte(listener.Addr().String()), 0600); err != nil {
		log.Fatal(err)
	}
	log.Fatal(http.Serve(listener, http.FileServer(http.Dir(os.Args[1]))))
}
