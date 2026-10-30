#if DEBUG
import SwiftUI

// App Icon Generator - Apple-Style Translucent Glass Design
struct ProgrammaticIcon: View {
    // Safe area padding to prevent cropping
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 200 // Padding from edges including shadows
    
    var maxWidth: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Vibrant gradient background
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.47, blue: 1.0),
                        Color(red: 0.5, green: 0.2, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Translucent glass dumbbell - layered like Podcasts/Home
            ZStack {
                // Back layer - larger, more transparent
                HStack(spacing: 0) {
                    // Left weight
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(.white.opacity(0.25))
                        .frame(width: maxWidth * 0.22, height: maxWidth * 0.42)
                    
                    // Center bar
                    Rectangle()
                        .fill(.white.opacity(0.25))
                        .frame(width: maxWidth * 0.29, height: maxWidth * 0.048)
                    
                    // Right weight
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(.white.opacity(0.25))
                        .frame(width: maxWidth * 0.22, height: maxWidth * 0.42)
                }
                .blur(radius: 1)
                .offset(y: 8)
                
                // Middle layer
                HStack(spacing: 0) {
                    // Left weight
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.35))
                        .frame(width: maxWidth * 0.19, height: maxWidth * 0.37)
                    
                    // Center bar
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(width: maxWidth * 0.26, height: maxWidth * 0.042)
                    
                    // Right weight
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.35))
                        .frame(width: maxWidth * 0.19, height: maxWidth * 0.37)
                }
                .blur(radius: 0.5)
                .offset(y: 4)
                
                // Front layer - brightest
                HStack(spacing: 0) {
                    // Left weight
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.white.opacity(0.5))
                        .frame(width: maxWidth * 0.16, height: maxWidth * 0.32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.linearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .blendMode(.overlay)
                        }
                    
                    // Center bar
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(width: maxWidth * 0.22, height: maxWidth * 0.035)
                        .overlay {
                            Rectangle()
                                .fill(.linearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .blendMode(.overlay)
                        }
                    
                    // Right weight
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.white.opacity(0.5))
                        .frame(width: maxWidth * 0.16, height: maxWidth * 0.32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.linearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .blendMode(.overlay)
                        }
                }
                .shadow(color: .black.opacity(0.3), radius: 25, x: 0, y: 12)
            }
            
            // Top gloss overlay
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [.white.opacity(0.25), .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                ))
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Alternative Design - Activity Rings Style
struct AlternativeIcon: View {
    // Safe area padding to prevent cropping (same as main design)
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 250 // Maximum padding to ensure fit
    
