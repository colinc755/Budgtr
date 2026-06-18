import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: BudgetStore

    private var income: IncomeSource? {
        store.profile.incomeSources.first
    }

    private var currentMonth: BudgetMonth? {
        store.profile.months.sorted { $0.monthStart > $1.monthStart }.first
    }

    private var estimate: TakeHomePayEstimate? {
        guard let income else { return nil }
        return TakeHomePayCalculator().estimate(profile: store.profile, income: income)
    }

    private var monthlyInflow: Double {
        estimate?.monthlyNetIncome ?? currentMonth?.expectedInflow ?? 0
    }

    private var totalAllocated: Double {
        store.profile.budgetBuckets.reduce(0) { $0 + $1.allocatedAmount(from: monthlyInflow) }
    }

    private var totalPlanned: Double {
        store.profile.budgetBuckets.reduce(0) { $0 + $1.plannedSpend }
    }

    private var totalRemaining: Double {
        monthlyInflow - totalPlanned
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let estimate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Monthly Take-Home")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(estimate.monthlyNetIncome, format: MoneyFormatting.currency)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text("\(estimate.netPerPaycheck, format: MoneyFormatting.currency) per paycheck")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(spacing: 12) {
                        MetricTile(title: "Allocated", amount: totalAllocated)
                        MetricTile(title: "Planned", amount: totalPlanned)
                        MetricTile(title: "Remaining", amount: totalRemaining)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Month")
                            .font(.headline)

                        ForEach(store.profile.budgetBuckets.sorted { $0.displayOrder < $1.displayOrder }) { bucket in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(bucket.kind.displayName)
                                    Spacer()
                                    Text(bucket.remainingAmount(from: monthlyInflow), format: MoneyFormatting.currency)
                                        .foregroundStyle(bucket.remainingAmount(from: monthlyInflow) >= 0 ? Color.primary : Color.red)
                                }

                                ProgressView(value: min(max(bucket.plannedSpend / max(bucket.allocatedAmount(from: monthlyInflow), 1), 0), 1))
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.quaternary)
                    )
                }
                .padding()
            }
            .navigationTitle("Budgtr")
        }
    }
}

private struct MetricTile: View {
    let title: String
    let amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(amount, format: MoneyFormatting.currency)
                .font(.headline)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        )
    }
}
