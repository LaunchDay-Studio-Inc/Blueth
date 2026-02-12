extends RefCounted
class_name BluethMetaProgression

const SAVE_PATH = "user://blueth_meta_v1.json"

const REALM_UNLOCK_ORDER = ["frostfields", "riftcore", "umbra_vault", "endless"]

const ACHIEVEMENTS = {
	"clear_frostfields": {"name": "Frostfields Breakout", "desc": "Win a run in Frostfields."},
	"clear_riftcore": {"name": "Riftcore Stabilized", "desc": "Win a run in Riftcore."},
	"clear_umbra_vault": {"name": "Umbra Vault Conquered", "desc": "Win a run in Umbra Vault."}
}

const DEFAULT_SETTINGS = {
	"music_volume": 0.85,
	"sfx_volume": 1.00,
	"flash_scale": 1.00,
	# Default shake was reported as too strong; keep it lower by default.
	"shake_scale": 0.65,
	"bg_intensity": 1.00,
	# Bool-like settings stored as 0/1 for simple persistence and clamping.
	"show_enemy_hp": 0.0,
	"show_boss_hp": 1.0,
	"show_damage_numbers": 1.0,
	"reduced_particles": 0.0
}

const NODES = [
	{"id": "vitality", "name": "Vitality Lattice", "desc": "+3.5% max HP per rank", "max_rank": 8, "base_cost": 7, "step_cost": 5},
	{"id": "arsenal", "name": "Arsenal Matrix", "desc": "+3.0% base damage per rank", "max_rank": 8, "base_cost": 8, "step_cost": 6},
	{"id": "tempo", "name": "Tempo Core", "desc": "+2.5% fire rate per rank", "max_rank": 8, "base_cost": 8, "step_cost": 6},
	{"id": "stride", "name": "Stride Memory", "desc": "+2.5% move speed per rank", "max_rank": 7, "base_cost": 6, "step_cost": 5},
	{"id": "aegis", "name": "Aegis Weave", "desc": "-3.0% incoming damage per rank", "max_rank": 7, "base_cost": 9, "step_cost": 7},
	{"id": "vacuum", "name": "Vacuum Relay", "desc": "+8.0% core charge gain per rank", "max_rank": 7, "base_cost": 7, "step_cost": 5},
	{"id": "recovery", "name": "Recovery Gel", "desc": "+0.25 HP/s regen per rank", "max_rank": 6, "base_cost": 10, "step_cost": 8},
	{"id": "surgecraft", "name": "Surgecraft", "desc": "+8.0% surge damage per rank", "max_rank": 6, "base_cost": 9, "step_cost": 8},
	{"id": "economy", "name": "Shatter Economy", "desc": "+12.0% mastery shard gains", "max_rank": 6, "base_cost": 10, "step_cost": 8},
	{"id": "luck", "name": "Luck Routing", "desc": "+2.0% chance to duplicate attacks", "max_rank": 6, "base_cost": 11, "step_cost": 9}
]

const SHOP_ITEMS = [
	{"id": "starter_magnet", "name": "Magnet Starter", "desc": "+60 pickup radius at run start.", "cost": 90},
	{"id": "starter_crit", "name": "Crit Starter", "desc": "+10% crit chance at run start.", "cost": 120},
	{"id": "starter_pierce", "name": "Pierce Starter", "desc": "+1 projectile pierce at run start.", "cost": 140},
	{"id": "starter_regen", "name": "Regen Starter", "desc": "+0.4 HP/s regen at run start.", "cost": 160},
	{"id": "laser_license", "name": "Prism License", "desc": "All heroes can draft Prism Sweep (rotating laser).", "cost": 220}
]

var state: Dictionary = {}


func _init() -> void:
	load_state()


func _default_state() -> Dictionary:
	return {
		"shards": 0,
		"total_shards_earned": 0,
		"runs_played": 0,
		"endless_best_time": 0.0,
		"endless_best_level": 0,
		"endless_best_kills": 0,
		"nodes": {},
		"shop": {},
		"realm_unlocks": {
			"frostfields": true,
			"riftcore": false,
			"umbra_vault": false,
			"endless": false
		},
		"achievements": {},
		"settings": DEFAULT_SETTINGS.duplicate(true)
	}


func load_state() -> void:
	state = _default_state()
	if FileAccess.file_exists(SAVE_PATH):
		var raw = FileAccess.get_file_as_string(SAVE_PATH)
		var parsed = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			state = parsed
	_sanitize_state()


