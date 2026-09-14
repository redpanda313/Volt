extends RefCounted
class_name Powerup

## Beat 9 drone cargo. Seven kinds. Durations are the playtest contract (PLAYTEST.md).
## Health is instant. The rest refresh if the same kind is collected again.

enum Kind { SHIELD, HEALTH, STEALTH, OVERCHARGE, MAGNET, SLOW, SCORE }

const COUNT := 7
const IDS: Array[String] = [
	"shield",
	"health",
	"stealth",
	"overcharge",
	"magnet",
	"slow",
	"score",
]
const TITLES: Array[String] = [
	"SHIELD",
	"HEALTH",
	"STEALTH",
	"OVERCHARGE",
	"MAGNET",
	"SLOW",
	"SCORE ×2",
]
const SECS: Array[float] = [5.5, 0.0, 5.0, 6.0, 8.0, 5.5, 8.0]
const SLOW_PACE := 0.42
const SCORE_POWER := 2.0


static func id_of(kind: Kind) -> String:
	return IDS[int(kind)]


static func title(kind: Kind) -> String:
	return TITLES[int(kind)]


static func duration(kind: Kind) -> float:
	return SECS[int(kind)]


static func is_timed(kind: Kind) -> bool:
	return duration(kind) > 0.0


static func tint(kind: Kind) -> Color:
	match kind:
		Kind.SHIELD:
			return Color(0.38, 0.86, 1.0)
		Kind.HEALTH:
			return Color(0.95, 0.28, 0.38)
		Kind.STEALTH:
			return Color(0.62, 0.42, 0.95)
		Kind.OVERCHARGE:
			return Color(1.0, 0.82, 0.28)
		Kind.MAGNET:
			return Color(0.95, 0.42, 0.55)
		Kind.SLOW:
			return Color(0.40, 0.62, 1.0)
		Kind.SCORE:
			return Color(1.0, 0.86, 0.28)
	return Color(0.8, 0.9, 1.0)


static func toast(kind: Kind, extra: String = "") -> String:
	if extra != "":
		return extra
	return title(kind)
