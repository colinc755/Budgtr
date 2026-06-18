import Combine
import Foundation

final class BudgetStore: ObservableObject {
    @Published var profile: BudgetProfile {
        didSet {
            save()
        }
    }

    init() {
        self.profile = Self.load() ?? Self.seedProfile()
    }

    func createNextMonth() {
        guard let currentMonth = profile.months.sorted(by: { $0.monthStart > $1.monthStart }).first else { return }
        let expectedInflow = profile.incomeSources.first.map {
            TakeHomePayCalculator().estimate(profile: profile, income: $0).monthlyNetIncome
        } ?? currentMonth.expectedInflow

        let nextMonth = CarryoverEngine().buildNextMonth(
            from: currentMonth,
            categories: profile.categories,
            expectedInflow: expectedInflow
        )
        profile.months.append(nextMonth)
    }

    func syncCurrentMonthWithPlan() {
        guard let monthIndex = profile.months.indices.max(by: { profile.months[$0].monthStart < profile.months[$1].monthStart }) else { return }

        for category in profile.categories {
            if let allocationIndex = profile.months[monthIndex].allocations.firstIndex(where: { $0.categoryName == category.name }) {
                profile.months[monthIndex].allocations[allocationIndex].plannedAmount = category.monthlyAllocation
                profile.months[monthIndex].allocations[allocationIndex].carryoverRuleRaw = category.carryoverRuleRaw
            } else {
                profile.months[monthIndex].allocations.append(
                    CategoryAllocation(
                        categoryName: category.name,
                        categoryKind: category.kind,
                        plannedAmount: category.monthlyAllocation,
                        carryoverRule: category.carryoverRule
                    )
                )
            }
        }

        if let income = profile.incomeSources.first {
            profile.months[monthIndex].expectedInflow = TakeHomePayCalculator()
                .estimate(profile: profile, income: income)
                .monthlyNetIncome
        }
    }

    private func save() {
        guard let data = try? JSONEncoder.budgtr.encode(profile) else { return }
        try? data.write(to: Self.fileURL, options: [.atomic])
    }

    private static func load() -> BudgetProfile? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.budgtr.decode(BudgetProfile.self, from: data)
    }

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("BudgtrProfile.json")
    }

    private static func seedProfile() -> BudgetProfile {
        var profile = BudgetProfile()
        let income = IncomeSource(
            deductions: [
                Deduction(name: "Health insurance", monthlyAmount: 220, timing: .preTax)
            ]
        )
        let categories = starterCategories()
        let estimate = TakeHomePayCalculator().estimate(profile: profile, income: income)
        let currentMonth = BudgetMonth(
            monthStart: Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now,
            expectedInflow: estimate.monthlyNetIncome,
            allocations: categories.map {
                CategoryAllocation(
                    categoryName: $0.name,
                    categoryKind: $0.kind,
                    plannedAmount: $0.monthlyAllocation,
                    carryoverRule: $0.carryoverRule
                )
            }
        )

        profile.incomeSources = [income]
        profile.categories = categories
        profile.months = [currentMonth]
        return profile
    }

    private static func starterCategories() -> [BudgetCategory] {
        [
            BudgetCategory(name: "Housing", kind: .essential, monthlyAllocation: 1_800, carryoverRule: .none, displayOrder: 0),
            BudgetCategory(name: "Utilities", kind: .essential, monthlyAllocation: 300, carryoverRule: .positiveOnly, displayOrder: 1),
            BudgetCategory(name: "Food", kind: .essential, monthlyAllocation: 650, carryoverRule: .positiveOnly, displayOrder: 2),
            BudgetCategory(name: "Transportation", kind: .essential, monthlyAllocation: 450, carryoverRule: .positiveOnly, displayOrder: 3),
            BudgetCategory(name: "Savings", kind: .savings, monthlyAllocation: 800, carryoverRule: .full, displayOrder: 4),
            BudgetCategory(name: "Retirement", kind: .retirement, monthlyAllocation: 450, carryoverRule: .full, displayOrder: 5),
            BudgetCategory(name: "Discretionary", kind: .discretionary, monthlyAllocation: 900, carryoverRule: .positiveOnly, displayOrder: 6)
        ]
    }
}

private extension JSONEncoder {
    static var budgtr: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var budgtr: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