func save_state() -> void:
	_sanitize_state()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(state, "\t"))


func _sanitize_state() -> void:
	if typeof(state) != TYPE_DICTIONARY:
		state = _default_state()
	if not state.has("shards"):
		state["shards"] = 0
	if not state.has("total_shards_earned"):
		state["total_shards_earned"] = 0
	if not state.has("runs_played"):
		state["runs_played"] = 0
	if not state.has("endless_best_time"):
		state["endless_best_time"] = 0.0
	if not state.has("endless_best_level"):
		state["endless_best_level"] = 0
	if not state.has("endless_best_kills"):
		state["endless_best_kills"] = 0
	if not state.has("nodes") or typeof(state["nodes"]) != TYPE_DICTIONARY:
		state["nodes"] = {}
	if not state.has("shop") or typeof(state["shop"]) != TYPE_DICTIONARY:
		state["shop"] = {}
	if not state.has("realm_unlocks") or typeof(state["realm_unlocks"]) != TYPE_DICTIONARY:
		state["realm_unlocks"] = {}
	if not state.has("achievements") or typeof(state["achievements"]) != TYPE_DICTIONARY:
		state["achievements"] = {}
	if not state.has("settings") or typeof(state["settings"]) != TYPE_DICTIONARY:
		state["settings"] = DEFAULT_SETTINGS.duplicate(true)

	for node in NODES:
		var node_id = String(node["id"])
		if not state["nodes"].has(node_id):
			state["nodes"][node_id] = 0
		state["nodes"][node_id] = int(clamp(int(state["nodes"][node_id]), 0, int(node["max_rank"])))

	for item in SHOP_ITEMS:
		var item_id = String(item.get("id", ""))
		if item_id == "":
			continue
		if not state["shop"].has(item_id):
			state["shop"][item_id] = false
		state["shop"][item_id] = bool(state["shop"][item_id])

	for realm_id in REALM_UNLOCK_ORDER:
		if not state["realm_unlocks"].has(realm_id):
			state["realm_unlocks"][realm_id] = (realm_id == "frostfields")
		state["realm_unlocks"][realm_id] = bool(state["realm_unlocks"][realm_id])
	state["realm_unlocks"]["frostfields"] = true

	for ach_id in ACHIEVEMENTS.keys():
		if not state["achievements"].has(ach_id):
			state["achievements"][ach_id] = false
		state["achievements"][ach_id] = bool(state["achievements"][ach_id])

	for k in DEFAULT_SETTINGS.keys():
		if not state["settings"].has(k):
			state["settings"][k] = DEFAULT_SETTINGS[k]
		state["settings"][k] = float(state["settings"][k])
	state["settings"]["music_volume"] = clamp(float(state["settings"]["music_volume"]), 0.0, 1.0)
	state["settings"]["sfx_volume"] = clamp(float(state["settings"]["sfx_volume"]), 0.0, 1.0)
	state["settings"]["flash_scale"] = clamp(float(state["settings"]["flash_scale"]), 0.0, 1.0)
	state["settings"]["shake_scale"] = clamp(float(state["settings"]["shake_scale"]), 0.0, 1.0)
	state["settings"]["bg_intensity"] = clamp(float(state["settings"]["bg_intensity"]), 0.4, 1.0)
	state["settings"]["show_enemy_hp"] = 1.0 if float(state["settings"]["show_enemy_hp"]) >= 0.5 else 0.0
	state["settings"]["show_boss_hp"] = 1.0 if float(state["settings"]["show_boss_hp"]) >= 0.5 else 0.0
	state["settings"]["show_damage_numbers"] = 1.0 if float(state["settings"]["show_damage_numbers"]) >= 0.5 else 0.0
	state["settings"]["reduced_particles"] = 1.0 if float(state["settings"]["reduced_particles"]) >= 0.5 else 0.0

	state["shards"] = max(0, int(state["shards"]))
	state["total_shards_earned"] = max(0, int(state["total_shards_earned"]))
	state["runs_played"] = max(0, int(state["runs_played"]))
	state["endless_best_time"] = max(0.0, float(state["endless_best_time"]))
	state["endless_best_level"] = max(0, int(state["endless_best_level"]))
	state["endless_best_kills"] = max(0, int(state["endless_best_kills"]))


func get_shards() -> int:
	return int(state.get("shards", 0))


