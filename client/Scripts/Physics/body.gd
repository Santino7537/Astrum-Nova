## Esta clase sirve para contener la lógica y datos de cada cuerpo individual
class_name Body extends MeshInstance3D

const SOLAR_LUMINOSITY := 3.828e26  # W

# Parámetros artísticos: ajustalos a la escala de tu simulación
# Esto porque godot usa unidades arbitrarias y entonces usamos el sol como referencia, dale martin subite a la jam
const SUN_LIGHT_ENERGY := 2.0 # light_energy que tendría una estrella como el Sol
const SUN_LIGHT_RANGE := 500.0 # alcance (unidades de Godot) de una estrella como el Sol
const SUN_EMISSION_ENERGY := 3.0

var body_data : CelestialBody

func init_body() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_data.color

	if body_data.is_star():
		var lum_rel := body_data.luminosity() / SOLAR_LUMINOSITY  # 1.0 = como el Sol

		# Material emisivo (el glow lo aporta el WorldEnvironment) importante esto martin acordate de esto por favor
		mat.emission_enabled = true
		mat.emission = body_data.color
		mat.emission_energy_multiplier = SUN_EMISSION_ENERGY * (1.0 + log(1.0 + lum_rel) / log(10.0))

		# Luz omnidireccional
		var light := OmniLight3D.new()
		light.light_color = body_data.color
		light.omni_attenuation = 2.0                 # caída tipo 1/d²
		light.light_energy = clampf(SUN_LIGHT_ENERGY * sqrt(lum_rel), 0.1, 16.0)
		light.omni_range = SUN_LIGHT_RANGE * sqrt(lum_rel)  # d ∝ √L
		light.shadow_enabled = true
		add_child(light)

		# Evita que la propia mesh tape su luz
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	material_override = mat
