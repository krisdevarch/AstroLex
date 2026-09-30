import RealityKit
import SwiftUI
import UIKit

/// Walking skeleton for WP-3.0: proves SwiftUI + RealityKit render on device and that
/// each TestFlight build is identifiable. WP-3.2 replaces the title field with the play field.
struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.03, blue: 0.08), Color(red: 0.05, green: 0.07, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            TitleField()
                .ignoresSafeArea()

            VStack {
                Spacer()
                Text(BuildInfo.label)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 24)
                    .accessibilityLabel("Build \(BuildInfo.label)")
            }
        }
    }
}

/// "ASTROLEX" as tumbling letter tiles in a RealityView with a virtual camera.
struct TitleField: View {
    private static let word = Array("ASTROLEX")

    var body: some View {
        RealityView { content in
            content.camera = .virtual

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 50
            camera.position = [0, 0, 1.4]
            content.add(camera)

            let light = DirectionalLight()
            light.light.intensity = 2500
            light.orientation = simd_quatf(angle: -.pi / 5, axis: [1, 0, 0])
            content.add(light)

            let tileSize: Float = 0.1
            let spacing: Float = 0.125
            let startX = -spacing * Float(Self.word.count - 1) / 2

            for (index, letter) in Self.word.enumerated() {
                let tile = Self.makeTile(letter: letter, size: tileSize)
                let x = startX + spacing * Float(index)
                let y: Float = index.isMultiple(of: 2) ? 0.02 : -0.02
                tile.position = [x, y, 0]
                tile.orientation = simd_quatf(angle: Float(index % 3 - 1) * 0.12, axis: [0, 1, 0])
                    * simd_quatf(angle: Float(index % 2 == 0 ? 1 : -1) * 0.08, axis: [1, 0, 0])
                content.add(tile)
                Self.bob(tile, phase: Float(index))
            }
        }
    }

    private static func makeTile(letter: Character, size: Float) -> Entity {
        let tile = ModelEntity(
            mesh: .generateBox(size: size, cornerRadius: size * 0.18),
            materials: [SimpleMaterial(color: .white, roughness: 0.4, isMetallic: false)]
        )

        let glyphMesh = MeshResource.generateText(
            String(letter),
            extrusionDepth: size * 0.05,
            font: .systemFont(ofSize: CGFloat(size * 0.7), weight: .heavy)
        )
        let glyph = ModelEntity(
            mesh: glyphMesh,
            materials: [UnlitMaterial(color: UIColor(red: 0.05, green: 0.07, blue: 0.16, alpha: 1))]
        )
        let center = glyphMesh.bounds.center
        glyph.position = [-center.x, -center.y, size / 2 + 0.001]
        tile.addChild(glyph)
        return tile
    }

    /// Gentle vertical drift so the build visibly animates at the display's refresh rate.
    private static func bob(_ entity: Entity, phase: Float) {
        var up = entity.transform
        up.translation.y += 0.015
        let animation = FromToByAnimation<Transform>(
            from: entity.transform,
            to: up,
            duration: 1.6 + Double(phase) * 0.07,
            timing: .easeInOut,
            bindTarget: .transform,
            repeatMode: .autoReverse
        )
        if let resource = try? AnimationResource.generate(with: animation) {
            entity.playAnimation(resource)
        }
    }
}

#Preview {
    ContentView()
}
