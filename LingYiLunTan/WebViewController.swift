import UIKit
import WebKit

/// 凌意论坛 iOS 版 —— WKWebView 套壳
/// 对应 Android APK (top.lingyiluntan.app v1.7.6) 的功能：
///   - 加载 https://lingyiluntan.top/
///   - Cookie 持久化（"记住登录"）
///   - JS alert / confirm / prompt 支持
///   - 外部链接跳转 Safari
///   - 下拉刷新
class WebViewController: UIViewController {

    // MARK: - 配置

    /// 论坛首页地址（可改）
    private let homeURL = URL(string: "https://lingyiluntan.top/")!

    // MARK: - UI

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()

        // 持久化 Cookie —— 对应 APK 的 "remember" 功能
        // defaultDataStore 会把 cookie 写入磁盘，关掉 App 再打开登录态还在
        config.websiteDataStore = WKWebsiteDataStore.default()

        // 允许 JS
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = prefs

        // 允许视频内联播放
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        // 观察 loading 进度
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)

        return webView
    }()

    private lazy var progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.progressTintColor = .systemBlue
        bar.trackTintColor = .clear
        bar.isHidden = true
        return bar
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    private lazy var backButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain, target: self, action: #selector(goBack)
        )
        return btn
    }()

    private lazy var forwardButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.forward"),
            style: .plain, target: self, action: #selector(goForward)
        )
        return btn
    }()

    private lazy var homeButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(
            image: UIImage(systemName: "house"),
            style: .plain, target: self, action: #selector(goHome)
        )
        return btn
    }()

    private lazy var reloadButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain, target: self, action: #selector(reload)
        )
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadHome()

        // 网络断开恢复后自动刷新
        NotificationCenter.default.addObserver(
            self, selector: #selector(loadHome),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
    }

    // MARK: - UI 搭建

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(webView)
        view.addSubview(progressBar)

        // WebView 里嵌下拉刷新
        webView.scrollView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 3),
        ])

        // 底部工具栏（由 SceneDelegate 里的 UINavigationController 提供）
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [backButton, spacer, forwardButton, spacer, homeButton, spacer, reloadButton]
    }

    // MARK: - 导航动作

    @objc private func loadHome() {
        var request = URLRequest(url: homeURL)
        request.cachePolicy = .reloadRevalidatingCacheData
        webView.load(request)
    }

    @objc private func handleRefresh() {
        webView.reload()
    }

    @objc private func goBack() {
        if webView.canGoBack { webView.goBack() }
    }

    @objc private func goForward() {
        if webView.canGoForward { webView.goForward() }
    }

    @objc private func goHome() {
        loadHome()
    }

    @objc private func reload() {
        webView.reload()
    }

    // MARK: - KVO

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            let progress = Float(webView.estimatedProgress)
            progressBar.isHidden = progress >= 1.0
            progressBar.setProgress(progress, animated: true)
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.progressBar.setProgress(0, animated: false)
                }
            }
        } else if keyPath == #keyPath(WKWebView.title) {
            title = webView.title
        }
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // 外部链接（非 lingyiluntan.top 域名）跳 Safari
        if let url = navigationAction.request.url {
            let host = url.host ?? ""
            if !host.contains("lingyiluntan.top") && url.scheme == "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        showOfflineHint()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        showOfflineHint()
    }

    /// 加载失败时显示离线提示
    private func showOfflineHint() {
        let alert = UIAlertController(
            title: "无法连接",
            message: "论坛暂时打不开，请检查网络后重试。\n地址：lingyiluntan.top",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.loadHome()
        })
        alert.addAction(UIAlertAction(title: "好", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - WKUIDelegate（JS 弹窗）

extension WebViewController: WKUIDelegate {

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: frame.request.url?.host, message: prompt, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = defaultText }
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(nil) })
        present(alert, animated: true)
    }
}
