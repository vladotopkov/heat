package domain

import (
	"errors"
	"time"
)

var (
	ErrNetworkSectionNotFound = errors.New("network section not found")
	ErrHeatNetworkNotFound    = errors.New("heat network not found")
	ErrQHValueNotFound        = errors.New("matching qh_value not found")
	ErrAmbiguousQHValue       = errors.New("multiple equally suitable qh_values found")
	ErrBetaValueNotFound      = errors.New("matching beta value not found")
	ErrAmbiguousBetaValue     = errors.New("multiple equally suitable beta values found")
)

type HeatNetwork struct {
	ID                               int64
	Name                             string
	ProjectSupplyTemperature         *float64
	ProjectReturnTemperature         *float64
	GVSProjectSupplyTemperature      *float64
	GVSProjectCirculationTemperature *float64
}

// NetworkSection contains only the section characteristics which have a
// direct (or safely derivable) counterpart in qh_values.
type NetworkSection struct {
	ID             int64
	HeatNetworkID  int64
	QHTableID      int64
	QHTableCode    string
	QHTableName    string
	NetworkType    string
	JointChannelID *int64
	SectionName    *string

	LayingType            *string
	UndergroundLayingType *string
	SupportType           *string
	NominalBoreMM         *float64
	LengthM               *float64
	ProjectDate           *time.Time
	Beta                  *float64

	BurialDepthM      *float64
	TemperatureC      *float64
	SupplyTemperature *float64
	ReturnTemperature *float64

	SupplyOuterDiameter      *float64
	SupplyWallThickness      *float64
	SupplyShellOuterDiameter *float64
	ReturnOuterDiameter      *float64
	ReturnWallThickness      *float64
	ReturnShellOuterDiameter *float64
}

type BetaValue struct {
	ID int64

	ProjectDateFrom *time.Time
	ProjectDateTo   *time.Time

	LayingType            *string
	UndergroundLayingType *string
	SupportType           *string
	NominalBoreFromMM     *float64
	NominalBoreToMM       *float64
	PipeType              *string
	ObjectKind            *string

	Value float64
	Note  *string
}

type QHValue struct {
	ID        int64
	QHTableID int64

	OuterDiameterMM             *float64
	NominalBoreMM               *float64
	PipeSize                    *string
	PressurePipeInnerDiameterMM *float64
	PressurePipeOuterDiameterMM *float64
	PressurePipeWallThicknessMM *float64
	ShellOuterDiameterMM        *float64
	ShellWallThicknessMM        *float64
	ChannelHeightM              *float64
	ChannelWidthM               *float64
	ThermalResistance           *float64
	BurialDepthM                *float64
	AxisDistanceM               *float64
	ObjectKind                  *string
	PlacementVariant            *string
	PipelineRole                *string
	TemperatureC                *float64
	SupplyTemperatureC          *float64
	ReturnTemperatureC          *float64
	Value                       float64
	SourceInterpolated          bool
	SupplyValue                 *float64
	ReturnValue                 *float64
	Note                        *string
}

type Match struct {
	NetworkSectionID int64
	QHTableID        int64
	QHValue          QHValue
	MatchedFields    []string
}

type NetworkSectionWithQH struct {
	Section   NetworkSection
	QHValue   *QHValue
	QHError   *string
	Beta      *BetaValue
	BetaError *string
}

type HeatNetworkSections struct {
	HeatNetwork HeatNetwork
	Sections    []NetworkSectionWithQH
}
