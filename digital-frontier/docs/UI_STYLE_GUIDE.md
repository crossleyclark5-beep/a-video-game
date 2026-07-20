# Digital Frontier UI Style Guide

## Brand feeling

Early-2000s digi-device energy: **fun, bright, adventurous** — like opening a Field Unit from another world.

Inspired by Digimon-era devices, Nintendo handheld menus, and colorful adventure games — **not** corporate app chrome or plain white prototypes.

## Palette (`WorldPalette`)

| Token | Role |
|-------|------|
| `UI_NAVY` | Device shell / sheet body |
| `UI_CYAN` | Digital LCD accent, map frame, titles |
| `UI_ACCENT` | Orange CTAs / focus / Adventure |
| `UI_LIME` | Success / ready |
| `UI_PURPLE` | Quests / secondary tabs |
| `UI_GOLD` | Bits / rewards |
| `UI_PAPER` / `UI_INK` | Top bars, readable labels |
| `UI_SHEET` / `UI_SHEET_TEXT` | Modal sheet body |

## Shared code

- **`DFStyle`** — StyleBox factories, label/button/progress apply helpers, slide/pulse motion
- **`DFFormat`** — BBCode card sheets for Pack / Quests / Collection / Bits / Map
- **`DeviceSettings`** — Select opens themed settings (volume, haptics, LED, legend)

## Screens

| Screen | Look |
|--------|------|
| Boot | Navy + cyan logo + orange subtitle |
| Partner | Sheet chrome, accent name, gold confirm hint |
| Home | Paper top / navy bottom bar, orange Adventure CTA, cyan hints, card Pack/Journal sheets |
| Adventure Field Unit | Paper top bar, cyan accent strip, navy sheets with card BBCode |
| Shop | Navy sheet, shopkeeper Bit, item cards + purchase SFX |
| Quests | Story vs side sections, reward Bits, cleared count |
| Map | Island silhouette, cyan/orange device frame |
| Collection | Database card sheet (locations, achievements, memories) |
| Settings | Same sheet language as Shop (Select) |
| Prompt | Navy panel + cyan text |

## Sound

| Id | Use |
|----|-----|
| `ui_blip` | Focus move |
| `ui_confirm` | Confirm / soft ack |
| `ui_cancel` | Back / close |
| `ui_purchase` | Buy success chord |
| `menu_beep` | Open sheet / settings |
| `boot_chime` | Power on |

## Navigation (pad only)

- **D-pad** move focus  
- **A** confirm  
- **B** back  
- **Start** Adventure / Field Unit  
- **Select** Settings  
- **X** cycle sheets / shop owned  
- **R** map peek  

Always show a control hint on screen.
