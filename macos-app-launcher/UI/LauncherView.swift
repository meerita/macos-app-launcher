import SwiftUI

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel
    @ObservedObject var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme

    private let contentWidth: CGFloat = 660

    var body: some View {
        VStack(spacing: 0) {
            searchField

            if !viewModel.results.isEmpty {
                Divider()
                    .opacity(0.55)

                resultsList
            }
        }
        .frame(width: contentWidth)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .preferredColorScheme(settings.appearanceMode.colorScheme)
            .accessibilityElement(children: .contain)
    }

    private var searchField: some View {
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
    }

    private var resultsList: some View {
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

}
