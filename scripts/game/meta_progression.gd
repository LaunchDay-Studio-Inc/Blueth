extends RefCounted
class_name BluethMetaProgression

const SAVE_PATH = "user://blueth_meta_v1.json"

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

var state: Dictionary = {}


func _init() -> void:
	load_state()


func _default_state() -> Dictionary:
	return {
		"shards": 0,
		"total_shards_earned": 0,
		"runs_played": 0,
		"nodes": {}
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
	if not state.has("nodes") or typeof(state["nodes"]) != TYPE_DICTIONARY:
		state["nodes"] = {}

	for node in NODES:
		var node_id = String(node["id"])
		if not state["nodes"].has(node_id):
			state["nodes"][node_id] = 0
		state["nodes"][node_id] = int(clamp(int(state["nodes"][node_id]), 0, int(node["max_rank"])))

	state["shards"] = max(0, int(state["shards"]))
	state["total_shards_earned"] = max(0, int(state["total_shards_earned"]))
	state["runs_played"] = max(0, int(state["runs_played"]))


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


func add_shards(amount: int) -> void:
	if amount <= 0:
		return
	state["shards"] = get_shards() + amount
	state["total_shards_earned"] = get_total_shards_earned() + amount
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

	return {
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
		"extra_draft_choices": int(luck_rank / 3)
	}
