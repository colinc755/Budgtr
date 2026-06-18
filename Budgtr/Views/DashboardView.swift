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

    private var totalAllocated: Double {
        currentMonth?.allocations.reduce(0) { $0 + $1.plannedAmount } ?? 0
    }

    private var totalUsed: Double {
        currentMonth?.allocations.reduce(0) { $0 + $1.usedAmount } ?? 0
    }

    private var totalRemaining: Double {
        currentMonth?.allocations.reduce(0) { $0 + $1.remainingAmount } ?? 0
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
                        MetricTile(title: "Used", amount: totalUsed)
                        MetricTile(title: "Remaining", amount: totalRemaining)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Month")
                            .font(.headline)

                        ForEach((currentMonth?.allocations ?? []).sorted { $0.categoryName < $1.categoryName }) { allocation in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(allocation.categoryName)
                                    Spacer()
                                    Text(allocation.remainingAmount, format: MoneyFormatting.currency)
                                        .foregroundStyle(allocation.remainingAmount >= 0 ? Color.primary : Color.red)
                                }

                                ProgressView(value: min(max(allocation.usedAmount / max(allocation.availableAmount, 1), 0), 1))
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
