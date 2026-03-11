Read codex_context.md before making changes.

You are working on a SwiftUI iPad app branch whose explicit goal is to push Apple’s Liquid Glass design language to a strong Apple-demo-style extreme while remaining readable and usable.

Before doing any work:

1. Read this entire specification.
2. Follow the editing rules and workflow defined below.
3. Do NOT rewrite large files unless explicitly required.

This specification should be saved into a file named:

codex_context.md

in the root of the repository.

If codex_context.md does not exist:
create it and place this entire specification inside it.

All future Codex sessions should begin with:

Read codex_context.md before making changes.

--------------------------------------------------

PROJECT CONTEXT

This is a SwiftUI-first iPad construction scope / production order application used by field estimators.

The app:

- works offline
- captures structured job scopes
- supports sketches, signatures, and photos
- exports a flattened PDF production order.

Current branch:

feature/liquid-glass-chrome-pass

Recent UI evolution:

This branch evolved from a restrained glass chrome pass into a deliberately maximalist Apple Liquid Glass exploration.

Major glass styling is in place across:

- shells
- cards
- inputs
- photo/PDF sheets
- toolbar and action chrome.

Shared input styling lives in:

Components/CardComponents.swift

Key modifiers:

liquidGlassInput()
liquidGlassInputBackground()
liquidGlassSurface()

The toolbar implementation was recently corrected.

Important final state:

The custom floating toolbar capsule was removed from the top bar.

Toolbar actions now render directly inside the system toolbar host.

This fixed the “sticker on top of another sticker” problem caused by nested glass capsules.

Current commit:

d9878de
"Refine liquid glass toolbar chrome"

--------------------------------------------------

KEY SWIFTUI FILES CONTROLLING LAYOUT

Views/RootNavigationView.swift

Main application shell.
Contains:

- NavigationSplitView
- sidebar
- section routing
- editor header
- toolbar actions
- rename overlays.

Views/SectionEditors.swift

Contains section editor UIs and shared editor helper views.

Components/CardComponents.swift

This is the shared UI material system.

Contains:

- glass surfaces
- cards
- status pill
- action icon styling
- input modifiers.

Views/PhotoAttachmentSupport.swift

Photo management sheet and preview helpers.

PDFEngine/PDFPreviewStubView.swift

PDF preview and export shell UI.

Views/PencilDrawingSupport.swift

PencilKit canvas wrapper used by signature and sketch flows.

--------------------------------------------------

CRITICAL PROJECT RULES

schema.json is the source of truth for fields and enums.

If fields change:
update schema.json first.

UI decisions should respect UI_SYSTEM.md even though this branch intentionally pushes styling beyond production levels.

PDF behavior must remain aligned with:

PDF_EXPORT.md

Planning documentation lives in:

PLANS.md
DOCUMENTATION.md

Milestone coverage already includes:

Milestone 7.3 restrained pass
Milestone 7.4 maximalist Liquid Glass exploration

--------------------------------------------------

EDITING WORKFLOW (MANDATORY)

Always follow the READ → PLAN → EDIT workflow.

STEP 1 — READ

Inspect the relevant file(s) first.
Understand existing structure before editing.

STEP 2 — PLAN

Explain briefly:

- what will change
- which functions or views will be modified
- why the change aligns with the Liquid Glass specification.

STEP 3 — EDIT

Perform minimal surgical edits.

Never rewrite large sections unnecessarily.

--------------------------------------------------

SYMBOL-SCOPED EDITING (VERY IMPORTANT)

When modifying code, target specific functions or components instead of rewriting entire files.

Example instruction style:

Focus only on:

Components/CardComponents.swift → liquidGlassInputBackground()

or

Views/RootNavigationView.swift → toolbar action cluster

Do not restructure unrelated sections of the file.

Prefer edits that modify:

- a single function
- a single modifier
- a single view block

This prevents accidental rewrites of the UI system.

--------------------------------------------------

SURGICAL EDIT RULES

1. Do NOT rewrite entire files unless absolutely necessary.

2. Prefer minimal targeted edits.

3. Preserve existing architecture and component APIs.

4. Modify only the smallest possible section of code.

5. Do NOT reorganize unrelated code.

6. Avoid unnecessary reformatting.

7. Avoid introducing duplicate components.

--------------------------------------------------

CRITICAL FILE PROTECTION

The following files form the UI design system and should rarely be rewritten:

Components/CardComponents.swift
Views/RootNavigationView.swift
Views/SectionEditors.swift

Edits to these files must be minimal and localized.

Never redesign them wholesale.

--------------------------------------------------

COMPONENT TARGETS

Most UI styling should be modified inside these functions:

liquidGlassSurface()

liquidGlassInput()

liquidGlassInputBackground()

Do not restructure CardComponents.swift itself unless necessary.

--------------------------------------------------

PRIMARY GOAL

