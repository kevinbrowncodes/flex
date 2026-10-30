import SwiftUI

/// The shipping app icon: a liquid-glass lifter on a black background.
/// Rendered to the asset catalog by `scripts/generate-app-icon.sh`; keep this file free of iOS-only APIs
/// so the macOS render script can compile it.
struct FlexLiquidGlassIcon: View {
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 180
    
    var maxSize: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Near-black background with a faint gradient so the glass figure still reads as lit
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(
                    .linearGradient(
                        colors: [
                            Color(red: 0.17, green: 0.17, blue: 0.18),
                            Color(red: 0.0, green: 0.0, blue: 0.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Translucent glass layers
            ZStack {
                // Outer glow layer
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.85, weight: .bold))
                    .foregroundStyle(.white.opacity(0.15))
                    .blur(radius: 30)
                    .offset(y: 8)
                
                // Middle translucent layer
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.82, weight: .bold))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.3),
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 1)
                    .offset(y: 4)
                
                // Main glass layer with refraction
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.78, weight: .bold))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .white.opacity(0.85),
                                .white.opacity(0.65),
                                .white.opacity(0.45)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 15)
                
                // Top specular highlight (wet glass look)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.78, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .mask(
                        LinearGradient(
                            colors: [.black, .clear, .clear, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.overlay)
                
                // Edge lighting (refraction effect)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.78, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .mask(
                        LinearGradient(
                            colors: [.clear, .clear, .black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.softLight)
            }
            
            // Surface gloss overlay
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(
                    .radialGradient(
                        colors: [.white.opacity(0.4), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: iconSize * 0.8
                    )
                )
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}
