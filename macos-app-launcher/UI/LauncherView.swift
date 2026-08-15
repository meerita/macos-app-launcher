import SwiftUI

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel

    var body: some View {
        VStack(spacing: 0) {
            SearchFieldView(
                text: $viewModel.query,
                onMoveUp: viewModel.selectPreviousResult,
                onMoveDown: viewModel.selectNextResult,
                onSubmit: viewModel.launchSelectedResult,
                onCancel: {
                    viewModel.dismissLauncher?()
                }
            )
            .frame(height: 72)

            Divider()
                .opacity(0.55)

            VStack(spacing: 2) {
                ForEach(viewModel.results) { result in
                    ApplicationRow(
                        result: result,
                        icon: viewModel.icon(for: result.application),
                        isSelected: viewModel.isSelected(result)
                    )
                }
            }
            .padding(.vertical, 7)
        }
        .frame(width: 660)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}
