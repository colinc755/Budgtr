import Foundation

struct SimpleTaxEstimator {
    func estimateFederalIncomeTax(taxableIncome: Double, filingStatus: FilingStatus) -> Double {
        let standardDeduction = standardDeduction(for: filingStatus)
        let bracketIncome = max(taxableIncome - standardDeduction, 0)
        let brackets = federalBrackets(for: filingStatus)

        var remainingIncome = bracketIncome
        var lowerBound = 0.0
        var tax = 0.0

        for bracket in brackets {
            let upperBound = bracket.upperBound
            let taxableAtRate = min(remainingIncome, upperBound - lowerBound)
            if taxableAtRate > 0 {
                tax += taxableAtRate * bracket.rate
                remainingIncome -= taxableAtRate
            }
            lowerBound = upperBound
            if remainingIncome <= 0 { break }
        }

        return max(tax, 0)
    }

    func estimateStateIncomeTax(taxableIncome: Double, state: String) -> Double {
        let normalizedState = state.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let noIncomeTaxStates = ["AK", "FL", "NV", "NH", "SD", "TN", "TX", "WA", "WY"]
        if noIncomeTaxStates.contains(normalizedState) {
            return 0
        }

        return max(taxableIncome, 0) * 0.045
    }

    func estimatePayrollTax(grossIncome: Double) -> Double {
        let socialSecurityWageBase = 168_600.0
        let socialSecurityTax = min(max(grossIncome, 0), socialSecurityWageBase) * 0.062
        let medicareTax = max(grossIncome, 0) * 0.0145
        return socialSecurityTax + medicareTax
    }

    private func standardDeduction(for filingStatus: FilingStatus) -> Double {
        switch filingStatus {
        case .single: 14_600
        case .marriedJointly: 29_200
        case .headOfHousehold: 21_900
        }
    }

    private func federalBrackets(for filingStatus: FilingStatus) -> [TaxBracket] {
        switch filingStatus {
        case .single:
            [
                TaxBracket(upperBound: 11_600, rate: 0.10),
                TaxBracket(upperBound: 47_150, rate: 0.12),
                TaxBracket(upperBound: 100_525, rate: 0.22),
                TaxBracket(upperBound: 191_950, rate: 0.24),
                TaxBracket(upperBound: 243_725, rate: 0.32),
                TaxBracket(upperBound: 609_350, rate: 0.35),
                TaxBracket(upperBound: .greatestFiniteMagnitude, rate: 0.37)
            ]
        case .marriedJointly:
            [
                TaxBracket(upperBound: 23_200, rate: 0.10),
                TaxBracket(upperBound: 94_300, rate: 0.12),
                TaxBracket(upperBound: 201_050, rate: 0.22),
                TaxBracket(upperBound: 383_900, rate: 0.24),
                TaxBracket(upperBound: 487_450, rate: 0.32),
                TaxBracket(upperBound: 731_200, rate: 0.35),
                TaxBracket(upperBound: .greatestFiniteMagnitude, rate: 0.37)
            ]
        case .headOfHousehold:
            [
                TaxBracket(upperBound: 16_550, rate: 0.10),
                TaxBracket(upperBound: 63_100, rate: 0.12),
                TaxBracket(upperBound: 100_500, rate: 0.22),
                TaxBracket(upperBound: 191_950, rate: 0.24),
                TaxBracket(upperBound: 243_700, rate: 0.32),
                TaxBracket(upperBound: 609_350, rate: 0.35),
                TaxBracket(upperBound: .greatestFiniteMagnitude, rate: 0.37)
            ]
        }
    }
}

private struct TaxBracket {
    let upperBound: Double
    let rate: Double
}

