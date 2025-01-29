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
