//
//  AdoptionWidgetBundle.swift
//  MaoWoWidgets
//
//  Widget Extension 進入點。目前僅提供「認養倒數」Live Activity（鎖定畫面 + 動態島）。
//

import WidgetKit
import SwiftUI

// MARK: - AdoptionWidgetBundle

@main
struct AdoptionWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            AdoptionCountdownLiveActivity()
        }
    }
}
