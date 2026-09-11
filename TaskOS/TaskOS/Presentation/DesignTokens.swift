import SwiftUI

enum TaskOSSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum TaskOSRadius {
    static let control: CGFloat = 10
    static let card: CGFloat = 12
    static let composer: CGFloat = 14
}

enum TaskOSMetrics {
    static let sidebarMin: CGFloat = 200
    static let sidebarIdeal: CGFloat = 235
    static let editorMin: CGFloat = 420
    static let inspectorMin: CGFloat = 280
    static let inspectorIdeal: CGFloat = 320
    static let windowMinWidth: CGFloat = 640
    static let windowMinHeight: CGFloat = 560
}

extension Animation {
    static let taskOSStandard = Animation.easeInOut(duration: 0.2)
    static let taskOSQuick = Animation.easeOut(duration: 0.15)
    static let taskOSSlow = Animation.easeInOut(duration: 0.25)
}

struct TaskOSCardModifier: ViewModifier {
    var isSelected: Bool
    var isHovered: Bool
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color(nsColor: .separatorColor),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.07 : 0.03),
                radius: isHovered ? 6 : 2,
                y: 1
            )
            .animation(.taskOSQuick, value: isHovered)
            .animation(.taskOSQuick, value: isSelected)
    }
}

extension View {
    func taskOSCard(
        isSelected: Bool = false,
        isHovered: Bool = false,
        cornerRadius: CGFloat = TaskOSRadius.card
    ) -> some View {
        modifier(TaskOSCardModifier(isSelected: isSelected, isHovered: isHovered, cornerRadius: cornerRadius))
    }
}

struct TaskOSCard<Content: View>: View {
    var isSelected: Bool = false
    var padding: CGFloat = TaskOSSpacing.sm
    @ViewBuilder var content: () -> Content

    @State private var isHovered = false

    var body: some View {
        content()
            .padding(padding)
            .taskOSCard(isSelected: isSelected, isHovered: isHovered)
            .onHover { isHovered = $0 }
    }
}

struct TaskOSSectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: TaskOSSpacing.xs) {
            Text(title)
                .font(.headline)
            Spacer(minLength: TaskOSSpacing.xs)
            trailing()
        }
    }
}

extension TaskOSSectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title) { EmptyView() }
    }
}

struct TaskOSStatusChip: View {
    let text: String
    var systemImage: String?
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct TaskOSEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

extension View {
    func taskOSFieldChrome() -> some View {
        padding(.horizontal, TaskOSSpacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                    .fill(.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TaskOSRadius.control, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
            )
    }
}
