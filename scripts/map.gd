extends Node

const Bloc = preload("res://scripts/card.gd").Bloc
enum Region{AFR, ME, EGY, SSL, ALL}

class Country:
	var id : int
	var name : String
	var stability : int
	var inf_soviet : int
	var inf_usa : int
	var region : Region
	var battleground : bool
	var flashpoint = false
	var famine = false
	var adjacent = Array()
	
	func _init(id, name, stability,region, battleground) -> void:
		self.id = id
		self.name = name
		self.stability = stability
		self.region = region
		self.battleground = battleground
	
	func sov_control() -> bool:
		return inf_soviet >= inf_usa + stability
	
	func usa_control() -> bool:
		return inf_usa >= inf_soviet + stability
	

var map = Array()

func neg_modifier(id : int, bloc : Bloc) -> int:
	var modifier = 0
	if bloc == Bloc.USA:
		for adj_country_id in map[id].adjacent:
			if map[adj_country_id].sov_control():
				modifier -= 1
	else:
		for adj_country_id in map[id].adjacent:
			if map[adj_country_id].usa_control():
				modifier -= 1
	return modifier

func placement_eligible_soviet() -> Array:
	var eligible = Array()
	eligible.append(11)
	for country : Country in map:
		if country.inf_soviet > 0:
			if not eligible.has(country.id):
				eligible.append(country.id)
			for adj in country.adjacent:
				if not eligible.has(adj):
					eligible.append(adj)
	return eligible

func placement_eligible_usa() -> Array:
	var eligible = Array()
	eligible.append(11)
	for country : Country in map:
		if country.inf_usa > 0:
			if not eligible.has(country.id):
				eligible.append(country.id)
			for adj in country.adjacent:
				if not eligible.has(adj):
					eligible.append(adj)
	return eligible

func _ready():
	map.append(Country.new(0, "Египет", 2, Region.EGY, true))
	map[0].adjacent.append(1)
	map.append(Country.new(1, "Судан", 1, Region.AFR, false))
	map[1].adjacent.append(0)
	map[1].adjacent.append(2)
	map[1].adjacent.append(4)
	map.append(Country.new(2, "Эфиопия", 1, Region.AFR, false))
	map[2].flashpoint = true
	map[2].adjacent.append(1)
	map[2].adjacent.append(5)
	map.append(Country.new(3, "Джибути", 2, Region.AFR, false))
	map[3].adjacent.append(4)
	map[3].adjacent.append(8)
	map.append(Country.new(4, "Сомали", 2, Region.AFR, false))
	map[4].flashpoint = true
	map[4].adjacent.append(1)
	map[4].adjacent.append(3)
	map[4].adjacent.append(5)
	map[4].adjacent.append(6)
	map.append(Country.new(5, "Кения", 2, Region.AFR, true))
	map[5].adjacent.append(2)
	map[5].adjacent.append(4)
	map[5].adjacent.append(6)
	map.append(Country.new(6, "Мадагаскар", 2, Region.AFR, false))
	map[6].adjacent.append(4)
	map[6].adjacent.append(5)
	map.append(Country.new(7, "Саудовская Аравия", 3, Region.ME, true))
	map[7].adjacent.append(8)
	map[7].adjacent.append(9)
	map[7].adjacent.append(10)
	map.append(Country.new(8, "Ю. Йемен", 1, Region.ME, false))
	map[8].adjacent.append(3)
	map[8].adjacent.append(7)
	map.append(Country.new(9, "Йемен", 2, Region.ME, false))
	map[9].adjacent.append(7)
	map.append(Country.new(10, "Оман", 2, Region.ME, false))
	map[10].adjacent.append(7)
	map.append(Country.new(11, "Стратегические Морские Пути", 4, Region.SSL, true))