Implement Liquid Glass with first-party Apple consistency.

Do not default to restraint simply because it feels safer.

This branch intentionally explores the upper bound of Apple-style Liquid Glass so the visual ceiling can be evaluated before scaling back.

--------------------------------------------------

SOURCE OF TRUTH

Follow Apple’s official Liquid Glass guidance and APIs:

Adopting Liquid Glass
Human Interface Guidelines: Materials
Applying Liquid Glass to custom views
Landmarks: Building an app with Liquid Glass
WWDC sessions introducing the new Apple design system and Liquid Glass

--------------------------------------------------

DESIGN INTENT

Liquid Glass is a dynamic material combining optical glass properties with fluidity.

Characteristics:

- translucent
- dynamic
- refractive
- reflective
- edge lensing
- unified visual language across Apple platforms.

The design should elevate content, not bury it under decorative chrome.

--------------------------------------------------

NON-NEGOTIABLE PRINCIPLES

GLASS IS A CONTROL / CHROME LAYER

Use Liquid Glass primarily for:

- navigation bars
- toolbars
- tab bars
- sidebars
- floating control clusters
- sheets and popovers
- primary interactive controls.

Avoid using glass for:

- dense text regions
- long forms
- list rows
- reading surfaces
- large content panes.

--------------------------------------------------

CONTENT MUST STAY PRIMARY

Interface hierarchy should read:

content first
controls floating above content.

Glass should never compete with the information users are working with.

--------------------------------------------------

USE SYSTEM COMPONENTS FIRST

Prefer native SwiftUI components.

Only build custom glass surfaces when system components cannot achieve the correct behavior.

--------------------------------------------------

ONE COHESIVE GLASS OBJECT > MANY SMALL TILES

Group related controls into a single shared glass cluster.

Prefer:

one capsule cluster
embedded icons
soft separators
pooled highlights.

Avoid:

mini capsules
stacked blur tiles
glass stickers.

--------------------------------------------------

AVOID GLASS-ON-GLASS STACKING

If sheets or overlays appear:

reduce competing glass layers behind them.

Preserve the illusion of a single floating control layer.

--------------------------------------------------

SHAPES SHOULD FEEL APPLE-LIKE

Prefer:

capsules
rounded rectangles
circles
continuous corners.

Avoid:

hard edges
boxy panels
ornamental shapes.

--------------------------------------------------

MOTION SHOULD BE CONTINUOUS

Prefer morphing transitions over abrupt replacement.

Use SwiftUI APIs:

glassEffect(_:in:)
GlassEffectContainer
glassEffectTransition(_:)

--------------------------------------------------

INTERACTION SHOULD FEEL ALIVE

Controls should respond subtly to touch.

Examples:

- scale
- bounce
- highlight response.

Avoid gimmicky motion.

--------------------------------------------------

TINT SPARINGLY

Glass should remain mostly neutral.

Tint indicates:

- emphasis
- selection
- semantic state.

--------------------------------------------------

MAINTAIN LEGIBILITY

Preserve:

- text contrast
- icon clarity
- tap targets
- outdoor readability.

If aesthetics conflict with readability, fix readability.

--------------------------------------------------

APPLE DEMO STYLE TARGET

The interface should feel like:

floating system chrome
subtle lensing
grouped glass clusters
clean translucency
polished transitions
unified material language.

It should NOT feel like:

generic blur
neumorphism
stacked outlines
heavy gradients
fake glass.

--------------------------------------------------

IMPLEMENTATION RULES

TOOLBARS

Use shared glass clusters.

Avoid separate capsules for every icon.

SIDEBARS

Selection should integrate with the glass system.

SHEETS

Reduce competing glass layers when sheets appear.

CARDS

Not every card should be glass.

Content cards may remain calmer surfaces.

CUSTOM VIEWS

Use official SwiftUI glass APIs.

Favor cohesion over decoration.

--------------------------------------------------

ANTI-PATTERNS

Avoid:

tiny glass capsules
glass inside glass
heavy white borders
futuristic blue tint
decorative blur backgrounds
aggressive shadows
excess gradients.

--------------------------------------------------

WHEN IN DOUBT

Ask:

Is this chrome or content?
Would Apple group these controls?
Does this preserve hierarchy?
Is it readable and tappable?
Does it feel first-party?

--------------------------------------------------

BRANCH INTENT

This branch is intentionally maximalist.

Bias toward a strong Liquid Glass interpretation.

Only scale back when:

readability suffers
hierarchy breaks
too many glass layers compete.

--------------------------------------------------

DELIVERABLE

Produce a cohesive Liquid Glass showcase version of the app that:

- follows Apple design language
- uses system APIs
- groups controls into shared glass bodies
- avoids glass stacking
- preserves usability
- feels like a first-party Apple demo build.

When making major visual decisions, leave concise comments so the design can be toned down later.
