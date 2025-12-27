package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

func main() {
	url := "http://localhost:8080/api/stores/casino-royale/products"
	resp, err := http.Get(url)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)
	// fmt.Println(string(body))

	var response struct {
		Products []map[string]interface{} `json:"products"`
		Total    int                      `json:"total_count"`
	}
	json.Unmarshal(body, &response)

	fmt.Printf("API Total Count: %d\n", response.Total)
	fmt.Printf("Products returned: %d\n", len(response.Products))
	for _, p := range response.Products {
		fmt.Printf("- %s (LastConfirmed: %v)\n", p["title"], p["last_confirmed_at"])
	}
}
