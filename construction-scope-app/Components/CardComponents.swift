import SwiftUI

// Experimental upper-bound Liquid Glass backdrop for the feature branch.
// This intentionally exaggerates depth and translucency so the team can
// judge the maximum plausible Apple-style direction before scaling back.
struct LiquidGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    colorScheme == .dark
                        ? Color.white.opacity(0.9)
                        : Color(uiColor: .secondarySystemGroupedBackground),
                    colorScheme == .dark
                        ? Color(uiColor: .secondarySystemGroupedBackground).opacity(0.96)
                        : Color(uiColor: .tertiarySystemGroupedBackground).opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Keep accent color underneath the glass as a faint substrate so
            // surfaces stay neutral while refraction feels slightly deeper.
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(colorScheme == .dark ? 0.045 : 0.03),
                    Color.clear,
                    Color.accentColor.opacity(colorScheme == .dark ? 0.025 : 0.016)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.08 : 0.05))
                .frame(width: 360, height: 360)
                .blur(radius: 110)
                .offset(x: -185, y: -210)

            Circle()
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.045 : 0.025))
                .frame(width: 260, height: 260)
                .blur(radius: 96)
                .offset(x: 220, y: 265)

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.46 : 0.24))
                .frame(width: 340, height: 340)
                .blur(radius: 88)
                .offset(x: -170, y: -250)

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 82)
                .offset(x: 180, y: -140)

            Circle()
                .fill(Color.black.opacity(colorScheme == .dark ? 0.05 : 0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 88)
                .offset(x: -130, y: 280)

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.22 : 0.1))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 210, y: 250)
        }
        .ignoresSafeArea()
    }
}

struct CardGroup<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            content
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.13),
                                Color.white.opacity(colorScheme == .dark ? 0.025 : 0.05),
                                Color.black.opacity(colorScheme == .dark ? 0.015 : 0.028)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(colorScheme == .dark ? 0.3 : 0.46))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.14 : 0.24),
                                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.09)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        }
        .shadow(color: Color.black.opacity(0.03), radius: 6, y: 3)
    }
}

struct GlassChromePanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    @ViewBuilder var content: Content

    init(cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.24 : 0.18),
                                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.05),
                                    Color.black.opacity(colorScheme == .dark ? 0.015 : 0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.36 : 0.28),
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.11),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.12), lineWidth: 4)
                    .blur(radius: 8)
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(height: 42)
                    }
            }
            .shadow(color: Color.white.opacity(0.08), radius: 4, y: -1)
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 7)
    }
}

struct ChromeActionIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.primary)
            .frame(width: 40, height: 36)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct GlassToolbarGap: View {
    var body: some View {
        Color.clear
            .frame(width: 8, height: 1)
    }
}

struct GlassToolbarCluster<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 4) {
            content
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.32),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .overlay(alignment: .top) {
            Capsule()
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 3)
                .blur(radius: 6)
                .mask {
                    Rectangle()
                        .frame(height: 18)
                }
        }
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 5)
    }
}

struct StatusPill: View {
    let status: JobStatus

    var body: some View {
        Text(status.displayName)
            .font(.footnote)
            .foregroundStyle(.primary)
            .contentTransition(.opacity)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                }
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 3)
                    .blur(radius: 6)
                    .mask {
                        Rectangle()
                            .frame(height: 18)
                    }
            }
            .shadow(color: Color.white.opacity(0.04), radius: 2, y: -1)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
            .accessibilityLabel("Status \(status.displayName)")
    }
}

struct RequiredLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.body)
            Text("*")
                .foregroundStyle(.red)
                .font(.body)
        }
    }
}

struct LabeledTextField: View {
    let title: String
    let prompt: String
    @Binding var text: String
    let helperText: String?
    let isRequired: Bool

    init(
        _ title: String,
        text: Binding<String>,
        prompt: String? = nil,
        helperText: String? = nil,
        isRequired: Bool = false
    ) {
        self.title = title
        self.prompt = prompt ?? title
        self._text = text
        self.helperText = helperText
        self.isRequired = isRequired
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isRequired {
                RequiredLabel(text: title)
            } else {
                Text(title)
                    .font(.body)
            }

            TextField(prompt, text: $text)
                .liquidGlassInput()

            if let helperText {
                Text(helperText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct LiquidGlassInputModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.012 : 0.028))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.035 : 0.02))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.26),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.09),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.11 : 0.16), lineWidth: 2)
                    .blur(radius: 4)
                    .mask {
                        Rectangle()
                            .frame(height: 16)
                    }
            }
    }
}

private struct LiquidGlassInputBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.012 : 0.026))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.03 : 0.018))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.26),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.09),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.11 : 0.16), lineWidth: 2)
                    .blur(radius: 4)
                    .mask {
                        Rectangle()
                            .frame(height: 16)
                    }
            }
    }
}

private struct LiquidGlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.038 : 0.07))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(colorScheme == .dark ? 0.01 : 0.024))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.028 : 0.016))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.18 : 0.24),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.14), lineWidth: 2)
                    .blur(radius: 4)
                    .mask {
                        Rectangle()
                            .frame(height: 16)
                    }
            }
    }
}

extension View {
    // Experimental upper-bound Liquid Glass input styling for the branch.
    // Centralized here so all typed and Scribble-friendly text surfaces can
    // share one consistent treatment during the exploration pass.
    func liquidGlassInput(cornerRadius: CGFloat = 14) -> some View {
        modifier(LiquidGlassInputModifier(cornerRadius: cornerRadius))
    }

    func liquidGlassInputBackground(cornerRadius: CGFloat = 14) -> some View {
        modifier(LiquidGlassInputBackgroundModifier(cornerRadius: cornerRadius))
    }

    func liquidGlassSurface(cornerRadius: CGFloat = 14) -> some View {
        modifier(LiquidGlassSurfaceModifier(cornerRadius: cornerRadius))
    }
}
