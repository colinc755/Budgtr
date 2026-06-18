import Foundation

struct BudgetProfile: Identifiable, Codable {
    var id: UUID
    var name: String
    var workState: String
    var filingStatusRaw: String
    var createdAt: Date
    var incomeSources: [IncomeSource]
    var categories: [BudgetCategory]
    var months: [BudgetMonth]

    init(
        id: UUID = UUID(),
        name: String = "My Budget",
        workState: String = "TX",
        filingStatus: FilingStatus = .single,
        createdAt: Date = .now,
        incomeSources: [IncomeSource] = [],
        categories: [BudgetCategory] = [],
        months: [BudgetMonth] = []
    ) {
        self.id = id
        self.name = name
        self.workState = workState
        self.filingStatusRaw = filingStatus.rawValue
        self.createdAt = createdAt
        self.incomeSources = incomeSources
        self.categories = categories
        self.months = months
    }

    var filingStatus: FilingStatus {
        get { FilingStatus(rawValue: filingStatusRaw) ?? .single }
        set { filingStatusRaw = newValue.rawValue }
    }
}

struct IncomeSource: Identifiable, Codable {
    var id: UUID
    var name: String
    var annualGrossIncome: Double
    var payFrequencyRaw: String
    var retirementContributionRate: Double
    var createdAt: Date
    var deductions: [Deduction]

    init(
        id: UUID = UUID(),
        name: String = "Primary income",
        annualGrossIncome: Double = 90_000,
        payFrequency: PayFrequency = .biweekly,
        retirementContributionRate: Double = 0.06,
        createdAt: Date = .now,
        deductions: [Deduction] = []
    ) {
        self.id = id
        self.name = name
        self.annualGrossIncome = annualGrossIncome
        self.payFrequencyRaw = payFrequency.rawValue
        self.retirementContributionRate = retirementContributionRate
        self.createdAt = createdAt
        self.deductions = deductions
    }

    var payFrequency: PayFrequency {
        get { PayFrequency(rawValue: payFrequencyRaw) ?? .biweekly }
        set { payFrequencyRaw = newValue.rawValue }
    }
}

struct Deduction: Identifiable, Codable {
    var id: UUID
    var name: String
    var monthlyAmount: Double
    var timingRaw: String

    init(id: UUID = UUID(), name: String, monthlyAmount: Double, timing: DeductionTiming = .preTax) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.timingRaw = timing.rawValue
    }

    var timing: DeductionTiming {
        get { DeductionTiming(rawValue: timingRaw) ?? .preTax }
        set { timingRaw = newValue.rawValue }
    }
}

struct BudgetCategory: Identifiable, Codable {
    var id: UUID
    var name: String
    var kindRaw: String
    var monthlyAllocation: Double
    var carryoverRuleRaw: String
    var displayOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        kind: BudgetCategoryKind,
        monthlyAllocation: Double,
        carryoverRule: CarryoverRule = .positiveOnly,
        displayOrder: Int
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.monthlyAllocation = monthlyAllocation
        self.carryoverRuleRaw = carryoverRule.rawValue
        self.displayOrder = displayOrder
    }

    var kind: BudgetCategoryKind {
        get { BudgetCategoryKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var carryoverRule: CarryoverRule {
        get { CarryoverRule(rawValue: carryoverRuleRaw) ?? .positiveOnly }
        set { carryoverRuleRaw = newValue.rawValue }
    }
}

struct BudgetMonth: Identifiable, Codable {
    var id: UUID
    var monthStart: Date
    var expectedInflow: Double
    var allocations: [CategoryAllocation]

    init(id: UUID = UUID(), monthStart: Date, expectedInflow: Double, allocations: [CategoryAllocation] = []) {
        self.id = id
        self.monthStart = monthStart
        self.expectedInflow = expectedInflow
        self.allocations = allocations
    }
}

struct CategoryAllocation: Identifiable, Codable {
    var id: UUID
    var categoryName: String
    var categoryKindRaw: String
    var plannedAmount: Double
    var usedAmount: Double
    var carryoverAmount: Double
    var carryoverRuleRaw: String

    init(
        id: UUID = UUID(),
        categoryName: String,
        categoryKind: BudgetCategoryKind,
        plannedAmount: Double,
        usedAmount: Double = 0,
        carryoverAmount: Double = 0,
        carryoverRule: CarryoverRule = .positiveOnly
    ) {
        self.id = id
        self.categoryName = categoryName
        self.categoryKindRaw = categoryKind.rawValue
        self.plannedAmount = plannedAmount
        self.usedAmount = usedAmount
        self.carryoverAmount = carryoverAmount
        self.carryoverRuleRaw = carryoverRule.rawValue
    }

    var availableAmount: Double {
        plannedAmount + carryoverAmount
    }

    var remainingAmount: Double {
        availableAmount - usedAmount
    }

    var categoryKind: BudgetCategoryKind {
        get { BudgetCategoryKind(rawValue: categoryKindRaw) ?? .other }
        set { categoryKindRaw = newValue.rawValue }
    }

    var carryoverRule: CarryoverRule {
        get { CarryoverRule(rawValue: carryoverRuleRaw) ?? .positiveOnly }
        set { carryoverRuleRaw = newValue.rawValue }
    }
}

