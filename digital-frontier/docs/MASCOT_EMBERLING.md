# Emberling — Digital Frontier Mascot

## Identity

| | |
|--|--|
| **Species** | Emberling |
| **Line** | Emberling → Emberaptor → Emberion |
| **Role** | Starter partner / handheld mascot |
| **Look** | Small orange bipedal dinosaur, big eyes, long tail |

### Stage names

1. **Emberling** — tiny, round, endlessly curious  
2. **Emberaptor** — taller, braver, sharper presence  
3. **Emberion** — guardian form; still clearly *your* Emberling  

### Personality

Playful · Curious · Affectionate · Brave when protecting you  

**Likes:** sunny parks, treasure hunts, belly rubs, chasing leaves, sharing snacks  
**Dislikes:** loneliness, cold rain alone, being ignored, empty bowls  

### Backstory

Emberlings hatch from warm sunrise code in the Digital Frontier — a spark that grew scales and a heartbeat the moment an adventurer needed a friend. They are not wild beasts; they are living companions woven for small screens and big feelings.

## Systems

- Species data: `data/creatures/emberling.tres`
- Visual profile: `emberling` in `CompanionVisual`
- Care / XP / friendship: existing `CreatureManager` + `CreatureInstance`
- Evolution: `CreatureManager.try_evolve()` using level + friendship thresholds
- Adventure: follow + Secret Sense (`sense_secrets`)

## Handheld design

Clear orange silhouette, oversized eyes, readable moods without text spam.
