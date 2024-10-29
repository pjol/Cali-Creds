package creds

import (
	"database/sql"
	"fmt"
)

func CreateTables(db *sql.DB) error {
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS queue (
			address string PRIMARY KEY,
			cred string NOT NULL,
			time_created timestamp NOT NULL,
			last_tried timestamp
		);
	`)

	if err != nil {
		return fmt.Errorf("error creating queue table: %s", err)
	}

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS provers (
			url string NOT NULL,
			available boolean NOT NULL DEFAULT(TRUE)
		);
	`)

	if err != nil {
		return fmt.Errorf("error creating provers table: %s", err)
	}

	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS exchanges (
			id string PRIMARY KEY,
			token string NOT NULL,
			address string NOT NULL,
			qr string NOT NULL,
			link string NOT NULL,
			UNIQUE(address)
		);
	`)

	if err != nil {
		return fmt.Errorf("error creating exchanges table: %s", err)
	}

	return nil
}
