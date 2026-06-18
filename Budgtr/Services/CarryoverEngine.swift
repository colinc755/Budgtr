import Foundation

struct CarryoverEngine {
    func carryoverAmount(from allocation: CategoryAllocation) -> Double {
        switch allocation.carryoverRule {
        case .none:
            0
        case .positiveOnly:
            max(allocation.remainingAmount, 0)
        case .full:
            allocation.remainingAmount
        }
    }

    func buildNextMonth(from currentMonth: BudgetMonth, categories: [BudgetCategory], expectedInflow: Double) -> BudgetMonth {
        let carryoversByName = Dictionary(
            uniqueKeysWithValues: currentMonth.allocations.map { ($0.categoryName, carryoverAmount(from: $0)) }
        )

        let allocations = categories
            .sorted { $0.displayOrder < $1.displayOrder }
            .map { category in
                CategoryAllocation(
                    categoryName: category.name,
                    categoryKind: category.kind,
                    plannedAmount: category.monthlyAllocation,
                    carryoverAmount: carryoversByName[category.name] ?? 0,
                    carryoverRule: category.carryoverRule
                )
            }

        return BudgetMonth(
            monthStart: Calendar.current.date(byAdding: .month, value: 1, to: currentMonth.monthStart) ?? .now,
            expectedInflow: expectedInflow,
            allocations: allocations
        )
    }
}

