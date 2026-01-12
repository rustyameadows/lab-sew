# Development Plan (Draft)

## Summary of Steps
1. Project foundation and tooling
2. Core domain model and persistence (including Design Session UUIDs)
3. Assembly definitions (data model + seed)
4. Main UI scaffold (matches sketch)
5. Geometry engine (interprets assemblies + parameters)
6. SVG preview pipeline (server-rendered)
7. 3D preview pipeline (Three.js)
8. Live update wiring (options -> preview)
9. Export pipeline (SVGs, PDF layout, instructions)
10. Validation, constraints, and UX polish
11. Tests, QA, and release readiness

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

Status (completed):
- Design sessions model + UUID + JSON snapshot implemented.
- Default parameter schema added (including multi-select zipper locations and pocket settings).
- Projects index created; builder view now lives at `/projects/:uuid`.
- Autosave wired for project name and option parameters (debounced PATCH).
- Builder inputs now repopulate from saved session values.

## 3) Assembly definitions (data model + seed)
Goal: store assembly logic as data that can scale to many types.
- Create `AssemblyDefinition` model:
  - name, version, description
  - `definition_json` (panels, edges, seams, steps)
- Link `DesignSession` to an `assembly_definition_id`.
- Seed the initial zipper pouch assembly definition.

Status (completed):
- Assembly definitions model and DB table added.
- Design sessions reference an assembly definition.
- Default assemblies seeded (zipper pouch + tote bag).
- Existing design sessions backfilled to the default assembly definition.

## 4) Main UI scaffold (matches sketch)
Goal: build the layout while keeping it functional.
- Layout regions: Preview, Options, Panels strip, Export panel.
- Wire the form inputs for core parameters with placeholders for advanced options.
- Add a “live preview” container (initially static or stubbed).

Status (completed):
- Layout scaffold implemented and matches the sketch structure.
- Projects index added; builder view is routed per project.
- Autosave wired for project name + option parameters with values persisted.
- Assembly selector added on the builder view; options are hidden until selected.
- Options and panels are driven by the assembly definition schema.

## 5) Geometry engine (interprets assemblies + parameters)
Goal: generate accurate pieces from assembly definitions + parameters.
- Implement an interpreter in `app/services/`.
- Define input contract and output structure:
  - pattern pieces (named polygons/paths)
  - seam allowance expansions
  - assembly steps list
- Add unit tests for geometry output consistency.

Status (completed):
- Geometry engine returns panel shapes from assembly definitions + params.

## 6) SVG preview pipeline (server-rendered)
Goal: render a reliable preview from the geometry engine.
- Convert geometry output to SVG shapes.
- Provide a controller endpoint returning SVG for a given session or parameter set.
- Establish a consistent coordinate system and scale.

Status (completed):
- Basic SVG renderer added to visualize panel rectangles.
- Preview and panel SVG endpoints wired into the UI.

## 7) 3D preview pipeline (Three.js)
Goal: assemble panels into an interactive 3D preview.
- Render a Three.js canvas in the main preview area.
- Assemble panel planes into a 3D form based on assembly definition metadata.
- Animate a transition from flat layout to assembled form.
- Keep a “Preview SVG” link for 2D reference.

Status (completed):
- Three.js preview canvas replaces the static image.
- Toggle between flat and assembled states.
- Rigid assembly uses panel seams for folding (not a generic box).
- Preview stays synced to parameter changes via geometry refresh.

## 8) Live update wiring (options -> preview)
Goal: real-time UX that updates preview on change.
- Connect Options inputs to preview refresh (Turbo/Hotwire or plain fetch).
- Debounce input changes for smooth interactions.
- Persist changes to Design Session UUID as the single source of truth.

Status (completed):
- Save now triggers cache-busted refreshes for preview SVG + panel thumbnails.
- 3D preview re-fetches geometry on save without forcing camera resets.
- Toggle 3D now handles camera recentering/angles; input changes no longer snap the view.

## 9) Export pipeline (SVGs, PDF layout, instructions)
Goal: export a complete pattern packet.
- Generate SVG files per pattern piece.
- Assemble a printable PDF layout (single page or tiled; decide).
- Export text instructions (plain text to start).
- Provide a download action in the Export panel.

## 10) Validation, constraints, and UX polish
Goal: reduce invalid states and improve clarity.
- Add inline validation for measurement ranges.
- Define constraints (depth <= width/height, etc.).
- Show helpful warnings; disable export if invalid.

## 11) Tests, QA, and release readiness
Goal: ensure reliability as functionality grows.
- Unit tests for geometry engine and conversions.
- Request/feature tests for preview and export endpoints.
- Basic performance checks for SVG rendering.

---

## Notes on Design Sessions
- Each design session gets a UUID.
- We store a snapshot of parameters and additional notes at each save.
- This enables future features like user accounts, sharing, and version history.
- Each design session references an assembly definition.
