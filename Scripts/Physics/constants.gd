extends RefCounted

## Constante gravitatoria
const Gravity: float = 6.67430e-11

## Genera una id aleatoria de tipo String
func generate_id(length: int = 16) -> String:
	var chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var id := ""
	
	for i in range(length):
		id += chars[randi() % chars.length()]
	
	return id
