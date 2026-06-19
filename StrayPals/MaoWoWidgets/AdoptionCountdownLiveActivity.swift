//
//  AdoptionCountdownLiveActivity.swift
//  MaoWoWidgets
//
//  「認養倒數」Live Activity：在鎖定畫面與動態島顯示某隻浪浪的認養截止倒數，
//  提醒飼主把握開放認養時間。
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Brand Color

private extension Color {
    static let brandCoral = Color(red: 1.0, green: 0.42, blue: 0.37)   // #FF6B5E
}

// MARK: - AdoptionCountdownLiveActivity

@available(iOS 16.1, *)
struct AdoptionCountdownLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AdoptionCountdownAttributes.self) { context in
            // 鎖定畫面 / 橫幅。
            LockScreenView(context: context)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.kindEmoji)
                        .font(.title)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.deadline, style: .relative)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundColor(.brandCoral)
                        Text("截止")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading) {
                        Text(context.attributes.animalName)
                            .font(.subheadline).bold()
                            .lineLimit(1)
                        Text(context.state.shelterName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Label("把握認養開放時間", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.brandCoral)
                }
            } compactLeading: {
                Text(context.attributes.kindEmoji)
            } compactTrailing: {
                Text(context.state.deadline, style: .relative)
                    .monospacedDigit()
                    .frame(maxWidth: 64)
                    .foregroundColor(.brandCoral)
            } minimal: {
                Text(context.attributes.kindEmoji)
            }
            .widgetURL(URL(string: "maowo://animal/\(context.attributes.animalId)"))
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<AdoptionCountdownAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Text(context.attributes.kindEmoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 3) {
                Text(context.attributes.animalName)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.state.shelterName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.deadline, style: .relative)
                    .font(.title3).bold()
                    .monospacedDigit()
                    .foregroundColor(.brandCoral)
                Text("認養截止")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
