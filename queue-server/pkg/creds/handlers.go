package creds

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/pjol/go-async-queue-server/structs"
)

// Gets an exchange for a given blockchain address.
func (s *CredService) HandleGetExchange(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	address := strings.Split(r.URL.Path, "/")[2]

	fmt.Println("address:" + address)

	// Check to see if user has an open exchange that hasn't been filled out yet.
	exchange, err := s.GetExchange(address)
	if err != nil && address != "" {
		exchange, err = s.CreateExchange(address)
	}

	// If not, call out to opencred server & make exchange.
	if err != nil {
		fmt.Println("error creating exchange:", err)
		w.WriteHeader(http.StatusInternalServerError)
	}

	res, err := json.Marshal(exchange)
	if err != nil {
		fmt.Println("error marshalling exchange body:", err)
		w.WriteHeader(http.StatusInternalServerError)
	}

	w.Write(res)
}

// Handles the opencred callback, determines the address corresponding to the exchange and enqueues the VP token and address to be sent to the prover.
func (s *CredService) HandleCallback(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()

	// fmt.Println("got callback")
	// exchangeUrl := structs.ExchangeUrl{}

	// body, err := io.ReadAll(r.Body)
	// if err != nil {
	// 	fmt.Println("error reading callback body: ", err)
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	return
	// }
	// // Parse callback into ExchangeResult struct
	// fmt.Println("body: ", string(body))
	// err = json.Unmarshal(body, &exchangeUrl)
	// if err != nil {
	// 	fmt.Println("error unmarshalling exchange url: ", err)
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	return
	// }

	// exurl, err := url.Parse(exchangeUrl.Url)
	// if err != nil {
	// 	fmt.Println("error parsing url: ", err)
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	return
	// }

	// id := strings.Split(exurl.Path, "/")[4]
	// fmt.Println("id: ", id)

	// accessToken, err := s.GetAccessToken(id)
	// if err != nil {
	// 	fmt.Println("error getting access token: ", err)
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	return
	// }

	// req, err := http.NewRequest("GET", exchangeUrl.Url, nil)
	// if err != nil {
	// 	fmt.Println("error creating request: ", err)
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	return
	// }
	// req.Header.Add("Authorization", "Bearer "+accessToken)

	// client := http.DefaultClient

	// res, err := client.Do(req)
	// if err != nil {
	// 	fmt.Println("error fetching exchange result: ", err)
	// 	w.WriteHeader(http.StatusBadRequest)
	// 	return
	// }

	exchangeResult := structs.ExchangeResult{}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println("error reading callback body: ", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	// Parse callback into ExchangeResult struct
	fmt.Println("body: ", string(body))
	err = json.Unmarshal(body, &exchangeResult)
	if err != nil {
		fmt.Println("error unmarshalling exchange result: ", err)
		w.WriteHeader(http.StatusBadRequest)
	}

	exurl, err := url.Parse(exchangeResult.Id)
	if err != nil {
		fmt.Println("error parsing url: ", err)
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	id := strings.Split(exurl.Path, "/")[4]

	fmt.Println(id)
	fmt.Println(exchangeResult.TimeCreated)
	fmt.Println(exchangeResult.Variables.Results.Default.VPToken)

	address, err := s.GetExchangeOwner(id)
	if err != nil {
		fmt.Println("error getting exchange owner: ", err)
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("No owner found for given exchange."))
	}

	err = s.Enqueue(exchangeResult.Variables.Results.Default.VPToken, address, nil)
	if err != nil {
		fmt.Println("error enqueueing: ", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	fmt.Println("enqueued")

	w.WriteHeader(http.StatusOK)
}
