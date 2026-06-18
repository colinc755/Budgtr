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

