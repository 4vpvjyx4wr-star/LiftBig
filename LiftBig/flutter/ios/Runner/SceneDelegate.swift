import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    var remaining: Set<UIOpenURLContext> = []
    for context in URLContexts {
      if !CompanionBridge.shared.open(url: context.url) {
        remaining.insert(context)
      }
    }
    if !remaining.isEmpty {
      super.scene(scene, openURLContexts: remaining)
    }
  }
}
