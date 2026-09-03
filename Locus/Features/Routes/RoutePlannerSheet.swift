import CoreLocation
import SwiftUI

struct RoutePlannerSheet: View {
    @Binding var start: CLLocationCoordinate2D?
    @Binding var end: CLLocationCoordinate2D?
    @Binding var isRouting: Bool
    var onBuild: () -> Void
    var onPlay: () -> Void
    var onImportGPX: () -> Void
    var onExportGPX: () -> Void
    var onUseDrawn: () -> Void

    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss

    @State private var speedText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Road route") {
                    Button("Use current pin / spoof as start") {
                        start = session.simulated ?? session.pin
                    }
                    Button("Use current pin as end") {
                        end = session.pin
                    }
                    LabeledContent("Start") {
                        Text(coordText(start)).font(.caption.monospaced())
                    }
                    LabeledContent("End") {
                        Text(coordText(end)).font(.caption.monospaced())
                    }
                    Button {
                        onBuild()
                    } label: {
                        if isRouting {
                            ProgressView()
                        } else {
                            Label("Build walk/drive route on roads", systemImage: "road.lanes")
                        }
                    }
                    .disabled(isRouting)
                }

                Section("Play / draw / GPX") {
                    Button {
                        onUseDrawn()
                    } label: {
                        Label("Use drawn path from map", systemImage: "pencil.tip")
                    }
                    Button(action: onPlay) {
                        Label("Follow route", systemImage: "play.fill")
                    }
                    Button(action: onImportGPX) {
                        Label("Import GPX", systemImage: "square.and.arrow.down")
                    }
                    Button(action: onExportGPX) {
                        Label("Export GPX", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    HStack {
                        TextField("Custom km/h", text: $speedText)
                            .keyboardType(.decimalPad)
                            .onSubmit { applySpeed() }
                        if session.customSpeedKmh != nil {
                            Button {
                                session.customSpeedKmh = nil
                                speedText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button("Set speed") { applySpeed() }
                        .disabled(speedText.isEmpty)
                    LabeledContent("Active") {
                        if let kmh = session.customSpeedKmh {
                            Text(String(format: "%.1f km/h", kmh))
                        } else {
                            Text("\(session.travelMode.title) default")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("Speed")
                } footer: {
                    Text("Max \(Int(SpoofSession.maxSpeedKmh)) km/h. Leave empty to use travel mode default.")
                }

                Section {
                    Text("Routes follow Apple Maps roads/footpaths for the selected travel mode. Speed gets light random variation so motion looks less robotic.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Routes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if let kmh = session.customSpeedKmh {
                    speedText = String(format: "%.1f", kmh)
                }
            }
        }
    }

    private func coordText(_ c: CLLocationCoordinate2D?) -> String {
        guard let c else { return "—" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }

    private func applySpeed() {
        guard let value = Double(speedText.replacingOccurrences(of: ",", with: ".")),
              value > 0 else {
            session.customSpeedKmh = nil
            speedText = ""
            return
        }
        let clamped = min(value, SpoofSession.maxSpeedKmh)
        session.customSpeedKmh = clamped
        speedText = String(format: "%.1f", clamped)
    }
}
