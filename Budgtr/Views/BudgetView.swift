import SwiftUI

struct BudgetView: View {
    @ObservedObject var store: BudgetStore

    private var currentMonth: BudgetMonth? {
        store.profile.months.sorted { $0.monthStart > $1.monthStart }.first
    }

    private var sortedCategories: [BudgetCategory] {
        store.profile.categories.sorted { $0.displayOrder < $1.displayOrder }
    }

    private var unallocated: Double {
        let inflow = currentMonth?.expectedInflow ?? 0
        let planned = sortedCategories.reduce(0) { $0 + $1.monthlyAllocation }
        return inflow - planned
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Monthly inflow")
                        Spacer()
                        Text((currentMonth?.expectedInflow ?? 0), format: MoneyFormatting.currency)
                    }

                    HStack {
                        Text("Unallocated")
                        Spacer()
                        Text(unallocated, format: MoneyFormatting.currency)
                            .foregroundStyle(unallocated >= 0 ? Color.secondary : Color.red)
                    }
                }

                Section("Categories") {
                    ForEach($store.profile.categories) { $category in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(category.name)
                                    .font(.headline)
                                Spacer()
                                Text(category.kind.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            HStack {
                                Text("Monthly")
                                Spacer()
                                TextField("Amount", value: $category.monthlyAllocation, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 120)
                            }

                            Picker("Carryover", selection: $category.carryoverRuleRaw) {
                                ForEach(CarryoverRule.allCases) { rule in
                                    Text(rule.displayName).tag(rule.rawValue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if currentMonth != nil {
                    Section {
                        Button {
                            store.createNextMonth()
                        } label: {
                            Label("Create Next Month", systemImage: "calendar.badge.plus")
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
}
