package calculationhttp

import (
	"encoding/json"
	"log/slog"
	"net/http"
)

func writeJSON(
	w http.ResponseWriter,
	status int,
	data any,
) {
	w.Header().Set(
		"Content-Type",
		"application/json; charset=utf-8",
	)

	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		slog.Error(
			"failed to encode HTTP response",
			"error",
			err,
		)
	}
}

func writeError(
	w http.ResponseWriter,
	status int,
	code string,
	message string,
) {
	writeJSON(
		w,
		status,
		map[string]any{
			"error": map[string]string{
				"code":    code,
				"message": message,
			},
		},
	)
}
