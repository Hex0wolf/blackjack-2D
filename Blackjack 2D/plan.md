# 2D Pixel Blackjack for iOS (SpriteKit) — Decision-Complete Development Plan (Updated)

## Summary
Build a single-player, offline, retro-neon pixel blackjack game in `/Users/ethangraham/Documents/Blackjack 2D` using a SpriteKit gameplay core with an arcade progression loop, custom card/table visuals, high-feedback VFX/SFX/haptics, and full portrait/landscape support on iPhone/iPad (iOS 17+).

This plan targets a **production-grade TestFlight beta** that can be hardened for App Store submission. UI clarity is a hard requirement: no cluttered gameplay screen, minimal HUD by default, and a unified pixel-themed control system.

## Locked Product Decisions
1. Engine: SpriteKit gameplay core, SwiftUI shell for app navigation and settings.
2. Scope: Arcade-polish blackjack (not casino-depth rule variants in v1).
3. Release target: TestFlight beta quality first, then App Store hardening pass.
4. Orientation: Full adaptive support for portrait and landscape in v1.
5. Economy: Single soft currency (`chips`) with persistent progression.
6. Monetization: None in v1.
7. Ruleset: Dealer stands on soft 17, blackjack pays 3:2, split once, double on first two cards, no surrender.
8. Meta loop: Session runs + unlockable modifiers/cosmetics.
9. Persistence: Local-only save (no backend, no cloud sync).
10. Platform: iOS 17+.
11. Interaction: Tap-first controls + haptics.
12. Audio: Layered music + reactive SFX with ducking.
13. Art direction: Retro neon casino pixel style.
14. Asset sourcing: Licensed production art/audio.
15. Card production strategy: Template-generated custom deck (full 52 + backs).
16. Localization: English-only v1, localization-ready structure.

## Hard UI/UX Constraints (New)
1. **No clutter during gameplay**: in-round HUD is minimal by default.
2. Default visible HUD content only:
- Chips
- Current bet
- Current phase/status
- Legal player actions
3. Secondary content (XP, streak, unlock details, recent outcomes) must live in an **expandable panel/drawer**, not always-on blocks.
4. All buttons must use a shared **pixelated 9-slice style** with pixelated text and state variants (normal/pressed/disabled).
5. Button art, typography, and color system must visually blend with table/background/card art so controls feel native to the game world.
6. Minimum tap target remains 44x44 pt.

## Architecture and Code Organization
1. Keep `Blackjack_2DApp.swift` as app entry.
2. Keep `ContentView.swift` as root screen router for:
- `MainMenuView`
- `GameScreenView`
- `SettingsView`
3. Use/maintain this module structure under `/Users/ethangraham/Documents/Blackjack 2D/Blackjack 2D`:
- `Core/`: game loop, state machine, deterministic RNG
- `Blackjack/`: cards, hands, rules, legal actions, outcomes
- `Meta/`: progression, unlocks, modifiers, economy
- `Presentation/`: SpriteKit scene, HUD, animation orchestration, pixel UI kit
- `Audio/`: music/SFX manager + ducking/mix logic
- `Persistence/`: Codable save repository + migration handling
- `Assets/`: sprite/audio keys, card manifest, theme constants

## Public Interfaces and Types
1. `enum GamePhase`
- `idle`, `betting`, `initialDeal`, `playerTurn`, `dealerTurn`, `settle`, `rewards`, `nextRound`
2. `struct Card`, `enum Suit`, `enum Rank`
- Rank values + blackjack valuation support (soft/hard ace logic)
3. `struct Hand`
- `cards`, `bestValue`, `isSoft`, `isBlackjack`, `isBust`
4. `struct RoundContext`
- Bet state, shoe, player/dealer hands, split hand, active hand, legal actions, round events
5. `enum PlayerAction`
- `hit`, `stand`, `double`, `split`
6. `protocol BlackjackRulesEngine`
- `allowedActions(context:)`
- `apply(action:context:)`
- `resolveRound(context:) -> RoundResult`
7. `struct RoundResult`
- Payout net, outcome, hand-level resolutions, VFX/SFX event list
8. `struct PlayerProfile`
- `chips`, `xp`, `level`, `unlockFlags`, `statistics`, `settings`, `winStreak`, `lastDailyGrantAt`
9. `struct RunModifier`
- ID + gameplay hooks (bet/xp multipliers, streak effects)
10. `protocol ProgressionService`
- XP gain, level thresholds, unlock resolution
11. `protocol SaveRepository`
- `loadProfile()`, `saveProfile(_:)`, `loadSettings()`, `saveSettings(_:)`
12. `protocol AudioService`
- `playSFX(_:)`, `playMusic(_:)`, `duckMusic(for:)`, `setMix(settings:)`
13. **Add `PixelUI` interfaces (new)**
- `PixelButtonStyle`
- `PixelPanelStyle`
- `PixelTextStyle`
- `PixelThemePalette`
14. **Add card manifest/theme mapping (new)**
- `CardAssetManifest` mapping `Rank/Suit -> texture key`
- `CardTheme` / `CardBackTheme` identifiers for cosmetics

