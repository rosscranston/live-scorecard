import SwiftUI

struct ThemePalette {
    let background: Color
    let surface: Color
    let raised: Color
    let primary: Color
    let secondary: Color
    let faint: Color
    let border: Color
    let green: Color
    let blue: Color
    let orange: Color
    let red: Color

    init(theme: AppTheme) {
        switch theme {
        case .dark:
            background = .black
            surface = Color.white.opacity(0.045)
            raised = Color(red: 0.07, green: 0.08, blue: 0.08)
            primary = Color.white.opacity(0.92)
            secondary = Color.white.opacity(0.56)
            faint = Color.white.opacity(0.34)
            border = Color.white.opacity(0.15)
            green = Color(red: 0.33, green: 1.0, blue: 0.57)
            blue = Color(red: 0.42, green: 0.72, blue: 1.0)
            orange = Color(red: 1.0, green: 0.67, blue: 0.26)
            red = Color(red: 1.0, green: 0.39, blue: 0.39)
        case .light:
            background = Color(red: 0.965, green: 0.96, blue: 0.94)
            surface = Color.black.opacity(0.035)
            raised = .white
            primary = Color.black.opacity(0.88)
            secondary = Color.black.opacity(0.57)
            faint = Color.black.opacity(0.36)
            border = Color.black.opacity(0.16)
            green = Color(red: 0.02, green: 0.48, blue: 0.24)
            blue = Color(red: 0.08, green: 0.36, blue: 0.73)
            orange = Color(red: 0.72, green: 0.34, blue: 0.02)
            red = Color(red: 0.72, green: 0.10, blue: 0.10)
        }
    }
}

struct CompactOutlineButtonStyle: ButtonStyle {
    let accent: Color
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(filled ? Color.black : accent)
            .padding(.horizontal, 7)
            .frame(minHeight: 23)
            .background(filled ? accent : Color.clear)
            .overlay { Rectangle().stroke(accent.opacity(0.85), lineWidth: 1) }
            .opacity(configuration.isPressed ? 0.58 : 1)
            .contentShape(Rectangle())
    }
}

struct BareRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(configuration.isPressed ? Color.primary.opacity(0.07) : Color.clear)
    }
}

struct PanelBox<Content: View>: View {
    let palette: ThemePalette
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(8)
            .background(palette.surface)
            .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
    }
}

struct SectionLabel: View {
    let text: String
    let palette: ThemePalette

    init(_ text: String, palette: ThemePalette) {
        self.text = text
        self.palette = palette
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(palette.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 3)
    }
}

struct TagChip: View {
    let text: String
    let selected: Bool
    let palette: ThemePalette

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
            .lineLimit(1)
            .foregroundStyle(selected ? Color.black : palette.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(selected ? palette.green : palette.surface)
            .overlay { Rectangle().stroke(selected ? palette.green : palette.border, lineWidth: 1) }
    }
}

struct StateBadge: View {
    let state: StudyState
    let palette: ThemePalette

    var color: Color {
        switch state {
        case .notStarted: return palette.faint
        case .needsReview: return palette.orange
        case .memorized: return palette.green
        }
    }

    var body: some View {
        Text(state.label)
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .overlay { Rectangle().stroke(color.opacity(0.75), lineWidth: 1) }
    }
}

struct StatCell: View {
    let value: Int
    let label: String
    let color: Color
    let palette: ThemePalette

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label.uppercased())
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(palette.faint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompactDivider: View {
    let palette: ThemePalette
    var body: some View { Rectangle().fill(palette.border).frame(height: 1) }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
