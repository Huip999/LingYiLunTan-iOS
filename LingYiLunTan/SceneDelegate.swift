import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // 套一层 UINavigationController，隐藏导航栏、显示底部工具栏
        let webVC = WebViewController()
        let nav = UINavigationController(rootViewController: webVC)
        nav.setNavigationBarHidden(true, animated: false)
        nav.setToolbarHidden(false, animated: false)

        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
