import WidgetKit
import SwiftUI
import ActivityKit

@main
struct LocusWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpoofLiveActivity()
    }
}

struct SpoofLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpoofActivityAttributes.self) { context in
            HStack {
                VStack(alignment: .leading) {
                    Text("Locus Spoofing")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text(context.state.statusText)
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f km/h", context.state.speed))
                        .font(.title2.bold())
                    if context.state.isRouting {
                        Text("Routing")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Locus")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.1f km/h", context.state.speed))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.statusText)
                }
            } compactLeading: {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(String(format: "%.0f", context.state.speed))
            } minimal: {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "locus://"))
            .keylineTint(Color.blue)
        }
    }
}
