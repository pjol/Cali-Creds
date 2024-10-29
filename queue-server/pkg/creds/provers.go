package creds

func (s *CredService) GetAvailable() (string, error) {

	var url string

	row := s.db.QueryRow(`
		SELECT url FROM provers WHERE available = true;
	`)

	err := row.Scan(&url)
	if err != nil || url == "" {
		return "", err
	}

	err = s.SetAvailable(url, false)
	if err != nil {
		return "", err
	}

	return url, nil
}

func (s *CredService) SetAvailable(url string, val bool) error {

	_, err := s.db.Exec(`
		UPDATE provers SET available = $1 WHERE url = $2;
	`, val, url)

	return err
}

func (s *CredService) SetAllAvailable() error {

	_, err := s.db.Exec(`
		UPDATE provers SET available = true;
	`)

	return err
}
