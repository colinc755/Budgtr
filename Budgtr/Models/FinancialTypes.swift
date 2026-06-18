import Foundation

enum PayFrequency: String, CaseIterable, Identifiable, Codable {
    case weekly
    case biweekly
    case semimonthly
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: "Weekly"
        case .biweekly: "Biweekly"
        case .semimonthly: "Twice monthly"
        case .monthly: "Monthly"
        }
    }

    var periodsPerYear: Double {
        switch self {
        case .weekly: 52
        case .biweekly: 26
        case .semimonthly: 24
        case .monthly: 12
        }
    }
}

enum FilingStatus: String, CaseIterable, Identifiable, Codable {
    case single
    case marriedJointly
    case headOfHousehold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: "Single"
        case .marriedJointly: "Married filing jointly"
        case .headOfHousehold: "Head of household"
        }
    }
}

enum DeductionTiming: String, CaseIterable, Identifiable, Codable {
    case preTax
    case postTax

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preTax: "Pre-tax"
        case .postTax: "Post-tax"
        }
    }
}

enum CarryoverRule: String, CaseIterable, Identifiable, Codable {
    case none
    case positiveOnly
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "No carryover"
        case .positiveOnly: "Unused only"
        case .full: "Surplus and shortfall"
        }
    }
}

enum BudgetCategoryKind: String, CaseIterable, Identifiable, Codable {
    case essential
    case discretionary
    case savings
    case retirement
    case debt
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .essential: "Essential"
        case .discretionary: "Discretionary"
        case .savings: "Savings"
        case .retirement: "Retirement"
        case .debt: "Debt"
        case .other: "Other"
        }
    }
}

enum BudgetBucketKind: String, CaseIterable, Identifiable, Codable {
    case essentialSpend
    case discretionarySpend
    case retirement

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .essentialSpend: "Essential Spend"
        case .discretionarySpend: "Discretionary Spend"
        case .retirement: "Retirement"
        }
    }
}

enum BudgetLineItemTiming: String, CaseIterable, Identifiable, Codable {
    case recurring
    case singlePurchase

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recurring: "Recurring"
        case .singlePurchase: "Single Purchase"
        }
    }
}

enum PaycheckItemKind: String, CaseIterable, Identifiable, Codable {
    case federal
    case payroll
    case state
    case city
    case property
    case vehicleTax
    case preTaxDeductions
    case postTaxDeductions
    case retirement

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .federal: "Federal"
        case .payroll: "Payroll"
        case .state: "State"
        case .city: "City Tax"
        case .property: "Property"
        case .vehicleTax: "Vehicle Tax"
        case .preTaxDeductions: "Pre-Tax Deductions"
        case .postTaxDeductions: "Post-Tax Deductions"
        case .retirement: "Retirement"
        }
    }

    var defaultTiming: DeductionTiming {
        switch self {
        case .preTaxDeductions, .retirement:
            .preTax
        case .federal, .payroll, .state, .city, .property, .vehicleTax, .postTaxDeductions:
            .postTax
        }
    }
}
