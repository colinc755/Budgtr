import Foundation

struct BudgetProfile: Identifiable, Codable {
    var id: UUID
    var name: String
    var workState: String
    var filingStatusRaw: String
    var federalStandardDeduction: Double
    var stateStandardDeduction: Double
    var createdAt: Date
    var incomeSources: [IncomeSource]
    var categories: [BudgetCategory]
    var budgetBuckets: [BudgetBucket]
    var months: [BudgetMonth]

    init(
        id: UUID = UUID(),
        name: String = "My Budget",
        workState: String = "TX",
        filingStatus: FilingStatus = .single,
        federalStandardDeduction: Double = 14_600,
        stateStandardDeduction: Double = 0,
        createdAt: Date = .now,
        incomeSources: [IncomeSource] = [],
        categories: [BudgetCategory] = [],
        budgetBuckets: [BudgetBucket] = [],
        months: [BudgetMonth] = []
    ) {
        self.id = id
        self.name = name
        self.workState = workState
        self.filingStatusRaw = filingStatus.rawValue
        self.federalStandardDeduction = federalStandardDeduction
        self.stateStandardDeduction = stateStandardDeduction
        self.createdAt = createdAt
        self.incomeSources = incomeSources
        self.categories = categories
        self.budgetBuckets = budgetBuckets
        self.months = months
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case workState
        case filingStatusRaw
        case federalStandardDeduction
        case stateStandardDeduction
        case createdAt
        case incomeSources
        case categories
        case budgetBuckets
        case months
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.workState = try container.decode(String.self, forKey: .workState)
        self.filingStatusRaw = try container.decode(String.self, forKey: .filingStatusRaw)
        self.federalStandardDeduction = try container.decodeIfPresent(Double.self, forKey: .federalStandardDeduction) ?? 14_600
        self.stateStandardDeduction = try container.decodeIfPresent(Double.self, forKey: .stateStandardDeduction) ?? 0
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.incomeSources = try container.decode([IncomeSource].self, forKey: .incomeSources)
        self.categories = try container.decode([BudgetCategory].self, forKey: .categories)
        self.budgetBuckets = try container.decodeIfPresent([BudgetBucket].self, forKey: .budgetBuckets) ?? []
        self.months = try container.decode([BudgetMonth].self, forKey: .months)
    }

    var filingStatus: FilingStatus {
        get { FilingStatus(rawValue: filingStatusRaw) ?? .single }
        set { filingStatusRaw = newValue.rawValue }
    }
}

struct BudgetBucket: Identifiable, Codable {
    var id: UUID
    var kindRaw: String
    var allocationShare: Double
    var displayOrder: Int
    var lineItems: [BudgetLineItem]

    init(
        id: UUID = UUID(),
        kind: BudgetBucketKind,
        allocationShare: Double,
        displayOrder: Int,
        lineItems: [BudgetLineItem] = []
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.allocationShare = allocationShare
        self.displayOrder = displayOrder
        self.lineItems = lineItems
    }

    var kind: BudgetBucketKind {
        get { BudgetBucketKind(rawValue: kindRaw) ?? .essentialSpend }
        set { kindRaw = newValue.rawValue }
    }

    func allocatedAmount(from monthlyInflow: Double) -> Double {
        monthlyInflow * allocationShare
    }

    var plannedSpend: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    func remainingAmount(from monthlyInflow: Double) -> Double {
        allocatedAmount(from: monthlyInflow) - plannedSpend
    }
}

struct BudgetLineItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var amount: Double
    var timingRaw: String
    var createdAt: Date
    var systemKey: String?

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        timing: BudgetLineItemTiming = .recurring,
        createdAt: Date = .now,
        systemKey: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.timingRaw = timing.rawValue
        self.createdAt = createdAt
        self.systemKey = systemKey
    }

    var timing: BudgetLineItemTiming {
        get { BudgetLineItemTiming(rawValue: timingRaw) ?? .recurring }
        set { timingRaw = newValue.rawValue }
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
    var paycheckItems: [PaycheckItem]

    init(
        id: UUID = UUID(),
        name: String = "Primary income",
        annualGrossIncome: Double = 90_000,
        payFrequency: PayFrequency = .biweekly,
        retirementContributionRate: Double = 0.06,
        createdAt: Date = .now,
        deductions: [Deduction] = [],
        paycheckItems: [PaycheckItem] = []
    ) {
        self.id = id
        self.name = name
        self.annualGrossIncome = annualGrossIncome
        self.payFrequencyRaw = payFrequency.rawValue
        self.retirementContributionRate = retirementContributionRate
        self.createdAt = createdAt
        self.deductions = deductions
        self.paycheckItems = paycheckItems
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case annualGrossIncome
        case payFrequencyRaw
        case retirementContributionRate
        case createdAt
        case deductions
        case paycheckItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.annualGrossIncome = try container.decode(Double.self, forKey: .annualGrossIncome)
        self.payFrequencyRaw = try container.decode(String.self, forKey: .payFrequencyRaw)
        self.retirementContributionRate = try container.decode(Double.self, forKey: .retirementContributionRate)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.deductions = try container.decode([Deduction].self, forKey: .deductions)
        self.paycheckItems = try container.decodeIfPresent([PaycheckItem].self, forKey: .paycheckItems) ?? []
    }

    var payFrequency: PayFrequency {
        get { PayFrequency(rawValue: payFrequencyRaw) ?? .biweekly }
        set { payFrequencyRaw = newValue.rawValue }
    }
}

struct PaycheckItem: Identifiable, Codable {
    var id: UUID
    var kindRaw: String
    var annualAmount: Double
    var timingRaw: String
    var displayOrder: Int

    init(
        id: UUID = UUID(),
        kind: PaycheckItemKind,
        annualAmount: Double,
        timing: DeductionTiming? = nil,
        displayOrder: Int
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.annualAmount = annualAmount
        self.timingRaw = (timing ?? kind.defaultTiming).rawValue
        self.displayOrder = displayOrder
    }

    var kind: PaycheckItemKind {
        get { PaycheckItemKind(rawValue: kindRaw) ?? .federal }
        set { kindRaw = newValue.rawValue }
    }

    var timing: DeductionTiming {
        get { DeductionTiming(rawValue: timingRaw) ?? kind.defaultTiming }
        set { timingRaw = newValue.rawValue }
    }

    func rate(of annualGrossIncome: Double) -> Double {
        guard annualGrossIncome > 0 else { return 0 }
        return annualAmount / annualGrossIncome
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