func get_total_shards_earned() -> int:
	return int(state.get("total_shards_earned", 0))


func get_runs_played() -> int:
	return int(state.get("runs_played", 0))


func get_rank(node_id: String) -> int:
	return int((state.get("nodes", {}) as Dictionary).get(node_id, 0))


func _node_by_id(node_id: String) -> Dictionary:
	for node in NODES:
		if String(node["id"]) == node_id:
			return node
	return {}


func get_upgrade_cost(node_id: String) -> int:
	var node = _node_by_id(node_id)
	if node.is_empty():
		return 999999
	var rank = get_rank(node_id)
	if rank >= int(node["max_rank"]):
		return 999999
	return int(node["base_cost"]) + rank * int(node["step_cost"])


func can_upgrade(node_id: String) -> bool:
	var node = _node_by_id(node_id)
	if node.is_empty():
		return false
	var rank = get_rank(node_id)
	if rank >= int(node["max_rank"]):
		return false
	return get_shards() >= get_upgrade_cost(node_id)


func upgrade_node(node_id: String) -> bool:
	if not can_upgrade(node_id):
		return false
	var cost = get_upgrade_cost(node_id)
	state["shards"] = get_shards() - cost
	state["nodes"][node_id] = get_rank(node_id) + 1
	save_state()
	return true


func add_shards(amount: int, count_as_run: bool = true) -> void:
	if amount <= 0:
		return
	state["shards"] = get_shards() + amount
	state["total_shards_earned"] = get_total_shards_earned() + amount
	if count_as_run:
		state["runs_played"] = get_runs_played() + 1
	save_state()


func get_nodes_for_ui() -> Array:
	var rows: Array = []
	for node in NODES:
		var row: Dictionary = node.duplicate(true)
		var node_id = String(node["id"])
		row["rank"] = get_rank(node_id)
		row["cost"] = get_upgrade_cost(node_id)
		row["can_upgrade"] = can_upgrade(node_id)
		rows.append(row)
	return rows


func _shop_item_by_id(item_id: String) -> Dictionary:
	for item in SHOP_ITEMS:
		if String(item.get("id", "")) == item_id:
			return item
	return {}


func is_shop_item_owned(item_id: String) -> bool:
	return bool((state.get("shop", {}) as Dictionary).get(item_id, false))


func get_shop_items_for_ui() -> Array:
	var rows: Array = []
	for item in SHOP_ITEMS:
		var row: Dictionary = item.duplicate(true)
		var item_id = String(item.get("id", ""))
		row["owned"] = is_shop_item_owned(item_id)
		row["can_buy"] = (not row["owned"]) and (get_shards() >= int(item.get("cost", 999999)))
		rows.append(row)
	return rows


func buy_shop_item(item_id: String) -> bool:
	var item = _shop_item_by_id(item_id)
	if item.is_empty():
		return false
	if is_shop_item_owned(item_id):
		return false
	var cost = int(item.get("cost", 999999))
	if get_shards() < cost:
		return false
	state["shards"] = get_shards() - cost
	state["shop"][item_id] = true
	save_state()
	return true


func get_endless_record() -> Dictionary:
	return {
		"best_time": float(state.get("endless_best_time", 0.0)),
		"best_level": int(state.get("endless_best_level", 0)),
		"best_kills": int(state.get("endless_best_kills", 0))
	}


func submit_endless_record(time_survived: float, level_reached: int, kills_count: int) -> bool:
	var best_time = float(state.get("endless_best_time", 0.0))
	if time_survived <= best_time:
		return false
	state["endless_best_time"] = time_survived
	state["endless_best_level"] = level_reached
	state["endless_best_kills"] = kills_count
	save_state()
	return true


