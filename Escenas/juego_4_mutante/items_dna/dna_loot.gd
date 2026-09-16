extends Node
#dna loot

const DNA_1 = preload("uid://cgbfvlvfohxr7")
const DNA_2 = preload("uid://dhsvp22tuv0hs")
const DNA_3 = preload("uid://dyv7bjge155ni")
const DNA_4 = preload("uid://dme67xheoeoeo")
const DNA_5 = preload("uid://bdfta00qn381m")


const DNA_POOL: Array[ItemData] = [DNA_1, DNA_2, DNA_3, DNA_4, DNA_5]
const MAX_DNA_PER_SPAWN: int = 5

# Devuelve un array de ItemData de DNA según el nivel.
# A mayor nivel, más DNA (máximo 5).
func get_dna_loot(level: int) -> Array[ItemData]:
	var loot: Array[ItemData] = []
	if level <= 0:
		return loot

	var amount: int = clampi(1 + int(level / 2.0), 1, MAX_DNA_PER_SPAWN)
	var max_index: int = clampi(level, 1, DNA_POOL.size())
	var available_pool: Array[ItemData] = DNA_POOL.slice(0, max_index)

	for i in amount:
		loot.append(available_pool.pick_random())

	return loot
