package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/joho/godotenv"
	"github.com/pjol/go-async-queue-server/router"
)

func main() {
	fmt.Println("starting server...")

	godotenv.Load()

	fmt.Println("env loaded")

	port := os.Getenv("PORT")

	r := router.AppRouter()

	fmt.Printf("now listening on port %s\n", port)

	http.ListenAndServe(fmt.Sprintf(":%s", port), r)
}