    var maxDiameter: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Vibrant gradient background
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.47, blue: 1.0),
                        Color(red: 0.5, green: 0.2, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Concentric translucent rings - like Activity app
            ZStack {
                // Outer ring - cyan
                Circle()
                    .strokeBorder(.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    .frame(width: maxDiameter * 0.75, height: maxDiameter * 0.75)
                    .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 0)
                
                // Middle ring - mint
                Circle()
                    .strokeBorder(.mint.opacity(0.7), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    .frame(width: maxDiameter * 0.54, height: maxDiameter * 0.54)
                    .shadow(color: .mint.opacity(0.3), radius: 10, x: 0, y: 0)
                
                // Inner ring - white
                Circle()
                    .strokeBorder(.white.opacity(0.8), style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    .frame(width: maxDiameter * 0.33, height: maxDiameter * 0.33)
                    .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 0)
                
                // Center icon - strength symbol
                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: maxDiameter * 0.14)
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            
            // Top gloss overlay
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [.white.opacity(0.25), .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                ))
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Third Design - Minimalist Gradient Circle
struct MinimalistIcon: View {
    // Same anti-cropping logic
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 250
    
    var maxDiameter: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Vibrant gradient background
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.47, blue: 1.0),
                        Color(red: 0.5, green: 0.2, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Large translucent circle - simple and bold
            ZStack {
                // Glow layer
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: maxDiameter * 0.85, height: maxDiameter * 0.85)
                    .blur(radius: 40)
                
                // Main glass circle
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: maxDiameter * 0.7, height: maxDiameter * 0.7)
                    .overlay {
                        Circle()
                            .fill(.linearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .blendMode(.overlay)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
                
                // Bold symbol
                Image(systemName: "dumbbell.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: maxDiameter * 0.35)
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            // Top gloss overlay
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [.white.opacity(0.25), .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                ))
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Apple-Style Bold Icon - Fits with iOS App Icons
struct AppleStyleIcon: View {
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 250
    
    var maxSize: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Clean gradient background - like Mail or FaceTime
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.5, blue: 1.0),
                        Color(red: 0.4, green: 0.3, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            
            // Simple, bold white dumbbell
            ZStack {
                // Barbell bar
                Capsule()
                    .fill(.white)
                    .frame(width: maxSize * 0.55, height: maxSize * 0.08)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                
                // Left weight
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .frame(width: maxSize * 0.18, height: maxSize * 0.38)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .offset(x: -maxSize * 0.27)
                
                // Right weight
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .frame(width: maxSize * 0.18, height: maxSize * 0.38)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .offset(x: maxSize * 0.27)
            }
            
            // Subtle top shine
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [.white.opacity(0.2), .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                ))
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Flex - Refined Apple-Quality Icon
struct FlexIcon: View {
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 250
    
    var maxSize: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Vibrant gradient like FaceTime/Mail
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.45, blue: 0.0),
                        Color(red: 0.95, green: 0.2, blue: 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Translucent glass dumbbell with depth - like Podcasts/Mail
            ZStack {
                // Back shadow layer
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.15))
                        .frame(width: maxSize * 0.16, height: maxSize * 0.35)
                    Rectangle()
                        .fill(.white.opacity(0.15))
                        .frame(width: maxSize * 0.2, height: maxSize * 0.065)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.15))
                        .frame(width: maxSize * 0.16, height: maxSize * 0.35)
                }
                .blur(radius: 2)
                .offset(y: 8)
                
                // Main glass layer
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.85))
                        .frame(width: maxSize * 0.14, height: maxSize * 0.32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.linearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .blendMode(.overlay)
                        }
                    
                    Capsule()
                        .fill(.white.opacity(0.85))
                        .frame(width: maxSize * 0.18, height: maxSize * 0.06)
                        .overlay {
                            Capsule()
                                .fill(.linearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .blendMode(.overlay)
                        }
                    
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.85))
                        .frame(width: maxSize * 0.14, height: maxSize * 0.32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.linearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .blendMode(.overlay)
                        }
                }
                .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
            }
            
            // Top gloss
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [.white.opacity(0.3), .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                ))
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Home App Style Icon - Layered Glass House
struct HomeStyleIcon: View {
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 230
    
    var maxSize: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Clean white/light background like Home app
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(Color(red: 0.98, green: 0.98, blue: 0.985))
            
            // Layered translucent house - Home app style
            ZStack {
                // Outer layer - largest
                HomeShape(cornerRadius: 48, chimneySize: 52)
                    .fill(.linearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.55, blue: 0.15),
                            Color(red: 0.98, green: 0.75, blue: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: maxSize * 0.85, height: maxSize * 0.85)
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 18)
                
