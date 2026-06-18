import Foundation

struct TakeHomePayEstimate {
    let annualGrossIncome: Double
    let annualPreTaxDeductions: Double
    let annualFederalTaxableIncome: Double
    let annualStateTaxableIncome: Double
    let annualFederalTax: Double
    let annualStateTax: Double
    let annualCityTax: Double
    let annualPayrollTax: Double
    let annualPropertyTax: Double
    let annualVehicleTax: Double
    let annualOtherPreTaxDeductions: Double
    let annualOtherPostTaxDeductions: Double
    let annualPostTaxDeductions: Double
    let annualRetirementContribution: Double
    let annualNetIncome: Double
    let monthlyNetIncome: Double
    let netPerPaycheck: Double
}

struct TakeHomePayCalculator {
    var taxEstimator = SimpleTaxEstimator()

    func estimate(profile: BudgetProfile, income: IncomeSource) -> TakeHomePayEstimate {
        let annualGross = max(income.annualGrossIncome, 0)
        let paycheckItems = income.paycheckItems

        func amount(for kind: PaycheckItemKind) -> Double? {
            paycheckItems.first { $0.kind == kind }.map { max($0.annualAmount, 0) }
        }

        let annualRetirement = amount(for: .retirement) ?? annualGross * max(income.retirementContributionRate, 0)

        let annualPreTax = paycheckItems
            .filter { $0.timing == .preTax }
            .reduce(0) { $0 + max($1.annualAmount, 0) }
        let annualPostTax = paycheckItems
            .filter { $0.timing == .postTax }
            .reduce(0) { $0 + max($1.annualAmount, 0) }

        let federalTaxableIncome = max(annualGross - annualPreTax - profile.federalStandardDeduction, 0)
        let stateTaxableIncome = max(annualGross - annualPreTax - profile.stateStandardDeduction, 0)

        let federalTax = amount(for: .federal)
            ?? taxEstimator.estimateFederalIncomeTax(taxableIncome: federalTaxableIncome, filingStatus: profile.filingStatus)
        let stateTax = amount(for: .state)
            ?? taxEstimator.estimateStateIncomeTax(taxableIncome: stateTaxableIncome, state: profile.workState)
        let payrollTax = amount(for: .payroll)
            ?? taxEstimator.estimatePayrollTax(grossIncome: annualGross)
        let cityTax = amount(for: .city) ?? 0
        let propertyTax = amount(for: .property) ?? 0
        let vehicleTax = amount(for: .vehicleTax) ?? 0
        let otherPreTaxDeductions = amount(for: .preTaxDeductions) ?? 0
        let otherPostTaxDeductions = amount(for: .postTaxDeductions) ?? 0

        let annualNet = max(annualGross - annualPreTax - annualPostTax, 0)

        return TakeHomePayEstimate(
            annualGrossIncome: annualGross,
            annualPreTaxDeductions: annualPreTax,
            annualFederalTaxableIncome: federalTaxableIncome,
            annualStateTaxableIncome: stateTaxableIncome,
            annualFederalTax: federalTax,
            annualStateTax: stateTax,
            annualCityTax: cityTax,
            annualPayrollTax: payrollTax,
            annualPropertyTax: propertyTax,
            annualVehicleTax: vehicleTax,
            annualOtherPreTaxDeductions: otherPreTaxDeductions,
            annualOtherPostTaxDeductions: otherPostTaxDeductions,
            annualPostTaxDeductions: annualPostTax,
            annualRetirementContribution: annualRetirement,
            annualNetIncome: annualNet,
            monthlyNetIncome: annualNet / 12,
            netPerPaycheck: annualNet / income.payFrequency.periodsPerYear
        )
    }
}