func get_run_modifiers() -> Dictionary:
	var vitality_rank = get_rank("vitality")
	var arsenal_rank = get_rank("arsenal")
	var tempo_rank = get_rank("tempo")
	var stride_rank = get_rank("stride")
	var aegis_rank = get_rank("aegis")
	var vacuum_rank = get_rank("vacuum")
	var recovery_rank = get_rank("recovery")
	var surge_rank = get_rank("surgecraft")
	var economy_rank = get_rank("economy")
	var luck_rank = get_rank("luck")

	var incoming_mult = max(0.55, 1.0 - 0.03 * float(aegis_rank))

	var out = {
		"max_hp_mult": 1.0 + 0.035 * float(vitality_rank),
		"damage_mult": 1.0 + 0.03 * float(arsenal_rank),
		"fire_rate_mult": 1.0 + 0.025 * float(tempo_rank),
		"move_speed_mult": 1.0 + 0.025 * float(stride_rank),
		"damage_taken_mult": incoming_mult,
		"core_gain_mult": 1.0 + 0.08 * float(vacuum_rank),
		"regen_per_sec": 0.25 * float(recovery_rank),
		"surge_damage_mult": 1.0 + 0.08 * float(surge_rank),
		"mastery_gain_mult": 1.0 + 0.12 * float(economy_rank),
		"duplicate_attack_chance": 0.02 * float(luck_rank),
		"extra_draft_choices": int(float(luck_rank) / 3.0)
	}

	# Permanent shop skills (always applied once purchased).
	if is_shop_item_owned("starter_magnet"):
		out["magnet_bonus"] = float(out.get("magnet_bonus", 0.0)) + 60.0
	if is_shop_item_owned("starter_crit"):
		out["crit_bonus"] = float(out.get("crit_bonus", 0.0)) + 0.10
	if is_shop_item_owned("starter_pierce"):
		out["pierce_bonus"] = int(out.get("pierce_bonus", 0)) + 1
	if is_shop_item_owned("starter_regen"):
		out["regen_bonus"] = float(out.get("regen_bonus", 0.0)) + 0.4
	if is_shop_item_owned("laser_license"):
		out["unlock_laser_all"] = true

	return out


func get_settings() -> Dictionary:
	return (state.get("settings", {}) as Dictionary).duplicate(true)


func set_setting(key: String, value) -> void:
	if not state.has("settings") or typeof(state["settings"]) != TYPE_DICTIONARY:
		state["settings"] = DEFAULT_SETTINGS.duplicate(true)
	state["settings"][key] = value
	save_state()


func is_realm_unlocked(realm_id: String) -> bool:
	return bool((state.get("realm_unlocks", {}) as Dictionary).get(realm_id, realm_id == "frostfields"))


func unlock_realm(realm_id: String) -> bool:
	if not state.has("realm_unlocks") or typeof(state["realm_unlocks"]) != TYPE_DICTIONARY:
		state["realm_unlocks"] = {}
	if is_realm_unlocked(realm_id):
		return false
	state["realm_unlocks"][realm_id] = true
	save_state()
	return true


func has_achievement(achievement_id: String) -> bool:
	return bool((state.get("achievements", {}) as Dictionary).get(achievement_id, false))


func grant_achievement(achievement_id: String) -> bool:
	if not state.has("achievements") or typeof(state["achievements"]) != TYPE_DICTIONARY:
		state["achievements"] = {}
	if has_achievement(achievement_id):
		return false
	state["achievements"][achievement_id] = true
	save_state()
	return true


func get_achievements_for_ui() -> Array:
	var rows: Array = []
	for ach_id in ACHIEVEMENTS.keys():
		var row: Dictionary = (ACHIEVEMENTS[ach_id] as Dictionary).duplicate(true)
		row["id"] = ach_id
		row["unlocked"] = has_achievement(ach_id)
		rows.append(row)
	return rows


func on_realm_victory(realm_id: String) -> Dictionary:
	var out = {
		"bonus_shards": 0,
		"unlocked_realm": "",
		"new_achievements": []
	}

	var ach_id = "clear_%s" % realm_id
	var newly_achieved = false
	if ACHIEVEMENTS.has(ach_id) and not has_achievement(ach_id):
		state["achievements"][ach_id] = true
		newly_achieved = true
		out["new_achievements"].append(ach_id)

	if newly_achieved:
		var bonus = 0
		var unlock_target = ""
		match realm_id:
			"frostfields":
				bonus = 40
				unlock_target = "riftcore"
			"riftcore":
				bonus = 60
				unlock_target = "umbra_vault"
			"umbra_vault":
				bonus = 90
				unlock_target = "endless"
			_:
				bonus = 0
				unlock_target = ""

		if bonus > 0:
			state["shards"] = get_shards() + bonus
			state["total_shards_earned"] = get_total_shards_earned() + bonus
			out["bonus_shards"] = bonus

		if unlock_target != "" and not is_realm_unlocked(unlock_target):
			state["realm_unlocks"][unlock_target] = true
			out["unlocked_realm"] = unlock_target

		save_state()

	return out
