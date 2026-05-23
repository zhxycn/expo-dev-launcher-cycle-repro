import WidgetKit
import SwiftUI

struct DummyEntry: TimelineEntry {
    let date: Date
}

struct DummyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DummyEntry {
        DummyEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (DummyEntry) -> Void) {
        completion(DummyEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DummyEntry>) -> Void) {
        completion(Timeline(entries: [DummyEntry(date: Date())], policy: .never))
    }
}

struct DummyWidgetEntryView: View {
    var entry: DummyEntry
    var body: some View {
        Text(entry.date, style: .time)
    }
}

@main
struct DummyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DummyWidget", provider: DummyProvider()) { entry in
            DummyWidgetEntryView(entry: entry)
        }
    }
}
