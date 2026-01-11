# Product Spec (Draft)

## Summary
A Rails app that generates sewing patterns from user-defined parameters for a simple 3D zipper pouch. Users tune measurements (length, width, depth, seam allowance, pocket placement), see a live preview rendered from server-generated SVG, and export a complete pattern packet (SVG pieces, printable PDF, and a text instruction file). Core logic is a Ruby geometry engine that produces accurate pattern pieces and assembly steps.

## Goals
- Make it easy to define pouch parameters and immediately preview the result.
- Generate accurate, printable pattern pieces and clear assembly steps.
- Produce exportable assets suitable for home printing and sewing.

## Non-Goals (for now)
- Multi-item projects beyond the simple 3D zipper pouch.
- Client-side-only rendering or offline-first behavior.
- Advanced sizing libraries or garment grading.

## Target Users
- Sewing hobbyists who want quick, customizable zipper pouch patterns.
- Makers who prefer printable patterns with clear instructions.

## Primary UI (Main Design View)
Reference sketch: `Sewing pattern app.png` (repo root).

Layout:
- Left column: large **Preview** area showing the 3D pouch visualization.
- Bottom row (left): **Panels** strip showing thumbnails for individual pattern pieces.
- Right column: **Options** panel with inputs and controls.
- Bottom right: **Export** panel with name field and export actions.

Options panel (as sketched):
- Measurement inputs: Height, Width, Depth.
- Zipper location selector (icon/toggle set: top/left/right/bottom).
- Zipper style selector (dropdown).
- Pocket controls (not fully specified yet).

Export panel (as sketched):
- Name input for the pattern.
- Primary action: download/export pattern packet.
- Secondary action: share.

Note: Admin/project management UI will be added later; this view is the core functionality.

## Options Spec (Main View)
All options update the preview and pattern output. Inputs accept numeric values, with inline validation and units shown.

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
1. User opens the pouch builder.
2. User adjusts parameters (length, width, depth, seam allowance, pocket placement).
3. App renders a live SVG preview (server-generated).
4. User exports a pattern packet.
5. App delivers SVG pieces, a PDF print layout, and a text instruction file.

## Inputs (Parameters)
- Length
- Width
- Depth
- Seam allowance
- Pocket placement

## Outputs
- SVG files for each pattern piece
- PDF print layout
- Text instructions/assembly steps

## System Notes
- Rails app serves UI and generates SVG server-side.
- Ruby geometry engine builds pattern pieces and assembly steps from parameters.

## Open Questions
- What units are supported (inches, cm) and how are they displayed?
- What are valid parameter ranges and constraints?
- How should pocket placement be defined (absolute vs. relative)?
- How is the PDF composed (single-page vs. tiled)?
- How are instructions formatted (plain text, markdown)?
