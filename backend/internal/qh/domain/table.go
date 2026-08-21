package domain

type QHTableKind string

const (
	QHTableKindQH          QHTableKind = "QH"
	QHTableKindCoefficient QHTableKind = "COEFFICIENT"
)

type QHTable struct {
	ID int64

	Code     string
	Appendix string
	Title    string

	Kind QHTableKind

	IsActive bool
}