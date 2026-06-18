import SwiftUI

struct BudgetView: View {
    @ObservedObject var store: BudgetStore

    private var monthlyInflow: Double {
        store.estimatedMonthlyInflow
    }

    private var totalPlanned: Double {
        store.profile.budgetBuckets.reduce(0) { $0 + $1.plannedSpend }
    }

    private var totalRemaining: Double {
        monthlyInflow - totalPlanned
    }

    private var sortedBuckets: [BudgetBucket] {
        store.profile.budgetBuckets.sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BudgetSummaryRow(title: "Monthly take-home", amount: monthlyInflow)
                    BudgetSummaryRow(title: "Line items", amount: totalPlanned)
                    BudgetSummaryRow(title: "Unplanned", amount: totalRemaining, isWarning: totalRemaining < 0)
                }

                Section("Allocation") {
                    ForEach(sortedBuckets) { bucket in
                        allocationControl(for: bucket)
                    }
                }

                Section("Buckets") {
                    ForEach(sortedBuckets) { bucket in
                        if let binding = binding(for: bucket.id) {
                            BudgetBucketSection(
                                bucket: binding,
                                monthlyInflow: monthlyInflow,
                                onAddItem: {
                                    store.addLineItem(to: bucket.id)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Budget")
            .onDisappear {
                store.syncCurrentMonthWithPlan()
            }
        }
    }

    private func allocationControl(for bucket: BudgetBucket) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bucket.kind.displayName)
                    .font(.headline)
                Spacer()
                Text(bucket.allocationShare, format: MoneyFormatting.percent)
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { bucket.allocationShare },
                    set: { store.setAllocationShare(for: bucket.id, to: $0) }
                ),
                in: 0...1,
                step: 0.01
            )

            HStack {
                Text(bucket.allocatedAmount(from: monthlyInflow), format: MoneyFormatting.currency)
                Spacer()
                Text("allocated")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func binding(for bucketID: BudgetBucket.ID) -> Binding<BudgetBucket>? {
        guard let index = store.profile.budgetBuckets.firstIndex(where: { $0.id == bucketID }) else {
            return nil
        }
        return $store.profile.budgetBuckets[index]
    }
}

private struct BudgetBucketSection: View {
    @Binding var bucket: BudgetBucket
    let monthlyInflow: Double
    let onAddItem: () -> Void

    private var allocatedAmount: Double {
        bucket.allocatedAmount(from: monthlyInflow)
    }

    private var remainingAmount: Double {
        bucket.remainingAmount(from: monthlyInflow)
    }

    var body: some View {
        DisclosureGroup {
            if bucket.lineItems.isEmpty {
                Text("No line items")
                    .foregroundStyle(.secondary)
            }

            ForEach($bucket.lineItems) { $item in
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Name", text: $item.name)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("Amount", value: $item.amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }

                    Picker("Timing", selection: $item.timingRaw) {
                        ForEach(BudgetLineItemTiming.allCases) { timing in
                            Text(timing.displayName).tag(timing.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 6)
            }
            .onDelete { offsets in
                bucket.lineItems.remove(atOffsets: offsets)
            }

            Button(action: onAddItem) {
                Label("Add Line Item", systemImage: "plus.circle.fill")
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(bucket.kind.displayName)
                        .font(.headline)
                    Spacer()
                    Text(remainingAmount, format: MoneyFormatting.currency)
                        .foregroundStyle(remainingAmount >= 0 ? Color.secondary : Color.red)
                }

                HStack {
                    Text("\(allocatedAmount, format: MoneyFormatting.currency) allocated")
                    Spacer()
                    Text("\(bucket.plannedSpend, format: MoneyFormatting.currency) planned")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                ProgressView(value: min(max(bucket.plannedSpend / max(allocatedAmount, 1), 0), 1))
            }
            .padding(.vertical, 4)
        }
    }
}

private struct BudgetSummaryRow: View {
    let title: String
    let amount: Double
    var isWarning = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(amount, format: MoneyFormatting.currency)
                .foregroundStyle(isWarning ? Color.red : Color.secondary)
        }
    }
}
