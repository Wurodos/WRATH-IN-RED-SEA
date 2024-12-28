extends Node

enum Bloc{USA, USSR, NEUTRAL}
enum Period{MID, LATE}

const MapFilter = preload("res://scripts/map_ui.gd").MapFilter
const Region = preload("res://scripts/map.gd").Region
const Phase = preload("res://scripts/game.gd").Phase

class Card:
	var id : int
	var sprite : Material
	var name : String
	var ops: int
	var desc : String
	var bloc : Bloc
	var asterisk : bool
	var period : Period
	var map : Node
	var confirm_button : Node
	static var mid_war_deck : Array
	static var discard : Array
	static var card_manifest : Array
	
	signal choose_a_country(map_filter : MapFilter, effect : Callable)
	
	
	func _init() -> void:
		self.asterisk = false
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print("ERROR")
	
	static func find_in_deck(deck: Array, id: int) -> Card:
		for card: Card in deck:
			if card.id == id:
				return card
		return null

signal apply_ui

func test():
	print("It's working???")

@rpc("authority", "call_local")
func setup():
	print("am")
	Card.mid_war_deck.append(PeaceCorps.new())
	Card.mid_war_deck.append(OgadenWar.new())
	Card.mid_war_deck.append(USAID.new())
	Card.mid_war_deck.append(VictoriousLeader.new())
	Card.mid_war_deck.append(EritreanPopularLiberationFront.new())
	Card.mid_war_deck.append(FrenchConnections.new())
	Card.mid_war_deck.append(HeroOfTheCrossing.new())
	Card.mid_war_deck.append(IsraeliPeripheryDoctrine.new())
	Card.mid_war_deck.append(TheStrongManOfSudan.new())
	Card.mid_war_deck.append(DiegoGarcia.new())
	Card.mid_war_deck.append(SovietsAirliftCubans.new())
	Card.mid_war_deck.append(Detente.new())
	Card.mid_war_deck.append(LionFalters.new())
	Card.mid_war_deck.append(DhofarRebellion.new())
	Card.mid_war_deck.append(Nasserism.new())
	Card.mid_war_deck.append(TheDerg.new())
	Card.mid_war_deck.append(USElections.new())
	Card.mid_war_deck.append(F5EDelivered.new())
	Card.mid_war_deck.append(CyrusVance.new())
	Card.mid_war_deck.append(MalagasyConstitutionalReferendum.new())
	Card.mid_war_deck.append(YemeniPresidentialAssassinations.new())
	Card.mid_war_deck.append(AfricaScoring.new())
	Card.mid_war_deck.append(Famine.new())
	Card.mid_war_deck.append(Separatists.new())
	Card.mid_war_deck.append(ArabLeague.new())
	Card.mid_war_deck.append(ApolloSoyuzTestProject.new())
	Card.mid_war_deck.append(IndianOceanZoneOfPeace.new())
	Card.mid_war_deck.append(WaterWars.new())
	Card.card_manifest = Card.mid_war_deck.duplicate()
	
	Card.card_manifest.append(RomanianAutonomy.new())
	
	Card.mid_war_deck.shuffle()
	Card.discard = Array()
	var map_script = get_parent()
	var confirm_button = get_parent().get_node("Confirmation")
	for card: Card  in Card.mid_war_deck:
		card.choose_a_country.connect(map_script.enable_countries)
		card.map = map_script
		card.confirm_button = confirm_button

class Blank extends Card:
	func _init() -> void:
		self.id = -1
		self.ops = 1
		self.bloc = Bloc.NEUTRAL
	

# ============================ USA Mid War ==============================

