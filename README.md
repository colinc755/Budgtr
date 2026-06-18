# Budgtr

Budgtr is starting as a local-first SwiftUI personal finance tool focused on two jobs:

- estimating take-home pay from income, deductions, filing status, and work state
- planning a monthly budget with category-level carryover

## Phase 1 Foundation

The first build keeps the financial logic separate from the screens:

- `Models/` contains Codable domain models for profiles, income, categories, months, and allocations.
- `Services/` contains the calculator layer for take-home pay, simple taxes, money formatting, and carryover.
- `ViewModels/BudgetStore.swift` owns local persistence and can later become the integration point for account sync.
- `Views/` contains the initial dashboard, income editor, and budget editor.

Local data is currently saved as JSON in the app's documents directory. This keeps the foundation simple while leaving room for CloudKit, account auth, or a server-backed sync layer later.

## Next Good Chunks

1. Add editing for used amounts inside the monthly budget.
2. Add a month picker and monthly history.
3. Expand deduction editing.
4. Add tests around tax estimates and carryover rules.
5. Replace the simple state tax fallback with state-specific calculators one state at a time.
