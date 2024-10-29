package db

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/mattn/go-sqlite3"
	"github.com/pjol/go-async-queue-server/pkg/creds"
)

func InitDB(name string) (*sql.DB, error) {
	dbFolderPath := "./data"
	dbPath := fmt.Sprintf("%s/%s.db", dbFolderPath, name)

	if !Exists(dbFolderPath) {
		fmt.Printf("no %s db folder found... creating\n", name)
		os.Mkdir(dbFolderPath, os.ModePerm)
	}

	if !Exists(dbPath) {
		fmt.Printf("no %s db found... creating\n", name)

		os.Create(dbPath)
	}

	fmt.Printf("connecting to %s db...\n", name)

	db, err := sql.Open("sqlite3", fmt.Sprintf("file:%s", dbPath))
	if err != nil {
		return nil, err
	}

	err = InitTables(name, db)
	if err != nil {
		return nil, err
	}

	return db, nil

}

func Exists(path string) bool {
	exists := true
	_, err := os.Stat(path)
	if err != nil {
		fmt.Println(err)
		exists = false
	}

	if os.IsExist(err) {
		exists = true
	}

	return exists
}

func InitTables(name string, db *sql.DB) error {
	// db.Exec(fmt.Sprintf("CREATE DATABASE %s", name))
	switch name {
	case "creds":
		err := creds.CreateTables(db)

		if err != nil {
			return err
		}

	}
	return nil
}
