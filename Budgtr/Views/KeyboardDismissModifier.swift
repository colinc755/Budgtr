import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnBackgroundTap() -> some View {
        background(KeyboardDismissGestureInstaller())
    }
}

private struct KeyboardDismissGestureInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        installGestureIfPossible(from: view, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        installGestureIfPossible(from: view, coordinator: context.coordinator)
    }

    private func installGestureIfPossible(from view: UIView, coordinator: Coordinator) {
        DispatchQueue.main.async {
            guard let window = view.window, coordinator.installedWindow !== window else { return }

            let recognizer = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.dismissKeyboard))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = coordinator
            window.addGestureRecognizer(recognizer)

            coordinator.installedWindow = window
            coordinator.recognizer = recognizer
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var installedWindow: UIWindow?
        weak var recognizer: UITapGestureRecognizer?

        @objc func dismissKeyboard() {
            installedWindow?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var touchedView: UIView? = touch.view
            while let view = touchedView {
                if view is UIControl {
                    return false
                }
                touchedView = view.superview
            }
            return true
        }
    }
}

