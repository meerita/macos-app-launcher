import AppKit
import SwiftUI

struct ApplicationRow: View {
    let result: SearchResult
    let icon: NSImage
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            Text(result.application.name)
                .font(.system(size: 17, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 12)
        }
        .frame(height: 52)
        .padding(.horizontal, 18)
        .background(selectionBackground)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.08), value: isSelected)
        .accessibilityLabel(result.application.name)
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.18))
                .padding(.horizontal, 8)
        } else {
            Color.clear
        }
    }
}
