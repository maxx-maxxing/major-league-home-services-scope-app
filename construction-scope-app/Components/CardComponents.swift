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
                    Color.white.opacity(0.9),
                    Color(uiColor: .secondarySystemGroupedBackground).opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Keep accent color underneath the glass as a faint substrate so
            // surfaces stay neutral while refraction feels slightly deeper.
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.045),
                    Color.clear,
                    Color.accentColor.opacity(0.025)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(0.08))
                .frame(width: 360, height: 360)
                .blur(radius: 110)
                .offset(x: -185, y: -210)

            Circle()
                .fill(Color.accentColor.opacity(0.045))
                .frame(width: 260, height: 260)
                .blur(radius: 96)
                .offset(x: 220, y: 265)

            Circle()
                .fill(Color.white.opacity(0.46))
                .frame(width: 340, height: 340)
                .blur(radius: 88)
                .offset(x: -170, y: -250)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 82)
                .offset(x: 180, y: -140)

            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 88)
                .offset(x: -130, y: 280)

            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 210, y: 250)
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
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.025),
                                Color.black.opacity(0.015)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.3))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.04),
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
                            Color.white.opacity(0.05)
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
                                    Color.white.opacity(0.24),
                                    Color.white.opacity(0.08),
                                    Color.black.opacity(0.015)
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
                                Color.white.opacity(0.36),
                                Color.white.opacity(0.08),
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
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 4)
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

extension View {
    // Experimental upper-bound Liquid Glass input styling for the branch.
    // Centralized here so all typed and Scribble-friendly text surfaces can
    // share one consistent treatment during the exploration pass.
    func liquidGlassInput(cornerRadius: CGFloat = 14) -> some View {
        textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(0.035))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.05),
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
                    .strokeBorder(Color.white.opacity(0.11), lineWidth: 2)
                    .blur(radius: 4)
                    .mask {
                        Rectangle()
                            .frame(height: 16)
                    }
            }
    }

    func liquidGlassInputBackground(cornerRadius: CGFloat = 14) -> some View {
        scrollContentBackground(.hidden)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor.opacity(0.03))
                }
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.05),
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
                    .strokeBorder(Color.white.opacity(0.11), lineWidth: 2)
                    .blur(radius: 4)
                    .mask {
                        Rectangle()
                            .frame(height: 16)
                    }
            }
    }

    func liquidGlassSurface(cornerRadius: CGFloat = 14) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.038))
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(0.028))
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.05),
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
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 2)
                .blur(radius: 4)
                .mask {
                    Rectangle()
                        .frame(height: 16)
                }
        }
    }
}
