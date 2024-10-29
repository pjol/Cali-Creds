package creds

import "database/sql"

type CredService struct {
	db *sql.DB
}

func CreateService(db *sql.DB) *CredService {
	return &CredService{db: db}
}
