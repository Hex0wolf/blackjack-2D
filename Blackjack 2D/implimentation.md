# Blackjack 2D Implementation Strategy (8 Phases, Granular)

## Summary
This strategy updates the existing codebase in small, low-risk phases to reach a TestFlight-ready beta while preserving the locked product decisions from `plan.md`.

It is grounded in current repo state:
1. Core gameplay loop exists and builds successfully.
2. UI currently violates the minimal-HUD requirement.
3. SpriteKit scene is label/text-based, not sprite-card/table based.
4. XCTest target exists with unit, smoke, and integration coverage.
5. Deployment target is aligned to iOS 17.0.

## Phase Plan

## Current Status (as of February 14, 2026)
1. Phase 1: Completed
2. Phase 2: Completed
3. Phase 3: Completed
4. Phase 4-8: Pending
### 1. Phase 1: Foundation and Compatibility Lock (Completed)
Goal: align project baseline and create scaffolding for safe incremental delivery.

Implementation:
1. Set deployment target to iOS 17.0 in `Blackjack 2D.xcodeproj/project.pbxproj`.
2. Add XCTest unit test target and source folders: `Blackjack 2DTests`.
3. Add smoke test scheme wiring and deterministic seed fixtures.
4. Add build-time guardrails for missing assets/audio keys (non-fatal fallback policy).

Exit criteria:
1. `xcodebuild ... build` succeeds for simulator.
2. `xcodebuild ... test` succeeds with at least smoke tests running.
3. No gameplay behavior changes yet.

### 2. Phase 2: Core Rules and Determinism Hardening (Completed)
Goal: make rules/flow fully test-backed and deterministic.

Implementation:
1. Harden `StandardBlackjackRulesEngine` for edge cases around split/double/blackjack ordering.
2. Introduce deterministic shoe injection path for integration tests (seeded deck fixtures).
3. Validate and tighten state transitions in `Core/GameStateMachine.swift`.
4. Add explicit round event ordering contract (deal -> resolve -> settle).

Exit criteria:
1. Unit coverage for hand valuation, legal actions, dealer soft-17 stand, and payout matrix.
2. Deterministic full-round integration tests pass.
3. No regressions in current play loop.

### 3. Phase 3: Presentation Contract Refactor (Completed)
Goal: decouple UI from string-rendered cards and prep sprite-first rendering.

Implementation:
1. Replace string-heavy `GameSnapshot` with render-model structs: `CardRenderModel`, `HandRenderModel`, `TableRenderModel`, while keeping backward compatibility for one phase via adapter.
2. Update `Presentation/BlackjackViewModel.swift` to emit typed snapshot data.
3. Keep `GameSceneView` API stable while internalizing new snapshot mapping.

Exit criteria:
1. App behavior unchanged from user perspective.
2. Snapshot tests for portrait/landscape data shape.
3. No direct `Hand.rendered()` dependency in scene layer.

Completion notes:
1. Added typed render models: `CardRenderModel`, `HandRenderModel`, `TableRenderModel`.
2. Updated `BlackjackViewModel` to emit typed snapshot data.
3. Kept compatibility adapter on `GameSnapshot` and stable `GameSceneView` API.
4. Added snapshot-shape tests and validated suite pass via `xcodebuild test`.

### 4. Phase 4: SpriteKit Table/Card Scene Upgrade
Goal: replace label-only table with animated card/table/chip scene.

Implementation:
1. Rebuild `Presentation/BlackjackGameScene.swift` around sprite nodes and layout anchors.
2. Implement animations: initial deal, hit, split layout transition, dealer hole reveal, settle feedback.
3. Add event-driven VFX mapping and input lock integration during animation queue.
4. Keep safe fallbacks when texture keys are absent.

Exit criteria:
1. Gameplay is fully playable using sprite cards.
2. No dropped input during queued animations.
3. 60 FPS sanity on recent iPhone/iPad simulator/device spot checks.

### 5. Phase 5: Pixel UI System + Minimal HUD
Goal: enforce hard UI/UX constraints and visual system consistency.

Implementation:
1. Add Pixel UI interfaces and implementation under `Presentation`: `PixelButtonStyle`, `PixelPanelStyle`, `PixelTextStyle`, `PixelThemePalette`.
2. Refactor `Presentation/GameScreenView.swift` to: primary always-on strip = chips, bet, phase/status, legal actions only.
3. Add expandable drawer for XP/streak/history/unlocks.
4. Apply shared pixel controls to menu/settings/game views and keep 44x44 minimum tap targets.
5. Finalize portrait and landscape adaptive layouts.