                // Second layer
                HomeShape(cornerRadius: 44, chimneySize: 46)
                    .fill(.linearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.60, blue: 0.18),
                            Color(red: 0.99, green: 0.78, blue: 0.38)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: maxSize * 0.70, height: maxSize * 0.70)
                
                // Third layer
                HomeShape(cornerRadius: 38, chimneySize: 38)
                    .fill(.linearGradient(
                        colors: [
                            Color(red: 0.99, green: 0.68, blue: 0.22),
                            Color(red: 1.0, green: 0.83, blue: 0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: maxSize * 0.56, height: maxSize * 0.56)
                
                // Inner layer - brightest, smallest
                HomeShape(cornerRadius: 32, chimneySize: 30)
                    .fill(.linearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.78, blue: 0.38),
                            Color(red: 1.0, green: 0.90, blue: 0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: maxSize * 0.42, height: maxSize * 0.42)
                    .overlay {
                        HomeShape(cornerRadius: 32, chimneySize: 30)
                            .fill(.linearGradient(
                                colors: [.white.opacity(0.6), .clear],
                                startPoint: .top,
                                endPoint: .center
                            ))
                            .blendMode(.overlay)
                            .frame(width: maxSize * 0.42, height: maxSize * 0.42)
                    }
            }
            
            // Subtle top gloss
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.linearGradient(
                    colors: [.white.opacity(0.35), .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                ))
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Liquid Flex Icon
struct LiquidFlexIcon: View {
    let iconSize: CGFloat = 1024
    var cornerRadius: CGFloat { iconSize * 0.2237 }

    var body: some View {
        ZStack {
            // 1. The "Fluid" Background (Mesh-like gradient)
            ZStack {
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.2, blue: 0.1)) // Deep Orange base
                
                // Fluid blobs to create the "liquid" container feel
                Circle()
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.3)) // Hot Pink
                    .frame(width: iconSize * 0.8)
                    .offset(x: -iconSize * 0.3, y: -iconSize * 0.3)
                    .blur(radius: iconSize * 0.15)
                
                Circle()
                    .fill(Color(red: 1.0, green: 0.6, blue: 0.0)) // Gold
                    .frame(width: iconSize * 0.7)
                    .offset(x: iconSize * 0.3, y: iconSize * 0.2)
                    .blur(radius: iconSize * 0.1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

            // 2. The Liquid Icon Layer
            ZStack {
                // A. The "Water" Body (Darker, richer fill to simulate density)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: iconSize * 0.5, weight: .black))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.white.opacity(0.1), .white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    // "Hard Light" makes it look like it's blending into the fluid
                    .blendMode(.hardLight)
                
                // B. The "Wet" Specular Highlight (The most important part for Liquid)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: iconSize * 0.5, weight: .black))
                    .foregroundStyle(.white.opacity(0.9)) // Very bright
                    .mask(
                        // We use a gradient mask to cut the icon so it looks like light hitting a curve
                        LinearGradient(
                            colors: [.black, .clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: -2, y: -2) // Slight offset for 3D feel
                
                // C. The "Refraction" Edge (Bottom rim lighting)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: iconSize * 0.5, weight: .black))
                    .foregroundStyle(.white.opacity(0.4))
                    .mask(
                        // Edge lighting effect using gradient mask
                        LinearGradient(
                            colors: [.clear, .clear, .black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 5, y: 10) // Drop shadow creates the "floating" effect
            }

            // 3. Surface Gloss (The "Bubble" Reflection)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .mask(
                    // Cut a "swoosh" shape for the reflection
                    Circle()
                        .frame(width: iconSize * 1.5, height: iconSize * 1.5)
                        .offset(x: -iconSize * 0.4, y: -iconSize * 0.6)
                )
                .blendMode(.overlay)
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Flex Emoji Icon - Black Background with Bicep
struct FlexEmojiIcon: View {
    let iconSize: CGFloat = 1024
    let safePadding: CGFloat = 320
    
    var maxSize: CGFloat {
        iconSize - (safePadding * 2)
    }
    
    var body: some View {
        ZStack {
            // Black background
            RoundedRectangle(cornerRadius: 60, style: .continuous)
                .fill(.black)
            
            // Use SF Symbol for better result
            ZStack {
                // Shadow
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.55, weight: .bold))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.15, blue: 0.1),
                                Color(red: 0.1, green: 0.05, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: 6, y: 10)
                    .blur(radius: 8)
                
                // Main symbol with skin tone gradient
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.55, weight: .bold))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.80, blue: 0.60),  // Light skin
                                Color(red: 0.88, green: 0.68, blue: 0.48),  // Mid tone
                                Color(red: 0.75, green: 0.55, blue: 0.40)   // Shadow
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Top highlight for dimension
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: maxSize * 0.55, weight: .bold))
                    .foregroundStyle(
                        .radialGradient(
                            colors: [.white.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: maxSize * 0.35
                        )
                    )
                    .blendMode(.overlay)
            }
        }
        .frame(width: iconSize, height: iconSize)
    }
}

// Flex Liquid Glass Icon - Apple's Modern Design Philosophy
// Custom House Shape for Home Icon
struct HomeShape: Shape {
    let cornerRadius: CGFloat
    let chimneySize: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        
        // Roof height (top triangle portion)
        let roofHeight = height * 0.38
        let bodyTop = roofHeight
        
        // Chimney dimensions
        let chimneyWidth = chimneySize * 0.6
        let chimneyHeight = chimneySize
        let chimneyRight = width * 0.73
        let chimneyLeft = chimneyRight - chimneyWidth
        let chimneyTop = roofHeight * 0.35
        
        // Start at top center (peak of roof)
        path.move(to: CGPoint(x: centerX, y: 0))
        
        // Right side of roof going down to chimney
        path.addLine(to: CGPoint(x: chimneyLeft, y: chimneyTop))
        
        // Chimney outline (going up and around)
        path.addLine(to: CGPoint(x: chimneyLeft, y: chimneyTop - chimneyHeight + cornerRadius * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: chimneyLeft + cornerRadius * 0.3, y: chimneyTop - chimneyHeight),
            control: CGPoint(x: chimneyLeft, y: chimneyTop - chimneyHeight)
        )
        path.addLine(to: CGPoint(x: chimneyRight - cornerRadius * 0.3, y: chimneyTop - chimneyHeight))
        path.addQuadCurve(
            to: CGPoint(x: chimneyRight, y: chimneyTop - chimneyHeight + cornerRadius * 0.3),
            control: CGPoint(x: chimneyRight, y: chimneyTop - chimneyHeight)
        )
        path.addLine(to: CGPoint(x: chimneyRight, y: chimneyTop))
        
