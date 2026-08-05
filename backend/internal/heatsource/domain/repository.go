package domain

import "context"

type BoilerHouseRepository interface {
	ListAll(
		ctx context.Context,
	) ([]BoilerHouse, error)
}