//
//  Observable.swift
//  StrayPals
//
//  輕量級的「可觀察」資料綁定容器（Box / Observer Pattern）。
//  用於 MVVM 中 ViewModel 與 ViewController 的單向資料綁定，
//  避免引入 Combine / RxSwift 等額外相依，讓綁定關係一目了然。
//

import Foundation

// MARK: - Observable

/// 一個可被監聽的值容器。當 `value` 改變時會通知綁定的監聽者。
///
/// 使用方式：
/// ```swift
/// let isLoading = Observable(false)
/// isLoading.bind { loading in /* 更新 UI */ }
/// isLoading.value = true   // 觸發回呼
/// ```
final class Observable<T> {

    // MARK: Types

    typealias Listener = (T) -> Void

    // MARK: Properties

    /// 目前的值，設定後會在主執行緒通知監聽者。
    var value: T {
        didSet { notify() }
    }

    private var listener: Listener?

    // MARK: Init

    init(_ value: T) {
        self.value = value
    }

    // MARK: Binding

    /// 綁定監聽者，並「立即」以目前值回呼一次（方便初始化 UI）。
    func bind(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }

    /// 僅綁定後續變化，不立即回呼。
    func observe(_ listener: Listener?) {
        self.listener = listener
    }

    // MARK: Private

    private func notify() {
        if Thread.isMainThread {
            listener?(value)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.listener?(self.value)
            }
        }
    }
}
