import Combine
import Foundation

final class BudgetStore: ObservableObject {
    @Published var profile: BudgetProfile {
        didSet {
            save()
        }
    }

    init() {
        var profile = Self.load() ?? Self.seedProfile()
        if profile.budgetBuckets.isEmpty {
            profile.budgetBuckets = Self.starterBuckets()
        }
        if profile.incomeSources.indices.contains(0) {
            profile.incomeSources[0].paycheckItems = Self.normalizedPaycheckItems(for: profile, income: profile.incomeSources[0])
        }
        self.profile = profile
        syncRetirementBudgetLineItem()
    }

    var estimatedMonthlyInflow: Double {
        profile.incomeSources.first.map {
            TakeHomePayCalculator().estimate(profile: profile, income: $0).monthlyNetIncome
        } ?? profile.months.sorted(by: { $0.monthStart > $1.monthStart }).first?.expectedInflow ?? 0
    }

    func setAllocationShare(for bucketID: BudgetBucket.ID, to newShare: Double) {
        guard let changedIndex = profile.budgetBuckets.firstIndex(where: { $0.id == bucketID }) else { return }

        let clampedShare = min(max(newShare, 0), 1)
        let remainingShare = 1 - clampedShare
        let otherIndices = profile.budgetBuckets.indices.filter { $0 != changedIndex }
        let otherTotal = otherIndices.reduce(0) { $0 + profile.budgetBuckets[$1].allocationShare }

        profile.budgetBuckets[changedIndex].allocationShare = clampedShare

        if otherTotal > 0 {
            for index in otherIndices {
                let proportion = profile.budgetBuckets[index].allocationShare / otherTotal
                profile.budgetBuckets[index].allocationShare = remainingShare * proportion
            }
        } else {
            let evenShare = otherIndices.isEmpty ? 0 : remainingShare / Double(otherIndices.count)
            for index in otherIndices {
                profile.budgetBuckets[index].allocationShare = evenShare
            }
        }
    }

    func addLineItem(to bucketID: BudgetBucket.ID) {
        guard let bucketIndex = profile.budgetBuckets.firstIndex(where: { $0.id == bucketID }) else { return }
        profile.budgetBuckets[bucketIndex].lineItems.append(
            BudgetLineItem(name: "New item", amount: 0, timing: .recurring)
        )
    }

    func setAnnualGrossIncome(_ annualGrossIncome: Double) {
        guard profile.incomeSources.indices.contains(0) else { return }
        profile.incomeSources[0].annualGrossIncome = max(annualGrossIncome, 0)
        syncRetirementBudgetLineItem()
        syncCurrentMonthWithPlan()
    }

    func setFederalStandardDeduction(_ deduction: Double) {
        profile.federalStandardDeduction = max(deduction, 0)
        syncCurrentMonthWithPlan()
    }

    func setStateStandardDeduction(_ deduction: Double) {
        profile.stateStandardDeduction = max(deduction, 0)
        syncCurrentMonthWithPlan()
    }

    func setPaycheckItemAmount(_ amount: Double, for kind: PaycheckItemKind) {
        guard let itemIndex = paycheckItemIndex(for: kind) else { return }
        profile.incomeSources[0].paycheckItems[itemIndex].annualAmount = max(amount, 0)

        if kind == .retirement {
            profile.incomeSources[0].retirementContributionRate = profile.incomeSources[0].paycheckItems[itemIndex]
                .rate(of: profile.incomeSources[0].annualGrossIncome)
            syncRetirementBudgetLineItem()
        }

        syncCurrentMonthWithPlan()
    }

    func setPaycheckItemRate(_ rate: Double, for kind: PaycheckItemKind) {
        guard let itemIndex = paycheckItemIndex(for: kind) else { return }
        let annualGrossIncome = max(profile.incomeSources[0].annualGrossIncome, 0)
        profile.incomeSources[0].paycheckItems[itemIndex].annualAmount = annualGrossIncome * max(rate, 0)

        if kind == .retirement {
            profile.incomeSources[0].retirementContributionRate = max(rate, 0)
            syncRetirementBudgetLineItem()
        }

        syncCurrentMonthWithPlan()
    }

    func setRetirementTiming(_ timing: DeductionTiming) {
        guard let itemIndex = paycheckItemIndex(for: .retirement) else { return }
        profile.incomeSources[0].paycheckItems[itemIndex].timing = timing
        syncCurrentMonthWithPlan()
    }

