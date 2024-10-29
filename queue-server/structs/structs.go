package structs

import "time"

type ExchangeResult struct {
	Id          string            `json:"id"`
	Variables   ExchangeVariables `json:"variables"`
	TimeCreated string            `json:"updatedAt"`
}

type ExchangeVariables struct {
	Results ExchangeResults `json:"results"`
}

type ExchangeResults struct {
	Default ExchangeDefault `json:"default"`
}

type ExchangeDefault struct {
	VPToken string `json:"vpToken"`
}

type ExchangeUrl struct {
	Url string `json:"id"`
}

type Exchange struct {
	Id    string `json:"id"`
	Link  string `json:"OID4VP"`
	Qr    string `json:"QR"`
	Token string `json:"accessToken"`
}

type QueueItem struct {
	Address     string    `json:"addr"`
	Cred        string    `json:"cred"`
	TimeCreated time.Time `json:"iat"`
}