class PeaceCorps extends Card:
	
	func _init() -> void:
		self.id = 0
		self.name = "Миротворцы"
		self.ops = 2
		self.desc = "Уберите 1 влияние СССР из не-советской страны.
		 Добавьте 1 влияние США в 2 американские страны" 
		self.bloc = Bloc.USA
		self.period = Period.MID
		mid_war_deck.append(self)
		
	@rpc("any_peer", "call_local")
	func event() -> void:
		var map_filter = MapFilter.new()
		map_filter.need_control_ussr = true
		map_filter.reverse = true
		emit_signal("choose_a_country", map_filter, remove_one_from_non_soviet)
	
	func remove_one_from_non_soviet(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_soviet.rpc(chosen_id, -1, true)
		var map_filter = MapFilter.new()
		map_filter.need_control_usa = true
		map.disable_countries()
		emit_signal("choose_a_country", map_filter, add_one_to_american)
		
	var repeat = 2
	
	func add_one_to_american(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_usa.rpc(chosen_id, 1, true)
			var map_filter = MapFilter.new()
			map_filter.need_control_usa = true
			map_filter.ban.append(chosen_id)
			map.disable_countries()
			repeat -= 1
			if repeat == 0:
				repeat = 1
				map.disable_countries()
				confirm_button.disabled = false
			else:
				emit_signal("choose_a_country", map_filter, add_one_to_american)
		else:
			repeat = 1
			map.disable_countries()
			confirm_button.disabled = false




class OgadenWar extends Card:
	
	func _init() -> void:
		self.id = 1
		self.name = "Огаденская война"
		self.ops = 2
		self.desc = "Киньте d6, -1 за каждую соседнюю советскую страну
		 с Эфиопией. 5-6: +2 ПО США, замените влияние советов на американское
		 в Эфиопии\nНельзя играть после 'F-5E доставлены'" 
		self.bloc = Bloc.USA
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		if not map.game.F56:
			map.roll_d6.rpc(0)
			var roll = map.last_roll
			if roll + map.map_node.neg_modifier(2, Bloc.USA) > 4:
				map.game.move_VP.rpc(2)
				map.set_inf_usa.rpc(2, map.map[id].inf_soviet, true)
				map.set_inf_soviet.rpc(2, 0)
		confirm_button.disabled = false

const Sequence = preload("res://scripts/game.gd").Sequence

class USAID extends Card:
	
	func _init() -> void:
		self.id = 2
		self.name = "USAID"
		self.ops = 2
		self.desc = "США делают 1 ОО. Если сыграно в заголовке, то в этом
		 ходу США ходят первыми" 
		self.bloc = Bloc.USA
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		if map.game.sequence == Sequence.HEADLINE:
			print ("usaid proc 0/3")
			map.game.USAID.rpc()
		map.game.play_a_card(1)
		
		

class VictoriousLeader extends Card:
	
	func _init() -> void:
		self.id = 3
		self.name = "Лидер-победитель"
		self.ops = 3
		self.desc = "+4 влияния США в страны, соседние с советскими странами на
		 начало раунда действий (не более 2 в одну страну)" 
		self.bloc = Bloc.USA
		self.asterisk = true
		self.period = Period.MID
	
	var repeat = 3
	var eligible = MapFilter.new()
	var added_to = Array()
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		eligible.allow = map.victorious_leader()
		emit_signal("choose_a_country", eligible, add_usa_influence)
	
	func add_usa_influence(chosen_id : int):
		if chosen_id != -1 and repeat > 0:
			if added_to.has(chosen_id):
				eligible.ban.append(chosen_id)
			else:
				added_to.append(chosen_id)
			map.set_inf_usa.rpc(chosen_id, 1, true)
			repeat -= 1
			emit_signal("choose_a_country", eligible, add_usa_influence)
		else:
			added_to.clear()
			eligible.allow.clear()
			eligible.ban.clear()
			repeat = 3
			map.disable_countries()
			confirm_button.disabled = false


class EritreanPopularLiberationFront extends Card:
	
	func _init() -> void:
		self.id = 4
		self.name = "Народный фронт освобождения Эритреи"
		self.ops = 1
		self.desc = "Если Эфиопия контролируется СССР, добавьте 1
		 влияния туда и в соседнюю страну, +1 ПО" 
		self.bloc = Bloc.USA
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		if map.map[2].sov_control():
			var adj_to_ethiopia = MapFilter.new()
			adj_to_ethiopia.allow.append_array(map.map[2].adjacent)
			map.set_inf_usa.rpc(2, 1, true)
			map.game.move_VP.rpc(1)
			emit_signal("choose_a_country", adj_to_ethiopia, add_usa_influence)
			
		else:
			confirm_button.disabled = false
	
	func add_usa_influence(chosen_id : int):
		map.set_inf_usa.rpc(chosen_id, 1, true)
		map.disable_countries()
		confirm_button.disabled = false


class FrenchConnections extends Card:
	
	func _init() -> void:
		self.id = 5
		self.name = "Французские связи"
		self.ops = 2
		self.desc = "Уберите все влияние СССР из Джибути или
		 Мадагаскара и добавьте туда 2 влияния" 
		self.bloc = Bloc.USA
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map_filter.allow.append(3)
		map_filter.allow.append(6)
		emit_signal("choose_a_country", map_filter, delete_sov_plus_two_usa)
		
	func delete_sov_plus_two_usa(chosen_id: int):
		map.set_inf_soviet.rpc(chosen_id, 0)
		map.set_inf_usa.rpc(chosen_id, 2, true)
		map.disable_countries()
		confirm_button.disabled = false

class HeroOfTheCrossing extends Card:
	
	func _init() -> void:
		self.id = 6
		self.name = "Герой пролива"
		self.ops = 3
		self.desc = "Сбросьте с руки карту с советским событием. Заберите
		 из сброса карту с американским или нейтральным событием" 
		self.bloc = Bloc.USA
		self.period = Period.MID
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.mark_soviet_in_hand()
		await map.game.response
		confirm_button.disabled = false
		

class IsraeliPeripheryDoctrine extends Card:
	
	func _init() -> void:
		self.id = 7
		self.name = "Доктрина израильской периферии"
		self.ops = 2
		self.desc = "США совершает 2 попытки снижения влияния в Африке
		 с модификатором +1" 
		self.bloc = Bloc.USA
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TEST
		print(self.name + " event")
		map.game.realign_modifier = 1
		map.game.ops_left = 0
		var map_filter = MapFilter.new()
		map_filter.region = Region.AFR
		map_filter.need_presence_ussr = true
		emit_signal("choose_a_country", map_filter, map.game.realign_roll)
		confirm_button.disabled = true
		
		await map.game.response
		emit_signal("choose_a_country", map_filter, map.game.realign_roll)
		
		map.game.realign_modifier = 0
		
		

class TheStrongManOfSudan extends Card:
	
	func _init() -> void:
		self.id = 8
		self.name = "Сильный человек Судана"
		self.ops = 1
		self.desc = "США добавляет в Судан столько же влияния, сколько
		 советского влияния в Эфиопии плюс один" 
		self.bloc = Bloc.USA
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.set_inf_usa.rpc(1, map.map[2].inf_soviet + 1, true)
		confirm_button.disabled = false

class DiegoGarcia extends Card:
	
	func _init() -> void:
		self.id = 9
		self.name = "Диего-Гарсия"
		self.ops = 2
		self.desc = "+2 влияния США, -1 влияние СССР из Стратегических
		 Морских Путей" 
		self.bloc = Bloc.USA
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.set_inf_usa.rpc(11, 2, true)
		map.set_inf_soviet.rpc(11, -1, true)
		confirm_button.disabled = false


# ============================ USSR Mid War ==============================

class SovietsAirliftCubans extends Card:
	
	func _init() -> void:
		self.id = 10
		self.name = "Воздушные перевозки кубинцев"
		self.ops = 3
		self.desc = "Уберите все влияние США из одной африканской страны" 
		self.bloc = Bloc.USSR
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map_filter.region = Region.AFR
		emit_signal("choose_a_country", map_filter, remove_all_americans)
	
	func remove_all_americans(chosen_id : int) -> void:
		if chosen_id != -1:
			map.set_inf_usa.rpc(chosen_id, 0)
		map.disable_countries()
		confirm_button.disabled = false


class Detente extends Card:
	
	func _init() -> void:
		self.id = 11
		self.name = "Detente"
		self.ops = 1
		self.desc = "+2 военные операции СССР, -2 военные операции США. Заберите
		 карту Румынской автономии себе лицом вверх, если она у игрока за США" 
		self.bloc = Bloc.USSR
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.move_MO.rpc(0, -2)
		map.game.move_MO.rpc(1, 2)
		
		if not map.game.has_romania:
			# Opponent loses romania
			map.game.lose_romania.rpc()
			# Get Romania
			map.game.get_romania()
		
		
		confirm_button.disabled = false

class LionFalters extends Card:
	
	func _init() -> void:
		self.id = 12
		self.name = "Лев колеблется"
		self.ops = 2
		self.desc = "Если Эфиопия советская, +2 ПО. Иначе уберите все
		 влияние США из Эфиопии и добавьте 1 влияния СССР" 
		self.bloc = Bloc.USSR
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		if map.map[2].sov_control():
			map.game.move_VP.rpc(-2)
		else:
			map.set_inf_usa.rpc(2, 0)
			map.set_inf_soviet.rpc(2, 1, true)
		confirm_button.disabled = false
		
class DhofarRebellion extends Card:
	
	func _init() -> void:
		self.id = 13
		self.name = "Дхофарское восстание"
		self.ops = 2
		self.desc = "Если СССР контролирует Южный Йемен, +1 влияние в Оман и
		 в любую ближневосточную страну" 
		self.bloc = Bloc.USSR
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		if map.map[8].sov_control():
			map.set_inf_soviet.rpc(10, 1, true)
			var map_filter = MapFilter.new()
			map_filter.region = Region.ME
			emit_signal("choose_a_country", map_filter, add_one_soviet)
		else:
			confirm_button.disabled = false
	
	func add_one_soviet(chosen_id: int):
		map.set_inf_soviet.rpc(chosen_id, 1, true)
		map.disable_countries()
		confirm_button.disabled = false

class Nasserism extends Card:
	
	func _init() -> void:
		self.id = 14
		self.name = "Насеризм"
		self.ops = 1
		self.desc = "До конца хода попытки переворота СССР получают
		 модификатор +1" 
		self.bloc = Bloc.USSR
		self.asterisk = true;
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.nasserism.rpc()
		confirm_button.disabled = false

class TheDerg extends Card:
	
	func _init() -> void:
		self.id = 15
		self.name = "ВВАС"
		self.ops = 2
		self.desc = "+2 влияния СССР в Эфиопию. Если она контролируется СССР,
		ее стабильность становится 3 до конца игры" 
		self.bloc = Bloc.USSR
		self.asterisk = true;
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.set_inf_soviet.rpc(2, 2, true)
		if map.map[2].sov_control():
			map.derg.rpc()
			map.set_inf_soviet.rpc(2, 0, true)
			map.game.derg.rpc()
		confirm_button.disabled = false
		
class USElections extends Card:
	
	func _init() -> void:
		self.id = 16
		self.name = "Выборы президента США"
		self.ops = 1
		self.desc = "Может быть сыграно СССР в заголовке, чтобы отменить сыгранное событие США" 
		self.bloc = Bloc.USSR
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		# Because of how event are implemented, it basically only does shit
		# if we put it into "game.gd". It's awful, but whatever
		
		confirm_button.disabled = false
		

class F5EDelivered extends Card:
	
	func _init() -> void:
		self.id = 17
		self.name = "Доставка F-5E"
		self.ops = 3
		self.desc = "СССР может совершить попытку снижения влияния на каждую страну в Африке\n
		Отменяет эффект карты 'Огаденская война'" 
		self.bloc = Bloc.USSR
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.F56_active.rpc()
		var map_filter = MapFilter.new()
		map_filter.need_presence_usa = true
		map_filter.region = Region.AFR
		map.game.last_choice_id = 0
		
		while map.game.last_choice_id != -1:
			print(map.game.last_choice_id)
			emit_signal("choose_a_country", map_filter, map.game.realign_roll)
			confirm_button.disabled = true
			if map.game.last_choice_id == -1:
				break
			await map.game.response
			map_filter.ban.append(map.game.last_choice_id)
		confirm_button.disabled = false
		

class CyrusVance extends Card:
	
	func _init() -> void:
		self.id = 18
		self.name = "Сайрус Вэнс"
		self.ops = 2
		self.desc = "Вытяните 2 случайные карты с руки США. Сбросьте любую на выбор, другую
		 верните. Если сброшенная карта - событие СССР, +2 ПО" 
		self.bloc = Bloc.USSR
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		map.game.request_two_random_cards.rpc()
		await map.game.response
		confirm_button.disabled = false
		

class MalagasyConstitutionalReferendum extends Card:
	
	func _init() -> void:
		self.id = 19
		self.name = "Малагазийский Конституционный Референдум"
		self.ops = 2
		self.desc = "Уберите 1 влияние США из Мадагаскара, добавьте столько влияния в Мадагаскар,
		 сколько нужно для контроля" 
		self.bloc = Bloc.USSR
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.set_inf_usa.rpc(6, -1, true)
		var need_for_control = map.map[6].inf_usa + map.map[6].stability
		if need_for_control > map.map[6].inf_soviet:
			map.set_inf_soviet.rpc(6, need_for_control)
		confirm_button.disabled = false

class YemeniPresidentialAssassinations extends Card:
	
	func _init() -> void:
		self.id = 20
		self.name = "Убийство президента Йемена"
		self.ops = 2
		self.desc = "Снизьте DEFCON на 1. Киньте куб, +1 за каждую советскую страну на Ближнем
		 Востоке. 4-6: добавьте столько влияния в Йемен, сколько надо для контроля" 
		self.bloc = Bloc.USSR
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.move_defcon.rpc(-1)
		var mod = 0
		for country in map.map:
			if (country.region == Region.ME or country.region == Region.EGY) and country.sov_control():
				mod += 1
		map.roll_d6.rpc(1)
		if map.last_roll + mod > 3:
			var need_for_control = map.map[9].inf_usa + map.map[9].stability
			if need_for_control > map.map[9].inf_soviet:
				map.set_inf_soviet.rpc(9, need_for_control)
		confirm_button.disabled = false


# ============================ NEUTRAL Mid War ==============================

class AfricaScoring extends Card:
	
	func _init() -> void:
		self.id = 21
		self.name = "! Подсчет Африки !"
		self.ops = 0
		self.desc = "Подсчитайте Африку" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.move_VP.rpc(map.score_region(Region.AFR))
		confirm_button.disabled = false

class RomanianAutonomy extends Card:
	
	func _init() -> void:
		self.id = 22
		self.name = "Румынская Автономия"
		self.ops = 2
		self.desc = "+1 ОО, если вы отстаете по ПО. +1 ПО в конце игры" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")

class Famine extends Card:
	
	func _init() -> void:
		self.id = 23
		self.name = "Голод"
		self.ops = 2
		self.desc = "Разместите по жетону Голода в 2 соседних странах. Совершите переворот в
		 одной из них. Жетоны Голода добавляют +1 к переворотам и убираются после успешного
		 переворота" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		only_adjacent = MapFilter.new()
		only_adjacent.ban.append(11)
		first_time = true
		emit_signal("choose_a_country", only_adjacent, place_famine)
	
	var only_adjacent: MapFilter
	var first_time : bool
	
	func place_famine(chosen_id : int):
		map.place_famine.rpc(chosen_id)
		if first_time:
			first_time = false
			only_adjacent.allow.append_array(map.map[chosen_id].adjacent)
			map.disable_countries()
			emit_signal("choose_a_country", only_adjacent, place_famine)
		else:
			map.disable_countries()
			confirm_button.disabled = false
	

class Separatists extends Card:
	
	func _init() -> void:
		self.id = 24
		self.name = "Сепаратисты"
		self.ops = 2
		self.desc = "Сравняйте свое влияние с влиянием противника в любой не-ключевой стране" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map_filter.need_battleground = true
		map_filter.reverse = true
		emit_signal("choose_a_country", map_filter, equalize)
	
	func equalize(chosen_id : int):
		var phasing = map.game.player_country
		if phasing == Phase.USA:
			map.set_inf_usa.rpc(chosen_id, map.map[chosen_id].inf_soviet)
		elif phasing == Phase.USSR:
			map.set_inf_soviet.rpc(chosen_id, map.map[chosen_id].inf_usa)
		map.disable_countries()
		confirm_button.disabled = false

class ArabLeague extends Card:
	
	func _init() -> void:
		self.id = 25
		self.name = "Арабская Лига"
		self.ops = 2
		self.desc = "+3 ПО, если контролируете хотя бы 3 из следующих стран:\n
		Египет, Судан, Ю. Йемен, Йемен, Оман, Саудовская Аравия" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var controlled = 0
		var phasing = map.game.player_country
		if phasing == Phase.USA:
			if map.map[1].usa_control():
				controlled += 1
			for country in map.map:
				if (country.region == Region.ME or country.region == Region.EGY) and country.usa_control():
					controlled += 1
			if controlled >= 3:
				map.game.move_VP.rpc(3)
		elif phasing == Phase.USSR:
			if map.map[1].sov_control():
				controlled += 1
			for country in map.map:
				if (country.region == Region.ME or country.region == Region.EGY) and country.sov_control():
					controlled += 1
			if controlled >= 3:
				map.game.move_VP.rpc(-3)
		confirm_button.disabled = false

class ApolloSoyuzTestProject extends Card:
	
	func _init() -> void:
		self.id = 26
		self.name = "Проект 'Апполон'/'Союз'"
		self.ops = 2
		self.desc = "Продвиньтесь на 1 деление в Космической Гонке" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var phasing = map.game.player_country
		if phasing == Phase.USA:
			map.game.move_space_race.rpc(0)
		elif phasing == Phase.USSR:
			map.game.move_space_race.rpc(1)
		confirm_button.disabled = false
		

class IndianOceanZoneOfPeace extends Card:
	
	func _init() -> void:
		self.id = 27
		self.name = "'Зона мира' Индийского океана"
		self.ops = 2
		self.desc = "До конца хода все страны считаются ключевыми для
		 переворотов" 
		self.bloc = Bloc.NEUTRAL
		self.asterisk = true
		self.period = Period.MID
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.get_parent().zone_of_peace.rpc()
		confirm_button.disabled = false
		

class WaterWars extends Card:
	
	func _init() -> void:
		self.id = 28
		self.name = "Морские войны"
		self.ops = 2
		self.desc = "Если противник контролирует Египет и Эфиопию, удалите
		все его влияние из страны, в котором его больше" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.MID
	
	var phasing : Phase
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		phasing = map.game.player_country
		if phasing == Phase.USA:
			if map.map[0].sov_control() and map.map[2].sov_control():
				if map.map[0].inf_soviet > map.map[2].inf_soviet:
					remove_all_opponent(0)
				elif map.map[0].inf_soviet < map.map[2].inf_soviet:
					remove_all_opponent(2)
				else:
					var egypt_ethiopia = MapFilter.new()
					egypt_ethiopia.allow.append(0)
					egypt_ethiopia.allow.append(2)
					emit_signal("choose_a_country", egypt_ethiopia, remove_all_opponent)
			else:
				confirm_button.disabled = false
		elif phasing == Phase.USSR:
			if map.map[0].usa_control() and map.map[2].usa_control():
				if map.map[0].inf_usa > map.map[2].inf_usa:
					remove_all_opponent(0)
				elif map.map[0].inf_usa < map.map[2].inf_usa:
					remove_all_opponent(2)
				else:
					var egypt_ethiopia = MapFilter.new()
					egypt_ethiopia.allow.append(0)
					egypt_ethiopia.allow.append(2)
					emit_signal("choose_a_country", egypt_ethiopia, remove_all_opponent)
			else:
				confirm_button.disabled = false
	
	func remove_all_opponent(chosen_id: int):
		if phasing == Phase.USA:
			map.set_inf_soviet.rpc(chosen_id, 0)
		elif phasing == Phase.USSR:
			map.set_inf_usa.rpc(chosen_id, 0)
		confirm_button.disabled = false


#=========================================================================
#								LATE WAR
#								 USA
#=========================================================================

class Zbig extends Card:
	
	func _init() -> void:
		self.id = 29
		self.name = "Збиг"
		self.ops = 3
		self.desc = "Совершите переворот, используя ОО этой карты. DEFCON не
		 ограничивает этот переворот и не изменяется из-за него" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TEST
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map_filter.ban.append(11)
		map_filter.need_presence_ussr = true
		map.game.zbig = true
		emit_signal("choose_a_country", map_filter, map.game.usa_coup)
		await map.game.response
		confirm_button.disabled = false

class AlbanoStalinistEconomics extends Card:
	
	func _init() -> void:
		self.id = 30
		self.name = "Албано-Сталинская экономика"
		self.ops = 2
		self.desc = "До конца хода карты СССР, потраченные на размещение влияния
		 в Африке, получают -1 ОО (минимум 1 ОО)" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class CENTCOM extends Card:
	
	func _init() -> void:
		self.id = 31
		self.name = "CENTCOM"
		self.ops = 3
		self.desc = "Разместите жетон CENTCOM рядом с любой страной. СССР не
		 может проводить перевороты и попытки снижения влияния в этой стране" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
		
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class CarterDoctrine extends Card:
	
	func _init() -> void:
		self.id = 32
		self.name = "Доктрина Картера"
		self.ops = 4
		self.desc = "Раз за этот ход США перед любым броском кубика может
		 сделать результат равным '1' или '6'" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class KenyaJoinsRDF extends Card:
	
	func _init() -> void:
		self.id = 33
		self.name = "Кения присоединяется к RDF"
		self.ops = 1
		self.desc = "Добавьте 1 влияние США в Кению. Уберите 1 влияние СССР из
		 любой не-советской страны" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map.set_inf_usa.rpc(5, 1, true)
		map_filter.need_control_ussr = true
		map_filter.reverse = true
		emit_signal("choose_a_country", map_filter, remove_one_from_non_soviet)
	
	func remove_one_from_non_soviet(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_soviet.rpc(chosen_id, -1, true)
		map.disable_countries()
		confirm_button.disabled = false
		
		

class VoiceOfAmericaAmharic extends Card:
	
	func _init() -> void:
		self.id = 34
		self.name = "'Голос Америки' на амхарском"
		self.ops = 2
		self.desc = "США совершают 1 ОО. До конца хода американские карты с 1 ОО
		 получают +1 ОО" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class EventsOf86 extends Card:
	
	func _init() -> void:
		self.id = 35
		self.name = "События 1986 года"
		self.ops = 2
		self.desc = "+1 ПО США, если СССР контролирует Ю. Йемен. Затем, уберите
		 с Ближнего Востока столько советского влияния, сколько американских стран
		 в этом регионе" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
	
	var times = 0
	var map_filter : MapFilter
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		times = 0
		map_filter = MapFilter.new()
		map_filter.need_control_ussr = true
		map_filter.region = Region.ME
		if map.map[8].sov_control():
			map.game.move_VP.rpc(1)
		for country in map.map:
			if country.usa_control() and country.id != 11:
				times += 1
		emit_signal("choose_a_country", map_filter, remove_one_soviet)
	
	func remove_one_soviet(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_soviet.rpc(chosen_id, -1, true)		
		times -= 1
		if times <= 0 or chosen_id == -1:
			map.disable_countries()
			confirm_button.disabled = false
		else:
			emit_signal("choose_a_country", map_filter, remove_one_soviet)
		

class AfghanistanInvaded extends Card:
	
	func _init() -> void:
		self.id = 36
		self.name = "Вторжение в Афганистан"
		self.ops = 4
		self.desc = "-1 ОО картам СССР до конца хода. 'Президентская Директива 30'
		 не играбельна/не действует" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		# TODO
		print(self.name + " event")
		
		

class DanielArapMoi extends Card:
	
	func _init() -> void:
		self.id = 37
		self.name = "Дэниэл арап Мои"
		self.ops = 2
		self.desc = "Если США контролируют Кению, +1 ПО и снизьте или повысьте
		 DEFCON на 1. Иначе, +2 влияния США в Кению" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		
		if map.map[5].usa_control():
			#TODO
			pass
		else:
			map.set_inf_usa.rpc(5, 2, true)
			confirm_button.disabled = false

class WeAreTheWorld extends Card:
	
	func _init() -> void:
		self.id = 38
		self.name = "Мы - это мир!"
		self.ops = 1
		self.desc = "Если есть страны с маркером голода, +1 ПО, добавьте 2 влияния
		 в страну с голодом и уберите маркер голода" 
		self.bloc = Bloc.USA
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map_filter.in_famine = true
		emit_signal("choose_a_country", map_filter, unstarve)
	
	func unstarve(chosen_id : int):
		if chosen_id != -1:
			map.game.move_VP.rpc(1)
			map.remove_famine.rpc(chosen_id)
			map.set_inf_usa.rpc(chosen_id, 2, true)		
		map.disable_countries()
		confirm_button.disabled = false
		

#=========================================================================
#								LATE WAR
#								 USSR
#=========================================================================

class T62Kalashnikovs extends Card:
	
	func _init() -> void:
		self.id = 39
		self.name = "Т-62 и Калашниковы"
		self.ops = 3
		self.desc = "+1 ОО всем картам СССР (не больше 3) до конца хода" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class GosplanAdvisers extends Card:
	
	func _init() -> void:
		self.id = 40
		self.name = "Советники Госплана"
		self.ops = 2
		self.desc = "СССР тянет 2 карты и скидывает 2 карты" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class MengistuHaileMariam extends Card:
	
	func _init() -> void:
		self.id = 41
		self.name = "Менгисту Хайле Мариам"
		self.ops = 3
		self.desc = "СССР может сыграть событие США с руки, как если бы оно было
		 советским (все упоминания США заменяются на СССР и наоборот)" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO HOLY SHIT THIS IS GONNA BE HARD
		print(self.name + " event")

class MarxistLeninistVanguardParties extends Card:
	
	func _init() -> void:
		self.id = 42
		self.name = "Марксисто-Ленинистские партии"
		self.ops = 2
		self.desc = "СССР может переместить до 3 своих очков влияния из одной страны в
		 любые другие страны (не более 2 на страну)" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")
		

class PresidentialDirective30 extends Card:
	
	func _init() -> void:
		self.id = 43
		self.name = "Президентская директива 30"
		self.ops = 2
		self.desc = "+1 влияние СССР в любую страну. СССР может сыграть 8 раундов
		 действий в этом ходу" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var map_filter = MapFilter.new()
		map_filter.ban.append(11)
		emit_signal("choose_a_country", map_filter, one_soviet)
		# TODO 8th round for USSR
	
	func one_soviet(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_soviet.rpc(chosen_id, 1, true)
		map.disable_countries()
		confirm_button.disabled = false
		
		

class Stagflation extends Card:
	
	func _init() -> void:
		self.id = 44
		self.name = "Стагфляция"
		self.ops = 2
		self.desc = "США открывает все свои карты подсчета. СССР играет ОО этой
		 карты. Если США открыли хотя бы один подсчет, они обязаны сыграть его
		 в следующий свой раунд действий" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")

class CENTOcollapses extends Card:
	
	func _init() -> void:
		self.id = 45
		self.name = "Раскол CENTO"
		self.ops = 1
		self.desc = "Уберите 2 влияния США из Ближнего Востока" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
		self.asterisk = true
	
	var times = 0
	var map_filter : MapFilter
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map_filter = MapFilter.new()
		map_filter.region = Region.ME
		map_filter.need_presence_usa = true
		times = 2
		emit_signal("choose_a_country", map_filter, remove_one_usa)
		
	func remove_one_usa(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_usa.rpc(chosen_id, -1, true)
		times -= 1
		if times <= 0 or chosen_id == -1:
			map.disable_countries()
			confirm_button.disabled = false
		else:
			emit_signal("choose_a_country", map_filter, remove_one_usa)
		
class AntiZionistCommiteeOfSovietPublic extends Card:
	
	func _init() -> void:
		self.id = 46
		self.name = "Анти-зионистский народный совет"
		self.ops = 2
		self.desc = "Совершите 2 попытки снижения влияния на Ближнем Востоке
		 с модификатором +1" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
		self.asterisk = true
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TEST
		print(self.name + " event")
		map.game.realign_modifier = 1
		map.game.ops_left = 0
		var map_filter = MapFilter.new()
		map_filter.region = Region.ME
		map_filter.need_presence_usa = true
		emit_signal("choose_a_country", map_filter, map.game.realign_roll)
		confirm_button.disabled = true
		
		await map.game.response
		emit_signal("choose_a_country", map_filter, map.game.realign_roll)
		
		map.game.realign_modifier = 0
		
class MrNyet extends Card:
	
	func _init() -> void:
		self.id = 47
		self.name = "Мистер Нет"
		self.ops = 4
		self.desc = "-1 DEFCON. Уберите все влияние США из 2 любых стран, где у
		 СССР есть влияние. Не более 1 страны на регион" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
		self.asterisk = true

	var map_filter : MapFilter
	var times : int
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		times = 2
		map_filter = MapFilter.new()
		map_filter.need_presence_ussr = true
		map_filter.region = Region.ME
		map_filter.ban.append(11)		
		
		map.game.move_defcon.rpc(-1)
		emit_signal("choose_a_country", map_filter, remove_all_american)
	
	func remove_all_american(chosen_id : int):
		if chosen_id != -1:
			map.set_inf_usa.rpc(chosen_id, 0)
		times -= 1
		if times == 1:
			map_filter.region = Region.AFR
			map_filter.ban.append(0)
			map.disable_countries()
			emit_signal("choose_a_country", map_filter, remove_all_american)
		else:
			map.disable_countries()
			confirm_button.disabled = false
		
		

class Seychelles extends Card:
	
	func _init() -> void:
		self.id = 48
		self.name = "Сейчеллес"
		self.ops = 2
		self.desc = "+1 влияние СССР в Стратегических Морских Путях за каждую
		 страну на Ближнем Востоке без влияния США" 
		self.bloc = Bloc.USSR
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		var total = 0
		for country in map.map:
			if country.inf_usa <= 0:
				total += 1
		map.set_inf_soviet.rpc(11, total, true)
		confirm_button.disabled = false
		

#=========================================================================
#								LATE WAR
#								 NEUTRAL
#=========================================================================

class MiddleEastScoring extends Card:
	
	func _init() -> void:
		self.id = 49
		self.name = "! Ближний Восток !"
		self.ops = 0
		self.desc = "Подсчитайте Ближний Восток" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		print(self.name + " event")
		map.game.move_VP.rpc(map.score_region(Region.ME))
		confirm_button.disabled = false

class OAU extends Card:
	
	func _init() -> void:
		self.id = 50
		self.name = "Организация Африканского Единства"
		self.ops = 1
		self.desc = "Сбросьте карту с событием противника и киньте d6. 4-6: совершите
		 ОО со сброшенной карты" 
		self.bloc = Bloc.NEUTRAL
		self.period = Period.LATE
	
	@rpc("any_peer", "call_local")
	func event() -> void:
		#TODO
		print(self.name + " event")
