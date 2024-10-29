package router

import (
	"fmt"
	"log"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/pjol/go-async-queue-server/internal/db"
	"github.com/pjol/go-async-queue-server/pkg/creds"
)

func AppRouter() *chi.Mux {
	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000", "https://localhost:3000", "*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	fmt.Println("middleware active")

	credsDB, err := db.InitDB("creds")
	if err != nil {
		log.Fatalf("failed to initialize creds db: %s", err)
	}

	fmt.Println("connected to creds db")

	fmt.Println("creating creds db tables")

	creds.CreateTables(credsDB)
	s := creds.CreateService(credsDB)
	s.SetAllAvailable()

	r.Route("/exchange", func(r chi.Router) {
		// r.Use(creds.GetCountMiddleware())
		r.Get("/{address}", s.HandleGetExchange)
	})

	r.Route("/callback", func(r chi.Router) {
		r.Post("/", s.HandleCallback)
	})

	return r

}
