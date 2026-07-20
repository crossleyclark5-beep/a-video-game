# Creature Companion Foundation

Digital Frontier companions are living friends — data-driven instances with personality, needs, growth, and modular presentation.

## Architecture

```
CreatureData (.tres)          species template (stats, personality, skins, colors)
        │
        ▼
CreatureInstance              runtime owned creature (needs, XP, skin, evolution)
        │
        ▼
CreatureManager (autoload)    owns active instance + collection dict
        │
   ┌────┴────┐
   ▼         ▼
Home Actor   Adventure hooks (grant_adventure_experience)
```

| Module | Path |
|--------|------|
| Species template | `resources/definitions/creature_data.gd` |
| Runtime instance | `scripts/creatures/creature_instance.gd` |
| Ownership / care | `scripts/autoload/creature_manager.gd` |
| Visual + anims | `scripts/home/companion_visual.gd` |
| Home AI | `scripts/home/companion_actor.gd` |

Starter species: **Sparkbit** (`data/creatures/sparkbit.tres`) — digital fantasy spirit, not a realistic animal.

## Tracked instance fields

- Name / species / instance id
- Level + experience
- Hunger, happiness, energy, friendship, health
- Stats (hp / attack / defense / speed)
- Skin id + unlocked skins
- Evolution stage
- Personality axes: playful, curious, affectionate, lazy, brave

Nothing gameplay-critical is hardcoded on the actor mesh.

## Animations (CompanionVisual.Anim)

| Anim | Use |
|------|-----|
| IDLE | Breathing, look-around |
| WALK | Home locomotion |
| SLEEP | Bed / low energy |
| EAT | Food bowl |
| HAPPY | Play / excited |
| SAD | Low mood |
| HUNGRY | Searching / waiting near food |
| STRETCH | Wake |
| PET | Player pet reaction |

Add new enum values + match branches — the actor only calls `set_anim`.

## AI behavior

Driven by `CreatureInstance.get_behavior_bias()` + personality:

- High happiness / playful → more wander + toy visits
- Low happiness → sleep more, move slower
- Hungry → walk to bowl, hungry sniff anim
- Click creature or Pet button → pet reaction + heart burst + SFX event

## Player interactions

| Action | Effect |
|--------|--------|
| Pet | Happiness + friendship + XP; pet anim + particles |
| Feed | Hunger restore + XP |
| Play | Happiness; energy cost |
| Rest | Energy restore |
| Train | Friendship + XP (growth feel) |
| Status | Detailed readout; creature faces / acknowledges |
| Click body | Same as Pet |

## Persistence (home ↔ adventure)

`CreatureManager.export_state()` saves the full `captured` instance map + active id.
Adventure calls `grant_adventure_experience()` so the same friend grows outdoors.
Returning home loads the same needs / level / personality.

## Future hooks (ready, not built)

- Multiple creatures in `_captured` / `_party`
- Trading (serialize `CreatureInstance.to_dict()`)
- Collection UI (count already exposed)
- Evolution (`evolution_stage` + `evolution_chain_id` on species)
- Skins (`skin_id` / `available_skin_ids` / visual profile id)
