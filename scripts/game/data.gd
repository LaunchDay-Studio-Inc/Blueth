extends RefCounted
class_name BluethData

const HEROES = [
	{
		"id": "warden",
		"name": "Blueth Warden",
		"tagline": "Balanced defender with a compact shotgun spread.",
		"weapon": "shotgun",
		"stats": {
			"max_hp": 112.0,
			"move_speed": 240.0,
			"fire_rate": 2.2,
			"damage": 13.0,
			"projectile_speed": 520.0,
			"projectile_pierce": 0,
			"pickup_magnet_radius": 140.0,
			"surge_distance": 340.0,
			"surge_damage": 24.0,
			"surge_radius": 128.0,
			"surge_slow_multiplier": 0.58,
			"surge_slow_duration": 1.5,
			"base_color": Color(0.33, 0.79, 0.94)
		}
	},
	{
		"id": "channeler",
		"name": "Blueth Channeler",
		"tagline": "Lighter health, high-rate piercing beam volleys.",
		"weapon": "beam",
		"stats": {
			"max_hp": 88.0,
			"move_speed": 258.0,
			"fire_rate": 3.0,
			"damage": 11.0,
			"projectile_speed": 560.0,
			"projectile_pierce": 1,
			"pickup_magnet_radius": 150.0,
			"surge_distance": 320.0,
			"surge_damage": 22.0,
			"surge_radius": 126.0,
			"surge_slow_multiplier": 0.60,
			"surge_slow_duration": 1.3,
			"base_color": Color(0.58, 0.91, 0.95)
		}
	},
	{
		"id": "drifter",
		"name": "Blueth Drifter",
		"tagline": "Boomerang specialist with high mobility and control.",
		"weapon": "boomerang",
		"stats": {
			"max_hp": 96.0,
			"move_speed": 286.0,
			"fire_rate": 2.0,
			"damage": 16.0,
			"projectile_speed": 470.0,
			"projectile_pierce": 2,
			"pickup_magnet_radius": 160.0,
			"surge_distance": 300.0,
			"surge_damage": 20.0,
			"surge_radius": 120.0,
			"surge_slow_multiplier": 0.56,
			"surge_slow_duration": 1.4,
			"base_color": Color(0.29, 0.95, 0.84)
		}
	}
]

const WEAPONS = {
	"shotgun": {
		"name": "Scatter Shot",
		"desc": "5 pellets with spread. Excels at close pressure."
	},
	"beam": {
		"name": "Pulse Beam",
		"desc": "Instant line strike with partial piercing."
	},
	"boomerang": {
		"name": "Arc Boomerang",
		"desc": "Returns to Blueth and can re-hit on return path."
	}
}

const REALMS = [
	{
		"id": "frostfields",
		"name": "Frostfields",
		"desc": "Beginner-friendly realm with slower swarms and safer damage scaling.",
		"mods": {
			"enemy_hp": 0.90,
			"enemy_speed": 0.92,
			"enemy_damage": 0.84,
			"spawn_interval": 1.16,
			"elite_rate": 0.82,
			"mastery_reward": 0.95,
			"bg_color": Color(0.08, 0.17, 0.24),
			"grid_color": Color(0.52, 0.78, 0.94, 0.06)
		}
	},
	{
		"id": "riftcore",
		"name": "Riftcore",
		"desc": "Standard arena rhythm with balanced pressure and reward scaling.",
		"mods": {
			"enemy_hp": 1.00,
			"enemy_speed": 1.00,
			"enemy_damage": 1.00,
			"spawn_interval": 1.00,
			"elite_rate": 1.00,
			"mastery_reward": 1.20,
			"bg_color": Color(0.08, 0.16, 0.22),
			"grid_color": Color(0.62, 0.86, 0.98, 0.07)
		}
	},
	{
		"id": "umbra_vault",
		"name": "Umbra Vault",
		"desc": "High-risk realm with denser elites, faster ramps, and bigger meta rewards.",
		"mods": {
			"enemy_hp": 1.24,
			"enemy_speed": 1.18,
			"enemy_damage": 1.20,
			"spawn_interval": 0.84,
			"elite_rate": 1.30,
			"mastery_reward": 1.65,
			"bg_color": Color(0.10, 0.10, 0.17),
			"grid_color": Color(0.82, 0.70, 0.99, 0.07)
		}
	},
	{
		"id": "endless",
		"name": "Endless",
		"desc": "Low-pressure endless realm for long sessions. Draft every minute, grind shards, and chase personal records.",
		"mods": {
			"enemy_hp": 0.80,
			"enemy_speed": 0.92,
			"enemy_damage": 0.76,
			"spawn_interval": 1.25,
			"elite_rate": 0.35,
			"mastery_reward": 0.65,
			"bg_color": Color(0.05, 0.10, 0.20),
			"grid_color": Color(0.46, 0.92, 0.88, 0.06)
		}
	}
]

static func hero_ids() -> Array:
	var ids: Array = []
	for hero in HEROES:
		ids.append(hero["id"])
	return ids


static func hero_by_id(hero_id: String) -> Dictionary:
	for hero in HEROES:
		if String(hero["id"]) == hero_id:
			return hero.duplicate(true)
	return HEROES[0].duplicate(true)


static func all_heroes() -> Array:
	var result: Array = []
	for hero in HEROES:
		result.append(hero.duplicate(true))
	return result


static func realm_by_id(realm_id: String) -> Dictionary:
	for realm in REALMS:
		if String(realm["id"]) == realm_id:
			return realm.duplicate(true)
	return REALMS[1].duplicate(true)


static func all_realms() -> Array:
	var result: Array = []
	for realm in REALMS:
		result.append(realm.duplicate(true))
	return result
