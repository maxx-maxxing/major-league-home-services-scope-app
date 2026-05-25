Read codex_context.md before making changes.

Current working focus:
Project-type-driven section visibility in the scope editor.

Highest-priority requirement:
When a customer/scope is brought into the app from JobTread, the left sidebar should initially show only `Project Information`. After the salesperson selects one or more applicable project types, only the sections relevant to those project types should appear in the left sidebar.

Important constraint:
Do not destabilize the current working JobTread customer search/select, linked-customer hydration, verified read-only ownership behavior, Documents / Attachments section, pricing engine, persistence continuity fixes, current PDF export improvements, or current section review/completion workflow unless the task explicitly requires it.

Current app phase:
The next active phase is to reduce sidebar overwhelm and field friction by making the section list contextual to the selected project type(s) instead of always showing every possible section.

What is already true:
- SwiftUI iPad construction scope app exists
- Core section-based workflow exists
- Offline-first behavior remains important
- JobTread connectivity has been verified
- Scope naming has been separated from customer identity
- JobTread customer search/select creation path exists
- Live partial-name JobTread customer search works
- Selecting a JobTread customer creates a linked scope
- Linked-customer hydration works for verified fields and has recently been strengthened for phone/email
- Verified JobTread-sourced customer fields are treated as read-only in the app
- Current PDF export now includes only relevant scope content and has improved layout/thumbnail behavior
- Signature and Site Diagram persistence have been strengthened enough to survive recent continuity tests
- Section review/completion workflow exists or is in active progress

Known limitations / current truths:
- Right now the app exposes too many sections at once in the sidebar, even when many are irrelevant to the current job
- This feels overwhelming in the field and slows down real scope capture
- Multiple project types may be selected for one scope
- Hidden sections should preserve any existing data in the scope
- Hidden sections should NOT participate in export/PDF composition while hidden/not relevant
- This phase should focus on contextual visibility, not destructive data clearing

Current architectural direction:
- `Project Information` is the entry point and should drive section relevance
- Section visibility should be derived from selected project type(s)
- For multiple selected project types, visible sections should be the union of relevant sections
- If project types are changed later, the sidebar should update dynamically
- Hidden section data must be preserved unless a future phase explicitly chooses otherwise
- Hidden sections must be excluded from export/PDF composition while hidden
- This visibility system should reduce field overwhelm without introducing validation friction

Immediate implementation direction:
- Add a section relevance model based on selected project types
- Make the sidebar/contextual section list render only:
  - `Project Information` initially
  - then relevant sections once project types are selected
- Preserve existing hidden section data in the scope model
- Exclude hidden sections from export composition while hidden/not relevant
- Keep this first pass focused on the sidebar visibility system and safe architecture, not broad UX polish

Likely first-pass section mapping guidance:
- Always visible:
  - Project Information
- Broadly shared after project type selection:
  - Existing Conditions
  - Documents / Attachments
  - Signatures / Export
- Screen Enclosure project types likely show:
  - Screen Enclosure
  - Structural System
  - Electrical
  - Drainage
  - Attachment Conditions
  - Finishes
- Sunroom project types likely show:
  - Sunroom
  - Structural System
  - Electrical
  - Drainage
  - Attachment Conditions
  - Finishes
- Structural/roof/cover oriented project types likely show:
  - Structural System
  - Electrical
  - Drainage
  - Attachment Conditions
  - Finishes
- This mapping should be implemented cleanly and be easy to refine later from field feedback

Most relevant near-term domains to build:
- project-type-to-section mapping
- contextual sidebar visibility
- hidden-section preservation
- export exclusion for hidden sections
- multi-project union visibility rules

Current priorities:
1. Show only `Project Information` before project types are selected
2. Show only relevant sections after project types are selected
3. Preserve hidden section data
4. Exclude hidden sections from exports/PDF while hidden
5. Keep the mapping easy to refine later
6. Avoid destabilizing current working scope editing behavior

Editing rules:
- Follow READ → PLAN → EDIT
- Make surgical edits
- Do not rewrite large files unnecessarily
- Preserve working service and model boundaries
- Explain what files changed and why
- Prefer incremental, production-safe changes over broad refactors
- Keep business logic out of low-level rendering code where possible
- This phase is contextual section visibility first, not destructive data cleanup
