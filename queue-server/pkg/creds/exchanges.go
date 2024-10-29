package creds

import (
	"encoding/json"
	"io"
	"net/http"
	"os"

	"github.com/pjol/go-async-queue-server/structs"
)

func (s *CredService) CreateExchange(address string) (*structs.Exchange, error) {

	opencred_server := os.Getenv("OPENCRED_SERVER")
	opencred_workflow_id := os.Getenv("OPENCRED_WORKFLOW_ID")
	opencred_username := os.Getenv("OPENCRED_USERNAME")
	opencred_password := os.Getenv("OPENCRED_PASSWORD")

	url := opencred_server + "/workflows/" + opencred_workflow_id + "/exchanges"

	client := http.DefaultClient

	req, err := http.NewRequest("POST", url, nil)
	if err != nil {
		return nil, err
	}
	req.SetBasicAuth(opencred_username, opencred_password)

	res, err := client.Do(req)
	if err != nil {
		return nil, err
	}

	body, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	exchange := structs.Exchange{}
	json.Unmarshal(body, &exchange)

	_, err = s.db.Exec(`
		INSERT INTO exchanges (id, token, address, qr, link) VALUES ($1, $2, $3, $4, $5);
	`, exchange.Id, exchange.Token, address, exchange.Qr, exchange.Link)
	if err != nil {
		return nil, err
	}

	return &exchange, nil
}

func (s *CredService) DeleteExchange(address string) error {

	_, err := s.db.Exec(`
		DELETE FROM exchanges WHERE address = $1;
	`)

	return err
}

func (s *CredService) GetAccessToken(id string) (string, error) {
	var token string

	row := s.db.QueryRow(`
		SELECT token FROM exchanges WHERE id = $1;
	`, id)

	err := row.Scan(&token)
	if err != nil {
		return "", err
	}

	return token, nil
}

func (s *CredService) GetExchange(address string) (*structs.Exchange, error) {

	exchange := structs.Exchange{}

	row := s.db.QueryRow(`
		SELECT id, token, qr, link FROM exchanges WHERE address = $1;
	`, address)

	err := row.Scan(&exchange.Id, &exchange.Token, &exchange.Qr, &exchange.Link)
	if err != nil {
		return nil, err
	}

	return &exchange, nil
}

func (s *CredService) GetExchangeOwner(id string) (string, error) {

	var address string

	row := s.db.QueryRow(`
		SELECT address FROM exchanges WHERE id = $1;
	`, id)

	err := row.Scan(&address)
	if err != nil {
		return "", err
	}

	return address, nil
}
