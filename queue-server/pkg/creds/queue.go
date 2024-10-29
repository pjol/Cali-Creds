package creds

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/pjol/go-async-queue-server/structs"
)

func (s *CredService) Enqueue(cred string, address string, currentTime *time.Time) error {
	t := time.Now()

	if currentTime == nil {
		currentTime = &t
	}

	_, err := s.db.Exec(`
		INSERT INTO queue (address, cred, time_created, last_tried) VALUES ($1, $2, $3, $4);
	`, address, cred, currentTime, t)
	if err != nil {
		return err
	}

	_, err = s.db.Exec(`
		DELETE FROM exchanges WHERE address = $1;
	`, address)
	if err != nil {
		return err
	}

	prover, err := s.GetAvailable()
	if err == nil {
		go s.NewWorker(prover)
		return nil
	}

	return nil
}

func (s *CredService) GetNext() (*structs.QueueItem, error) {

	item := structs.QueueItem{}

	row := s.db.QueryRow(`
		SELECT address, cred, time_created FROM queue ORDER BY last_tried ASC LIMIT 1;
	`)

	err := row.Scan(&item.Address, &item.Cred, &item.TimeCreated)
	if err != nil {
		return nil, err
	}

	_, err = s.db.Exec(`
		DELETE FROM queue WHERE address = $1;
	`, item.Address)
	if err != nil {
		return nil, err
	}

	return &item, nil
}

func (s *CredService) NewWorker(url string) {
	fmt.Println("made worker: ", url)
	for {
		item, err := s.GetNext()
		if err != nil {
			fmt.Println("destroyed worker: ", url)
			s.SetAvailable(url, true)
			return
		}
		fmt.Println(item)
		expired := time.Since(item.TimeCreated) > time.Minute*50

		if item.Address == "" || expired {
			continue
		}
		retry, err := sendCred(url, item)
		if err != nil && retry {
			fmt.Println("retrying")
			s.Enqueue(item.Cred, item.Address, &item.TimeCreated)
		}
	}
}

func sendCred(url string, item *structs.QueueItem) (bool, error) {

	fmt.Println("sending cred")

	prover_key := os.Getenv("PROVER_KEY")
	url = url + "/prove"

	body, err := json.Marshal(&item)
	if err != nil {
		return false, err
	}

	client := http.DefaultClient
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(body))
	if err != nil {
		return false, err
	}

	req.Header.Add("Authorization", "Bearer "+prover_key)

	res, err := client.Do(req)
	if err != nil {
		return true, err
	}
	if res.StatusCode == 400 {
		return false, err
	}

	fmt.Println("cred sent")

	return true, err
}