        // Continue right side of roof
        path.addLine(to: CGPoint(x: width, y: bodyTop))
        
        // Right side of house body
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
        
        // Bottom right corner
        path.addQuadCurve(
            to: CGPoint(x: width - cornerRadius, y: height),
            control: CGPoint(x: width, y: height)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: height))
        
        // Bottom left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height - cornerRadius),
            control: CGPoint(x: 0, y: height)
        )
        
        // Left side of house body
        path.addLine(to: CGPoint(x: 0, y: bodyTop))
        
        // Left side of roof back to peak
        path.addLine(to: CGPoint(x: centerX, y: 0))
        
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Icon Generator View with Export
struct IconGeneratorView: View {
    @State private var selectedIcon: IconType = .programmatic
    
    enum IconType: String, CaseIterable {
        case programmatic = "Translucent Dumbbell"
        case alternative = "Activity Rings"
        case minimalist = "Minimalist Circle"
        case appleStyle = "Apple Style"
        case flex = "Flex - Orange"
        case homeStyle = "Home Style"
        case liquidFlex = "Liquid Flex"
        case flexEmoji = "Flex Emoji 💪"
        case liquidGlass = "Liquid Glass"
        
        @ViewBuilder
        var icon: some View {
            switch self {
            case .programmatic:
                ProgrammaticIcon()
            case .alternative:
                AlternativeIcon()
            case .minimalist:
                MinimalistIcon()
            case .appleStyle:
                AppleStyleIcon()
            case .flex:
                FlexIcon()
            case .homeStyle:
                HomeStyleIcon()
            case .liquidFlex:
                LiquidFlexIcon()
            case .flexEmoji:
                FlexEmojiIcon()
            case .liquidGlass:
                FlexLiquidGlassIcon()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon Preview
                    selectedIcon.icon
                        .frame(width: 300, height: 300)
                        .cornerRadius(60)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Icon Selector
                    Picker("Icon Style", selection: $selectedIcon) {
                        ForEach(IconType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    
                    // Export Button
                    #if os(iOS)
                    ShareLink(
                        item: Image(uiImage: generateSnapshot()),
                        preview: SharePreview(
                            "\(selectedIcon.rawValue) Icon",
                            image: Image(uiImage: generateSnapshot())
                        )
                    ) {
                        Label("Export 1024×1024 Icon", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    #else
                    Button {
                        saveImageToFile()
                    } label: {
                        Label("Export 1024×1024 Icon", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    #endif
                    
                    VStack(spacing: 8) {
                        #if os(iOS)
                        Text("Tap to save to Files or AirDrop to your Mac")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        #else
                        Text("Icon will be saved to Downloads folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        #endif
                        
                        Text("The icon will be exported at 1024×1024px")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("App Icon Generator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    #if os(iOS)
    @MainActor
    private func generateSnapshot() -> UIImage {
        let renderer = ImageRenderer(content: selectedIcon.icon)
        renderer.scale = 1.0
        
        if let image = renderer.uiImage {
            return image
        }
        return UIImage()
    }
    #else
    @MainActor
    private func saveImageToFile() {
        let renderer = ImageRenderer(content: selectedIcon.icon)
        renderer.scale = 1.0
        
        guard let nsImage = renderer.nsImage else { return }
        
        // Convert to PNG data
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }
        
        // Save to Downloads folder
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileName = "\(selectedIcon.rawValue)-Icon-1024x1024.png"
        let fileURL = downloadsURL.appendingPathComponent(fileName)
        
        do {
            try pngData.write(to: fileURL)
            print("Icon saved to: \(fileURL.path)")
        } catch {
            print("Error saving icon: \(error)")
        }
    }
    #endif
}

#Preview("Icon Generator") {
    IconGeneratorView()
}

#Preview("Translucent Dumbbell") {
    ProgrammaticIcon()
}

#Preview("Activity Rings") {
    AlternativeIcon()
}

#Preview("Minimalist Circle") {
    MinimalistIcon()
}

#Preview("Apple Style") {
    AppleStyleIcon()
}

#Preview("Flex - Bicep") {
    FlexIcon()
}

#Preview("Home Style") {
    HomeStyleIcon()
}

#Preview("Liquid Flex") {
    LiquidFlexIcon()
}

#Preview("Flex Emoji") {
    FlexEmojiIcon()
}

#Preview("Liquid Glass") {
    FlexLiquidGlassIcon()
}
#endif
