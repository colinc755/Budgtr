import SwiftUI

struct IncomeView: View {
    @ObservedObject var store: BudgetStore

    private var income: IncomeSource {
        store.profile.incomeSources.first ?? IncomeSource()
    }

    private var estimate: TakeHomePayEstimate {
        TakeHomePayCalculator().estimate(profile: store.profile, income: income)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Income") {
                    TextField("Annual salary", value: $store.profile.incomeSources[0].annualGrossIncome, format: .number)
                        .keyboardType(.decimalPad)

                    Picker("Pay frequency", selection: $store.profile.incomeSources[0].payFrequencyRaw) {
                        ForEach(PayFrequency.allCases) { frequency in
                            Text(frequency.displayName).tag(frequency.rawValue)
                        }
                    }

                    Picker("Filing status", selection: $store.profile.filingStatusRaw) {
                        ForEach(FilingStatus.allCases) { status in
                            Text(status.displayName).tag(status.rawValue)
                        }
                    }

                    TextField("Work state", text: $store.profile.workState)
                        .textInputAutocapitalization(.characters)

                    HStack {
                        Text("Retirement")
                        Spacer()
                        TextField("Retirement", value: $store.profile.incomeSources[0].retirementContributionRate, format: .percent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }

                Section("Estimate") {
                    EstimateRow(title: "Gross income", amount: estimate.annualGrossIncome)
                    EstimateRow(title: "Pre-tax deductions", amount: estimate.annualPreTaxDeductions)
                    EstimateRow(title: "Federal tax", amount: estimate.annualFederalTax)
                    EstimateRow(title: "State tax", amount: estimate.annualStateTax)
                    EstimateRow(title: "Payroll tax", amount: estimate.annualPayrollTax)
                    EstimateRow(title: "Monthly take-home", amount: estimate.monthlyNetIncome)
                    EstimateRow(title: "Per paycheck", amount: estimate.netPerPaycheck)
                }
            }
            .navigationTitle("Income")
            .onDisappear {
                store.syncCurrentMonthWithPlan()
            }
        }
    }
}

private struct EstimateRow: View {
    let title: String
    let amount: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(amount, format: MoneyFormatting.currency)
                .foregroundStyle(.secondary)
        }
    }
}
