package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

func main() {
	appName := os.Getenv("APP_NAME")
	appPort := os.Getenv("APP_PORT")
	logLevel := os.Getenv("LOG_LEVEL")

	fmt.Printf("[%s] Starting on port %s (log_level=%s)\n", appName, appPort, logLevel)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"service":       appName,
			"port":          appPort,
			"log_level":     logLevel,
			"config_source": "environment variable",
			"message":       "Config loaded successfully!",
		})
	})

	http.ListenAndServe(":"+appPort, nil)
}
