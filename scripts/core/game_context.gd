class_name GameContext
extends RefCounted

var balance: GameBalanceConfig
var validation_warnings: Array[String] = []
var bank: ResourceBank
var colony: Colony
var research: ResearchManager
var modifiers: StatModifiers
var arena: Arena
var flower_field: FlowerField
var buildings_root: Node2D
var bees_root: Node2D
var enemies_root: Node2D
var projectiles_root: Node2D
var queen: Building
var effects: EffectsLayer
var camera: CameraController


func get_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	if not is_instance_valid(enemies_root):
		return result
	for child: Node in enemies_root.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion() and child is Enemy:
			result.append(child as Enemy)
	return result


func get_hostile_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy: Enemy in get_enemies():
		if enemy.faction == GameEnums.Faction.HOSTILE and enemy.is_targetable():
			result.append(enemy)
	return result
