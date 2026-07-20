# Shop & Map Layout

## Analysis (before)

| Gap | Was |
|-----|-----|
| Economy | Bits earned; `spend_bits` unused; Shop HUD stub |
| Items | Materials only; no categories / use / equip |
| POI layout | Park→Salty→Fields felt like a south corridor |

## Shop (handheld)

- `ItemData.shop_category` + priced catalog (Creature / Player / Home / Adventure)
- `ShopManager` buy / use / equip + unique ownership + save
- `FieldUnitShop` — D-pad browse, L/R or shoulders category, A buy/use, X owned pack, B close
- Entry: Home Shop button + Market Mile Bit Grocer (`ShopInteractable`)
- Prices: snacks ~45–120; mid gear ~150–280; goals (Spark Seed 650, Moss Bed 520, Trail Cloak 420) need saving

## Economy

| Source | Typical Bits |
|--------|----------------|
| Start | 50 |
| Normal chest | 8–18 |
| Rare chest | 28–48 |
| Legendary chest | 70–110 |
| Discoveries | 8–24 |
| Quests | 30–70 |

## Map (hub-and-spoke)

Pleasant Park center. Majors off-axis (not a line). Roads radiate; mini-map follows `GrasslandLayout` + `RegionMapCatalog`.
