# Product Spec (Draft)

## Summary
A Rails app for generating sewing patterns from user-defined parameters across multiple assemblies. The first assembly is a simple 3D zipper pouch to validate the workflow. Users tune measurements (length, width, depth, seam allowance, pocket placement), see a live preview (2D SVG + 3D assembly), and export a complete pattern packet (SVG pieces, printable PDF, and a text instruction file). Core logic is a geometry engine that produces accurate pattern pieces and assembly steps from stored assembly definitions.

## Goals
- Make it easy to define pouch parameters and immediately preview the result.
- Generate accurate, printable pattern pieces and clear assembly steps.
- Produce exportable assets suitable for home printing and sewing.
- Build a foundation that supports multiple assembly types over time.

## Non-Goals (for now)
- Multi-item projects beyond the simple 3D zipper pouch (first assembly only).
- Client-side-only rendering or offline-first behavior.
- Advanced sizing libraries or garment grading.

## Target Users
- Sewing hobbyists who want quick, customizable zipper pouch patterns.
- Makers who prefer printable patterns with clear instructions.

## Primary UI (Main Design View)
Reference sketch: `Sewing pattern app.png` (repo root).

Layout:
- Left column: large **Preview** area showing the current assembly visualization (3D canvas).
- Bottom row (left): **Panels** strip showing thumbnails for individual pattern pieces.
- Right column: **Options** panel with inputs and controls.
- Bottom right: **Export** panel with name field and export actions.

Options panel (as sketched):
- Assembly-specific measurement inputs (initially: Height, Width, Depth for the pouch).
- Zipper location selector (icon/toggle set: top/left/right/bottom).
- Zipper style selector (dropdown).
- Pocket controls (not fully specified yet).

Export panel (as sketched):
- Name input for the pattern.
- Primary action: download/export pattern packet.
- Secondary action: share.

Note: Admin/project management UI will be added later; this view is the core functionality. The layout should remain assembly-agnostic, with options changing per assembly type.

## 3D Preview
- The main preview is a Three.js canvas that assembles rigid panels into a 3D form.
- Assembly uses the panel + seam definitions (edge-to-edge folds) rather than a generic box model.
- This is a dimensional preview, not a cloth simulation or photorealistic render.
- Users can rotate/zoom the preview.
- The preview transitions between a flat panel layout and the assembled form.
- A “Preview SVG” link remains available for the 2D layout reference.

## Options Spec (Main View)
All options update the preview and pattern output. Inputs accept numeric values, with inline validation and units shown. The options panel is assembly-agnostic; individual assemblies define their own parameter sets.

Units:
- Default: inches.
- Allow toggle between inches and centimeters.
- Internally store in a canonical unit (TBD) and convert for display.

Measurements:
- Height (aka length): overall vertical size of pouch body.
- Width: horizontal size of pouch body.
- Depth: gusset depth (front-to-back).
- Seam allowance: added to all pattern edges (default on).

Suggested defaults (adjust later):
- Height: 9 in
- Width: 11 in
- Depth: 1.5 in
- Seam allowance: 0.25 in

Suggested ranges (adjust later):
- Height: 4–18 in
- Width: 4–18 in
- Depth: 0.5–4 in
- Seam allowance: 0–1 in

Validation rules:
- All measurements must be positive numbers.
- Depth must not exceed Height or Width.
- Seam allowance may be 0.
- Show inline error text and disable export if invalid.

Zipper location:
- Choices: Top, Left, Right, Bottom (icon toggles).
- Multi-select (user can choose one, multiple, or all).
- Default: Top.
- Affects preview orientation and pattern pieces.

Zipper style:
- Dropdown (initial set TBD).
- Should not change geometry unless a style requires different construction.

Pocket controls:
- Placement: Top/Center/Bottom (relative position).
- Size: optional width/height fields or preset sizes.
- Toggle: Off/On.
- Defaults: Off, placement Center.

Behavior:
- Changes re-render SVG preview server-side.
- Options panel shows brief helper text for unusual constraints.

## Core User Flow
1. User lands on a Projects list and creates a new project or opens an existing one.
2. Project is created with an assembly definition (initially zipper pouch).
3. User enters the builder view for that project (Design Session UUID).
4. User adjusts parameters (length, width, depth, seam allowance, pocket placement).
5. App saves a snapshot of the parameters to the session.
6. App renders a live 2D SVG preview and a 3D assembly preview.
7. User exports a pattern packet.
8. App delivers SVG pieces, a PDF print layout, and a text instruction file.

## Design Sessions (State + UUID)
- Every design session has a UUID.
- Each save stores a snapshot of the current parameter set plus optional notes.
- Sessions reference an assembly definition (the pattern logic source).
- Sessions are the unit for future user ownership, sharing, and history.

## Assemblies (Pattern Definitions)
- Assemblies are stored definitions that describe panels, edges, seams, and steps.
- Each project references an assembly definition (by ID or version).
- The geometry engine interprets the definition + parameters to produce output.
- Assemblies are versioned to keep projects reproducible over time.

## Inputs (Parameters)
- Length
- Width
- Depth
- Seam allowance
- Pocket placement
 - Zipper location
 - Zipper style
 - Units
 - Optional session name/notes (metadata)

## Outputs
- SVG files for each pattern piece
- PDF print layout
- Text instructions/assembly steps

## System Notes
- Rails app serves UI and generates SVG server-side.
- Geometry engine interprets stored assembly definitions and parameters.
- 3D preview uses seam metadata to build a rigid assembly in Three.js.

## Open Questions
- What units are supported (inches, cm) and how are they displayed?
- What are valid parameter ranges and constraints?
- How should pocket placement be defined (absolute vs. relative)?
- How is the PDF composed (single-page vs. tiled)?
- How are instructions formatted (plain text, markdown)?
