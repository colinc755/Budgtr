import Foundation

enum MoneyFormatting {
    static let currency: FloatingPointFormatStyle<Double>.Currency = .currency(code: Locale.current.currency?.identifier ?? "USD")

    static let percent: FloatingPointFormatStyle<Double>.Percent = .percent.precision(.fractionLength(0...1))
}

