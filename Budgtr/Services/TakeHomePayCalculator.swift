import Foundation

struct TakeHomePayEstimate {
    let annualGrossIncome: Double
    let annualPreTaxDeductions: Double
    let annualTaxableIncome: Double
    let annualFederalTax: Double
    let annualStateTax: Double
    let annualPayrollTax: Double
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
        let annualRetirement = annualGross * max(income.retirementContributionRate, 0)
        let annualPreTax = income.deductions
            .filter { $0.timing == .preTax }
            .reduce(annualRetirement) { $0 + ($1.monthlyAmount * 12) }
        let annualPostTax = income.deductions
            .filter { $0.timing == .postTax }
            .reduce(0) { $0 + ($1.monthlyAmount * 12) }
        let taxableIncome = max(annualGross - annualPreTax, 0)
        let federalTax = taxEstimator.estimateFederalIncomeTax(
            taxableIncome: taxableIncome,
            filingStatus: profile.filingStatus
        )
        let stateTax = taxEstimator.estimateStateIncomeTax(
            taxableIncome: taxableIncome,
            state: profile.workState
        )
        let payrollTax = taxEstimator.estimatePayrollTax(grossIncome: annualGross)
        let annualNet = max(annualGross - annualPreTax - federalTax - stateTax - payrollTax - annualPostTax, 0)

        return TakeHomePayEstimate(
            annualGrossIncome: annualGross,
            annualPreTaxDeductions: annualPreTax,
            annualTaxableIncome: taxableIncome,
            annualFederalTax: federalTax,
            annualStateTax: stateTax,
            annualPayrollTax: payrollTax,
            annualPostTaxDeductions: annualPostTax,
            annualRetirementContribution: annualRetirement,
            annualNetIncome: annualNet,
            monthlyNetIncome: annualNet / 12,
            netPerPaycheck: annualNet / income.payFrequency.periodsPerYear
        )
    }
}