    func deleteLineItems(from bucketID: BudgetBucket.ID, at offsets: IndexSet) {
        guard let bucketIndex = profile.budgetBuckets.firstIndex(where: { $0.id == bucketID }) else { return }
        profile.budgetBuckets[bucketIndex].lineItems.remove(atOffsets: offsets)
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

    private func syncRetirementBudgetLineItem() {
        guard
            let income = profile.incomeSources.first,
            let retirementItem = income.paycheckItems.first(where: { $0.kind == .retirement }),
            let bucketIndex = profile.budgetBuckets.firstIndex(where: { $0.kind == .retirement })
        else { return }

        let monthlyAmount = retirementItem.annualAmount / 12
        let systemKey = "paycheck.retirement"

        if let itemIndex = profile.budgetBuckets[bucketIndex].lineItems.firstIndex(where: { $0.systemKey == systemKey }) {
            profile.budgetBuckets[bucketIndex].lineItems[itemIndex].name = "Paycheck retirement"
            profile.budgetBuckets[bucketIndex].lineItems[itemIndex].amount = monthlyAmount
            profile.budgetBuckets[bucketIndex].lineItems[itemIndex].timing = .recurring
        } else {
            profile.budgetBuckets[bucketIndex].lineItems.insert(
                BudgetLineItem(
                    name: "Paycheck retirement",
                    amount: monthlyAmount,
                    timing: .recurring,
                    systemKey: systemKey
                ),
                at: 0
            )
        }
    }

    private func paycheckItemIndex(for kind: PaycheckItemKind) -> Int? {
        guard profile.incomeSources.indices.contains(0) else { return nil }
        return profile.incomeSources[0].paycheckItems.firstIndex { $0.kind == kind }
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
        var income = IncomeSource(
            deductions: [
                Deduction(name: "Health insurance", monthlyAmount: 220, timing: .preTax)
            ]
        )
        income.paycheckItems = normalizedPaycheckItems(for: profile, income: income)
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
        profile.budgetBuckets = starterBuckets()
        profile.months = [currentMonth]
        return profile
    }

    private static func normalizedPaycheckItems(for profile: BudgetProfile, income: IncomeSource) -> [PaycheckItem] {
        let existingItems = Dictionary(uniqueKeysWithValues: income.paycheckItems.map { ($0.kind, $0) })
        let estimator = SimpleTaxEstimator()
        let annualGrossIncome = max(income.annualGrossIncome, 0)
        let estimatedFederalTaxableIncome = max(annualGrossIncome - profile.federalStandardDeduction, 0)
        let estimatedStateTaxableIncome = max(annualGrossIncome - profile.stateStandardDeduction, 0)
        let legacyPreTaxDeductions = income.deductions
            .filter { $0.timing == .preTax }
            .reduce(0) { $0 + ($1.monthlyAmount * 12) }
        let legacyPostTaxDeductions = income.deductions
            .filter { $0.timing == .postTax }
            .reduce(0) { $0 + ($1.monthlyAmount * 12) }

        let defaults: [(PaycheckItemKind, Double, DeductionTiming)] = [
            (
                .federal,
                estimator.estimateFederalIncomeTax(taxableIncome: estimatedFederalTaxableIncome, filingStatus: profile.filingStatus),
                .postTax
            ),
            (
                .payroll,
                estimator.estimatePayrollTax(grossIncome: annualGrossIncome),
                .postTax
            ),
            (
                .state,
                estimator.estimateStateIncomeTax(taxableIncome: estimatedStateTaxableIncome, state: profile.workState),
                .postTax
            ),
            (.city, 0, .postTax),
            (.property, 0, .postTax),
            (.vehicleTax, 0, .postTax),
            (.preTaxDeductions, legacyPreTaxDeductions, .preTax),
            (.postTaxDeductions, legacyPostTaxDeductions, .postTax),
            (.retirement, annualGrossIncome * max(income.retirementContributionRate, 0), .preTax)
        ]

        return defaults.enumerated().map { index, item in
            let kind = item.0
            if var existingItem = existingItems[kind] {
                existingItem.displayOrder = index
                return existingItem
            }

            return PaycheckItem(
                kind: kind,
                annualAmount: item.1,
                timing: item.2,
                displayOrder: index
            )
        }
    }

    private static func starterBuckets() -> [BudgetBucket] {
        [
            BudgetBucket(
                kind: .essentialSpend,
                allocationShare: 0.55,
                displayOrder: 0,
                lineItems: [
                    BudgetLineItem(name: "Housing", amount: 1_800, timing: .recurring),
                    BudgetLineItem(name: "Utilities", amount: 300, timing: .recurring),
                    BudgetLineItem(name: "Food", amount: 650, timing: .recurring),
                    BudgetLineItem(name: "Transportation", amount: 450, timing: .recurring)
                ]
            ),
            BudgetBucket(
                kind: .discretionarySpend,
                allocationShare: 0.30,
                displayOrder: 1,
                lineItems: [
                    BudgetLineItem(name: "Dining and entertainment", amount: 500, timing: .recurring),
                    BudgetLineItem(name: "Shopping", amount: 250, timing: .singlePurchase)
                ]
            ),
            BudgetBucket(
                kind: .retirement,
                allocationShare: 0.15,
                displayOrder: 2,
                lineItems: [
                    BudgetLineItem(name: "Roth IRA", amount: 300, timing: .recurring),
                    BudgetLineItem(name: "Brokerage", amount: 150, timing: .recurring)
                ]
            )
        ]
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
