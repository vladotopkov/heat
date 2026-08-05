package config

import (
	"errors"
	"os"
)

type Config struct {
	DatabaseURL  string
	Port         string
	AllowOrigin  string
}

func Load() (Config, error) {
	cfg := Config{
		DatabaseURL: os.Getenv("DATABASE_URL"),
		Port:        os.Getenv("PORT"),
		AllowOrigin: os.Getenv("CORS_ALLOWED_ORIGIN"),
	}

	if cfg.DatabaseURL == "" {
		return Config{}, errors.New(
			"DATABASE_URL environment variable is required",
		)
	}

	if cfg.Port == "" {
		cfg.Port = "8080"
	}

	if cfg.AllowOrigin == "" {
		cfg.AllowOrigin = "http://localhost:3000"
	}

	return cfg, nil
}