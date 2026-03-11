import SwiftUI

// Experimental upper-bound Liquid Glass backdrop for the feature branch.
// This intentionally exaggerates depth and translucency so the team can
// judge the maximum plausible Apple-style direction before scaling back.
struct LiquidGlassBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    Color(red: 0.86, green: 0.93, blue: 1.0).opacity(0.8),
                    Color(red: 0.95, green: 0.9, blue: 1.0).opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -160, y: -230)

            Circle()
                .fill(Color.cyan.opacity(0.24))
                .frame(width: 300, height: 300)
                .blur(radius: 72)
                .offset(x: 170, y: -150)

            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 82)
                .offset(x: -140, y: 250)

            Circle()
                .fill(Color.white.opacity(0.26))
                .frame(width: 240, height: 240)
                .blur(radius: 58)
                .offset(x: 200, y: 240)
        }
        .ignoresSafeArea()
    }
}

struct CardGroup<Content: View>: View {
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
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04),
                                Color.blue.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.12),
                            Color.cyan.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.15
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 6
                )
        }
        .shadow(color: Color.white.opacity(0.22), radius: 10, y: -2)
        .shadow(color: Color.black.opacity(0.12), radius: 24, y: 14)
    }
}

struct GlassChromePanel<Content: View>: View {
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
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0.05),
                                    Color.cyan.opacity(0.06)
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
                                Color.white.opacity(0.56),
                                Color.white.opacity(0.12),
                                Color.cyan.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 5)
                    .blur(radius: 8)
                    .mask(alignment: .top) {
                        Rectangle()
                            .frame(height: 42)
                    }
            }
            .shadow(color: Color.white.opacity(0.24), radius: 12, y: -2)
            .shadow(color: Color.black.opacity(0.14), radius: 26, y: 14)
    }
}

struct ChromeActionIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.primary)
            .frame(width: 44, height: 40)
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
                            Color.white.opacity(0.56),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.1
                )
        }
        .shadow(color: Color.black.opacity(0.12), radius: 14, y: 8)
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
                        .fill(Color.white.opacity(0.08))
                }
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.05
                    )
            }
            .shadow(color: Color.white.opacity(0.16), radius: 6, y: -1)
            .shadow(color: Color.black.opacity(0.1), radius: 10, y: 6)
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

extension View {
    // Experimental upper-bound Liquid Glass input styling for the branch.
    // Centralized here so all typed and Scribble-friendly text surfaces can
    // share one consistent treatment during the exploration pass.
    func liquidGlassInput(cornerRadius: CGFloat = 14) -> some View {
        textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.05
                    )
            }
            .shadow(color: Color.white.opacity(0.12), radius: 5, y: -1)
            .shadow(color: Color.black.opacity(0.08), radius: 10, y: 6)
    }

    func liquidGlassInputBackground(cornerRadius: CGFloat = 14) -> some View {
        scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.05
                    )
            }
            .shadow(color: Color.white.opacity(0.12), radius: 5, y: -1)
            .shadow(color: Color.black.opacity(0.08), radius: 10, y: 6)
    }

    func liquidGlassSurface(cornerRadius: CGFloat = 14) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.05
                )
        }
        .shadow(color: Color.white.opacity(0.12), radius: 5, y: -1)
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 6)
    }
}
