import SwiftUI
import WidgetKit

/// Watch-face complication. Tapping it opens the LiftBig watch app.
struct LiftBigComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LiftBigComplication", provider: LiftBigTimeline()) { _ in
            LiftBigComplicationView()
                .widgetURL(URL(string: "liftbig://open"))
                .containerBackground(Color(red: 10 / 255, green: 15 / 255, blue: 30 / 255), for: .widget)
        }
        .configurationDisplayName("LiftBig")
        .description("Open LiftBig from your watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct LiftBigTimeline: TimelineProvider {
    func placeholder(in context: Context) -> LiftBigEntry {
        LiftBigEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (LiftBigEntry) -> Void) {
        completion(LiftBigEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LiftBigEntry>) -> Void) {
        let entry = LiftBigEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct LiftBigEntry: TimelineEntry {
    let date: Date
}

struct LiftBigComplicationView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("LiftBig")
        case .accessoryCorner:
            PlateMark()
                .widgetLabel { Text("LiftBig") }
        default:
            PlateMark()
                .padding(2)
        }
    }
}

/// One orange plate with LB. Large letters so a complication slot stays readable.
struct PlateMark: View {
    private let navy = Color(red: 10 / 255, green: 15 / 255, blue: 30 / 255)
    private let orange = Color(red: 244 / 255, green: 80 / 255, blue: 30 / 255)

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(orange)
                Circle()
                    .stroke(navy, lineWidth: max(1, side * 0.06))
                    .padding(side * 0.08)
                Text("LB")
                    .font(.system(size: side * 0.42, weight: .black, design: .rounded))
                    .foregroundStyle(navy)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

@main
struct LiftBigWidgets: WidgetBundle {
    var body: some Widget {
        LiftBigComplication()
    }
}
