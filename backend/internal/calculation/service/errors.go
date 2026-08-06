package service

import "errors"

var (
	ErrInvalidInput = errors.New(
		"invalid calculation input",
	)

	ErrNotFound = errors.New(
		"calculation reference not found",
	)
)