import SwiftUI

struct IncomeView: View {
    @ObservedObject var store: BudgetStore

    private var income: IncomeSource {
        store.profile.incomeSources.first ?? IncomeSource()
    }

    private var paycheckItems: [PaycheckItem] {
        income.paycheckItems.sorted { $0.displayOrder < $1.displayOrder }
    }

    private var estimate: TakeHomePayEstimate {
        TakeHomePayCalculator().estimate(profile: store.profile, income: income)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Income") {
                    TextField(
                        "Annual salary",
                        value: Binding(
                            get: { income.annualGrossIncome },
                            set: { store.setAnnualGrossIncome($0) }
                        ),
                        format: .number
                    )
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
                }

                Section("Standard Deductions") {
                    TextField(
                        "Federal standard deduction",
                        value: Binding(
                            get: { store.profile.federalStandardDeduction },
                            set: { store.setFederalStandardDeduction($0) }
                        ),
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    TextField(
                        "State standard deduction",
                        value: Binding(
                            get: { store.profile.stateStandardDeduction },
                            set: { store.setStateStandardDeduction($0) }
                        ),
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    EstimateRow(title: "Federal taxable income", amount: estimate.annualFederalTaxableIncome)
                    EstimateRow(title: "State taxable income", amount: estimate.annualStateTaxableIncome)
                }

                Section("Paycheck Items") {
                    ForEach(paycheckItems) { item in
                        PaycheckItemRow(
                            item: item,
                            annualGrossIncome: income.annualGrossIncome,
                            amount: Binding(
                                get: { currentItem(for: item.kind)?.annualAmount ?? 0 },
                                set: { store.setPaycheckItemAmount($0, for: item.kind) }
                            ),
                            percent: Binding(
                                get: { (currentItem(for: item.kind)?.rate(of: income.annualGrossIncome) ?? 0) * 100 },
                                set: { store.setPaycheckItemRate($0 / 100, for: item.kind) }
                            ),
                            retirementTiming: Binding(
                                get: { currentItem(for: .retirement)?.timingRaw ?? DeductionTiming.preTax.rawValue },
                                set: { store.setRetirementTiming(DeductionTiming(rawValue: $0) ?? .preTax) }
                            )
                        )
                    }
                }

                Section("Estimate") {
                    EstimateRow(title: "Gross income", amount: estimate.annualGrossIncome)
                    EstimateRow(title: "Pre-tax deductions", amount: estimate.annualPreTaxDeductions)
                    EstimateRow(title: "Federal tax", amount: estimate.annualFederalTax)
                    EstimateRow(title: "State tax", amount: estimate.annualStateTax)
                    EstimateRow(title: "City tax", amount: estimate.annualCityTax)
                    EstimateRow(title: "Payroll tax", amount: estimate.annualPayrollTax)
                    EstimateRow(title: "Property tax", amount: estimate.annualPropertyTax)
                    EstimateRow(title: "Vehicle tax", amount: estimate.annualVehicleTax)
                    EstimateRow(title: "Post-tax deductions", amount: estimate.annualOtherPostTaxDeductions)
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

    private func currentItem(for kind: PaycheckItemKind) -> PaycheckItem? {
        store.profile.incomeSources.first?.paycheckItems.first { $0.kind == kind }
    }
}

private struct PaycheckItemRow: View {
    let item: PaycheckItem
    let annualGrossIncome: Double
    @Binding var amount: Double
    @Binding var percent: Double
    @Binding var retirementTiming: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.kind.displayName)
                    .font(.headline)
                Spacer()
                Text(amount / 12, format: MoneyFormatting.currency)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Percent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Percent", value: $percent, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Annual value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Value", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
            }

            if item.kind == .retirement {
                Picker("Tax treatment", selection: $retirementTiming) {
                    Text("Pre-tax").tag(DeductionTiming.preTax.rawValue)
                    Text("Post-tax").tag(DeductionTiming.postTax.rawValue)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.vertical, 6)
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
