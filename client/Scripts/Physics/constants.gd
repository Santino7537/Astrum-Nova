extends Node

## Constante gravitatoria
const Gravity: float = 6.67430e-11
## Unidad astronómica
const AU := 149597870700.0

## Unidades de medida para la masa
enum MASS_UNITS {
	kg,
	Msun
}
## Unidades de medida para la longitud
enum LENGTH_UNITS {
	m,
	km
}
## Unidades de medida para la velocidad
enum VELOCITY_UNITS {
	km_s,
	km_h,
	m_s
}

## Factores de conversión de masa a kg
const MASS_FACTORS := {
	MASS_UNITS.kg: 1.0,
	MASS_UNITS.Msun: 1.98847e30
}
## Factores de conversión de longitud a m
const LENGTH_FACTORS := {
	LENGTH_UNITS.m: 1.0,
	LENGTH_UNITS.km: 1000.0
}
## Factores de conversión de velocidad a m/s
const VELOCITY_FACTORS := {
	VELOCITY_UNITS.km_s: 1000.0,
	VELOCITY_UNITS.km_h: 1000.0 / 3600.0,
	VELOCITY_UNITS.m_s: 1.0
}

## Convierte una magnitud de masa en cualquiera de sus unidades
func mass_converter(value: float, value_unit: MASS_UNITS, result_unit: MASS_UNITS) -> float:
	var value_in_kg: float = value * MASS_FACTORS[value_unit]
	return value_in_kg / MASS_FACTORS[result_unit]

## Convierte una magnitud de longitud en cualquiera de sus unidades
func length_converter(value: float, value_unit: LENGTH_UNITS, result_unit: LENGTH_UNITS) -> float:
	var value_in_m: float = value * LENGTH_FACTORS[value_unit]
	return value_in_m / LENGTH_FACTORS[result_unit]

## Convierte una magnitud de velocidad en cualquiera de sus unidades
func velocity_converter(value: float, value_unit: VELOCITY_UNITS, result_unit: VELOCITY_UNITS) -> float:
	var value_in_m_s: float = value * VELOCITY_FACTORS[value_unit]
	return value_in_m_s / VELOCITY_FACTORS[result_unit]