## Gameplay and Progression Design
1. Round flow:
- Place bet from chips
- Deal two cards each (dealer second hidden)
- Enable legal actions only
- Resolve dealer by rules
- Settle payout
- Apply streak/xp/unlock rewards
2. Arcade progression:
- XP per round + bonus for streaks/blackjacks/high-value outcomes
- Level unlocks: table skins, card back FX, modifier slot unlocks
- One active run modifier in v1
3. Economy:
- Tune source/sink so average 10-minute session is sustainable
- Bankruptcy fallback: daily free chips grant with local timestamp cooldown
4. Difficulty curve:
- Early levels use lower-risk progression
- Later levels increase bet pressure and risk/reward modifiers

## Presentation and Art Implementation
1. Replace label-only rendering with sprite-based table and card nodes in `Presentation/BlackjackGameScene.swift`:
- Animated card dealing
- Dealer reveal flip
- Split-hand layout anchors
- Chip movement feedback
2. Apply event-driven VFX mapping:
- `cardDealt`, `blackjack`, `bust`, `playerWin`, `dealerWin`, `winBig`, `levelUp`, `unlock`
3. Build custom deck assets (template-generated):
- 52 unique fronts
- 1 default back + unlockable variant(s)
- Optional overlays/glow states for highlighted cards
4. Add safe fallback behavior for missing textures/audio keys.

## UI/UX and Orientation Behavior
1. Gameplay HUD model (hard requirement):
- Primary strip (always visible): chips, bet, phase, legal actions
- Expandable drawer: XP/level/streak/round history/unlock detail
2. Pixel UI consistency:
- All controls use 9-slice pixel button components
- Pixel font only on gameplay/menu controls
- State transitions (pressed/disabled) handled by pixel assets, not generic SwiftUI styles
3. Layout adaptation:
- Landscape: table-first with compact side control rail
- Portrait: table top + bottom control strip + expandable drawer
4. Onboarding:
- First-run tutorial with 4 guided steps + skip + replay

## Audio, SFX, and Haptics
1. Music layers:
- Menu loop
- Round loop
- High-tension overlay during dealer resolve/high-stakes moments
2. SFX set:
- Deal, chip, confirm tap, win/loss stingers, blackjack, level-up
3. Mixing:
- Duck music for major stingers and reward announcements
4. Haptics:
- Light for button actions
- Medium for standard win/loss events
- Heavy for blackjack/level-up milestones

## Persistence and Data Schema
1. Storage method:
- Local JSON via `Codable` in app documents directory
2. Versioning:
- `saveVersion` with explicit migration path
3. Persisted entities:
- Profile, settings, unlocks, stats, selected themes, daily grant timestamp
4. Corruption handling:
- Decode failure -> safe defaults + backup corrupted file

## Testing and Verification Plan
1. Unit tests (logic-critical):
- Hand valuation with ace edge cases
- Allowed action matrix by phase/context
- Dealer resolution rules (soft 17 stand)
- Payout correctness (win/lose/push/blackjack/double/split)
- Progression XP/level thresholds
- Save encode/decode + migration fallback
2. Integration tests:
- Deterministic full round from bet to payout using seeded shoe
- Split-hand branch outcomes and settlement
- Run modifier reward impact
- Input lock while animation queue is active
3. UI/gameplay validation:
- Portrait + landscape snapshots with drawer collapsed and expanded
- Non-clutter check: primary HUD never exceeds defined minimal fields
- Pixel button style consistency across menu/game/settings
- Legal action visibility at each phase
4. Performance checks:
- Target 60 FPS on recent iPhones/iPads
- No dropped interaction during heavy VFX events
- Audio overlap/latency sanity
5. Acceptance scenarios:
- New player completes tutorial and plays 3 rounds smoothly
- Player bankruptcy recovers with daily grant
- Unlock/theme persists after relaunch
- UI remains clear and uncluttered during active rounds

## Milestones
1. Milestone 1: Core Stabilization
- Finalize deterministic round flow, legal actions, payouts, split/double edge cases
2. Milestone 2: Sprite Presentation Upgrade
- Replace text-first board with full sprite card/table/chip scene + animations
3. Milestone 3: Pixel UI System
- Implement shared 9-slice button/text/panel kit and minimal+expandable HUD
4. Milestone 4: Production Asset Pass
- Integrate licensed retro-neon deck/table/button/audio assets and manifests
5. Milestone 5: Progression + Balance
- Tune chips/xp/modifiers and daily grant cadence for sustained sessions
6. Milestone 6: Beta Hardening
- Tests, save migration checks, performance tuning, crash/edge-case cleanup for TestFlight

## Non-Goals for v1
1. Real-money gambling.
2. Online multiplayer.
3. Cloud profile sync.
4. Ads/IAP monetization.
5. Casino side bets/insurance/surrender rule expansion.
6. Multi-language localization pack.

## Assumptions and Defaults
1. Swift + SpriteKit only (no Unity/Godot).
2. Licensed art/audio includes commercial distribution rights for app deployment.
3. One modifier active at a time in v1.
4. English-only strings are structured for future localization.
5. TestFlight is the immediate quality gate; App Store packaging/compliance is a follow-up hardening pass.
