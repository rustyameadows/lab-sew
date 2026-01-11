# Development Plan (Draft)

## Summary of Steps
1. Project foundation and tooling
2. Core domain model and persistence (including Design Session UUIDs)
3. Main UI scaffold (matches sketch)
4. Ruby geometry engine (pattern pieces + assembly steps)
5. SVG preview pipeline (server-rendered)
6. Live update wiring (options -> preview)
7. Export pipeline (SVGs, PDF layout, instructions)
8. Validation, constraints, and UX polish
9. Tests, QA, and release readiness

---

## 1) Project foundation and tooling
Goal: establish a clean Rails baseline and dev workflow.
- Confirm Rails version, Ruby version, and dependency baseline.
- Establish app structure for pattern generation (services/lib).
- Add baseline linting/testing (RSpec or Minitest) and simple CI later.
- Create minimal routes and controller for the main builder view.

## 2) Core domain model and persistence (including Design Session UUIDs)
Goal: define how a design is represented, stored, and versioned.
- Create `DesignSession` (or `PatternSession`) model:
  - UUID primary or separate `uuid` column.
  - Stores parametric settings snapshot (JSON or structured columns).
  - Stores notes, user association (future), timestamps.
- Define canonical parameter schema (length/height, width, depth, seam allowance, pocket placement, zipper location/style, units).
- Create migrations and basic CRUD endpoints (create/read/update).
- Ensure all operations are idempotent for “save state by UUID”.

## 3) Main UI scaffold (matches sketch)
Goal: build the layout while keeping it functional.
- Layout regions: Preview, Options, Panels strip, Export panel.
- Wire the form inputs for core parameters with placeholders for advanced options.
- Add a “live preview” container (initially static or stubbed).

## 4) Ruby geometry engine (pattern pieces + assembly steps)
Goal: generate accurate pieces from parameters.
- Implement a small library in `lib/` or `app/services/`.
- Define input contract and output structure:
  - pattern pieces (named polygons/paths)
  - seam allowance expansions
  - assembly steps list
- Add unit tests for geometry output consistency.

## 5) SVG preview pipeline (server-rendered)
Goal: render a reliable preview from the geometry engine.
- Convert geometry output to SVG shapes.
- Provide a controller endpoint returning SVG for a given session or parameter set.
- Establish a consistent coordinate system and scale.

## 6) Live update wiring (options -> preview)
Goal: real-time UX that updates preview on change.
- Connect Options inputs to preview refresh (Turbo/Hotwire or plain fetch).
- Debounce input changes for smooth interactions.
- Persist changes to Design Session UUID as the single source of truth.

## 7) Export pipeline (SVGs, PDF layout, instructions)
Goal: export a complete pattern packet.
- Generate SVG files per pattern piece.
- Assemble a printable PDF layout (single page or tiled; decide).
- Export text instructions (plain text to start).
- Provide a download action in the Export panel.

## 8) Validation, constraints, and UX polish
Goal: reduce invalid states and improve clarity.
- Add inline validation for measurement ranges.
- Define constraints (depth <= width/height, etc.).
- Show helpful warnings; disable export if invalid.

## 9) Tests, QA, and release readiness
Goal: ensure reliability as functionality grows.
- Unit tests for geometry engine and conversions.
- Request/feature tests for preview and export endpoints.
- Basic performance checks for SVG rendering.

---

## Notes on Design Sessions
- Each design session gets a UUID.
- We store a snapshot of parameters and additional notes at each save.
- This enables future features like user accounts, sharing, and version history.
