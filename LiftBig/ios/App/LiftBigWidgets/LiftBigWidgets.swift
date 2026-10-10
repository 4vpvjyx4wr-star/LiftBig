import ActivityKit
import SwiftUI
import WidgetKit

struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            VStack(alignment: .leading) {
                Text(context.attributes.title)
                    .font(.headline)
                Text(timerInterval: context.state.endsAt...Date.distantFuture, countsDown: true)
                    .font(.title2.monospacedDigit())
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(timerInterval: context.state.endsAt...Date.distantFuture, countsDown: true)
                }
            } compactLeading: {
                Text("Rest")
            } compactTrailing: {
                Text(timerInterval: context.state.endsAt...Date.distantFuture, countsDown: true)
            } minimal: {
                Text("R")
            }
        }
    }
}

@main
struct LiftBigWidgets: WidgetBundle {
    var body: some Widget {
        RestLiveActivity()
    }
}
