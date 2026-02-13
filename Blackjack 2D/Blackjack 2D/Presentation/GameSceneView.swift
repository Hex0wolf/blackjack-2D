import SpriteKit
import SwiftUI

struct GameSceneView: View {
    @ObservedObject var viewModel: BlackjackViewModel
    @State private var scene = BlackjackGameScene(size: CGSize(width: 1000, height: 760))

    var body: some View {
        SpriteView(
            scene: scene,
            preferredFramesPerSecond: 60,
            options: [.ignoresSiblingOrder]
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .onAppear {
            scene.scaleMode = .resizeFill
            scene.render(snapshot: viewModel.snapshot)
        }
        .onReceive(viewModel.$snapshot) { snapshot in
            scene.render(snapshot: snapshot)
        }
    }
}