Exit criteria:
1. Non-clutter rule satisfied in all phases of a round.
2. All controls use unified pixel style.
3. Orientation snapshots pass for drawer collapsed/expanded.

### 6. Phase 6: Asset Manifest and Licensed Asset Integration
Goal: integrate production art/audio after UI architecture is stable.

Implementation:
1. Add `CardAssetManifest`, `CardTheme`, `CardBackTheme` in `Assets`.
2. Load full 52-card fronts + card backs + table/chip/button textures via manifest mapping.
3. Expand audio layer behavior in `Audio/AudioService.swift`: menu loop, round loop, tension overlay, ducking priorities.
4. Normalize fallback behavior for missing resources (log + graceful substitute).

Exit criteria:
1. No hardcoded card art paths in scene code.
2. All core SFX/music events mapped.
3. Missing key does not crash and remains playable.

### 7. Phase 7: Progression, Economy, and Onboarding Tuning
Goal: lock the arcade loop quality for sustained sessions.

Implementation:
1. Tune XP/chip flow in `Meta/ProgressionService.swift` and modifier impacts.
2. Validate bankruptcy recovery and daily grant cadence in `Meta/PlayerProfile.swift`.
3. Refine 4-step tutorial UX and replay/skip paths in `Presentation/GameScreenView.swift`.
4. Ensure unlock persistence includes theme selections.

Exit criteria:
1. 10-minute session sustainability target met.
2. Daily grant flow works across app relaunch and cooldown boundary.
3. Tutorial completion state persists correctly.

### 8. Phase 8: Beta Hardening and TestFlight Readiness
Goal: complete validation, migration safety, and release polish.

Implementation:
1. Add save migration tests for `saveVersion` evolution in `Persistence/SaveRepository.swift`.
2. Run full matrix checks: orientation, performance, audio overlap, input locking, long-session stability.
3. Add release checklist artifacts: known issues, test evidence, fallback behavior verification.
4. Perform TestFlight packaging pass and pre-submission sanity.

Exit criteria:
1. Full automated test suite green.
2. Manual acceptance scenarios pass.
3. Build is ready for external beta distribution.

## Public API / Interface Changes (Planned)
1. `GameSnapshot` evolves from string-only fields to typed render models.
2. Add Pixel UI interfaces: `PixelButtonStyle`, `PixelPanelStyle`, `PixelTextStyle`, `PixelThemePalette`.
3. Add asset manifest interfaces: `CardAssetManifest`, `CardTheme`, `CardBackTheme`.
4. `AudioService` expanded to support layered/tension playback state logic.
5. `SaveRepository` remains protocol-compatible but moves to `saveVersion = 2` with explicit migration tests.
6. Add XCTest target APIs for deterministic fixtures and integration helpers.

## Test Cases and Scenarios

### Unit
1. Hand ace valuation edge cases and blackjack detection.
2. Allowed action matrix by phase and bankroll constraints.
3. Dealer stands on soft 17 behavior.
4. Payout correctness for win/lose/push/blackjack/double/split.
5. XP/level/unlock threshold correctness.
6. Save decode failure fallback + corruption backup + migration path.

### Integration
1. Deterministic full round from bet -> initial deal -> actions -> settle.
2. Split branch with mixed outcomes across primary/split hands.
3. Modifier impact on bet/xp/streak pipeline.
4. Input lock behavior while animation queue is active.

### UI/Gameplay Validation
1. Portrait and landscape snapshots with minimal HUD verified.
2. Drawer collapsed and expanded content checks.
3. Pixel button consistency across menu/game/settings.
4. Legal action visibility per phase.
5. Tutorial first-run, skip, replay persistence.

### Performance/Operational
1. 60 FPS target sanity for heavy VFX events.
2. Audio latency/overlap and ducking behavior checks.
3. Memory stability across multi-round sessions.

## Assumptions and Defaults
1. Phase cadence: 8-phase granular rollout.
2. Asset timing: integrate licensed assets after Pixel UI and scene architecture are stable.
3. Deployment target: iOS 17.0.
4. Architecture remains SpriteKit gameplay core with SwiftUI shell.
5. Local-only persistence in v1; no backend/cloud work.
6. No monetization, multiplayer, or expanded casino rule variants in v1.
