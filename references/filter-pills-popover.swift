// MARK: - Filter Pills with Popovers (replaces FilterSheet)
// Each pill anchors its own popover. 1 tap to open, 1 tap to select.
// Stats stay visible underneath. iOS 26 Liquid Glass applied automatically.

import SwiftUI

// MARK: - Filter Model

enum PeriodMode: String, CaseIterable {
    case byDate = "By Date"
    case byGames = "By Games"
}

enum DatePeriod: String, CaseIterable, Identifiable {
    case last7Days = "7 Days"
    case last30Days = "30 Days"
    case last90Days = "90 Days"
    case thisYear = "This Year"
    case allTime = "All Time"

    var id: String { rawValue }
}

enum GameCountPeriod: String, CaseIterable, Identifiable {
    case last10 = "Last 10"
    case last20 = "Last 20"
    case last50 = "Last 50"
    case all = "All"

    var id: String { rawValue }
}

enum SourceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case local = "Local"
    case online = "Online"

    var id: String { rawValue }
}

enum GameType: String, CaseIterable, Identifiable {
    case threeOhOne = "301"
    case fiveOhOne = "501"
    case sevenOhOne = "701"

    var id: String { rawValue }
}

enum OutMode: String, CaseIterable, Identifiable {
    case doubleOut = "Double Out"
    case straightOut = "Straight Out"
    case masterOut = "Master Out"

    var id: String { rawValue }
}

enum InMode: String, CaseIterable, Identifiable {
    case openIn = "Open In"
    case doubleIn = "Double In"

    var id: String { rawValue }
}

struct StatsFilter {
    var periodMode: PeriodMode = .byDate
    var datePeriod: DatePeriod = .last90Days
    var gameCountPeriod: GameCountPeriod = .last20
    var source: SourceFilter = .all
    var gameType: GameType = .fiveOhOne
    var outMode: OutMode = .doubleOut
    var inMode: InMode = .openIn

    /// Display label for the period pill
    var periodLabel: String {
        switch periodMode {
        case .byDate: datePeriod.rawValue
        case .byGames: gameCountPeriod.rawValue
        }
    }

    /// Compact label for x01 settings pill
    var x01Label: String {
        "\(gameType.rawValue) · \(outMode == .doubleOut ? "Dbl" : outMode == .straightOut ? "Str" : "Mst")"
    }
}

// MARK: - Filter Pills Bar

struct FilterPillsBar: View {
    @Binding var filter: StatsFilter

    @State private var showPeriod = false
    @State private var showSource = false
    @State private var showX01 = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Period pill
                FilterPill(label: filter.periodLabel, isActive: showPeriod) {
                    showPeriod.toggle()
                }
                .popover(isPresented: $showPeriod) {
                    PeriodPopover(filter: $filter)
                        .presentationCompactAdaptation(.popover)
                }

                // Source pill
                FilterPill(label: filter.source.rawValue, icon: sourceIcon, isActive: showSource) {
                    showSource.toggle()
                }
                .popover(isPresented: $showSource) {
                    SourcePopover(selection: $filter.source)
                        .presentationCompactAdaptation(.popover)
                }

                // X01 Settings pill
                FilterPill(label: filter.x01Label, isActive: showX01) {
                    showX01.toggle()
                }
                .popover(isPresented: $showX01) {
                    X01Popover(filter: $filter)
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(.horizontal)
        }
    }

    private var sourceIcon: String {
        switch filter.source {
        case .all: "square.3.layers.3d"
        case .local: "iphone"
        case .online: "globe"
        }
    }
}

// MARK: - Filter Pill Button

struct FilterPill: View {
    let label: String
    var icon: String? = nil
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        // iOS 26: Liquid Glass capsule
        .glassEffect(.interactive, in: .capsule)
    }
}

// MARK: - Period Popover

struct PeriodPopover: View {
    @Binding var filter: StatsFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // By Date / By Games toggle
            Picker("Mode", selection: $filter.periodMode) {
                ForEach(PeriodMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Options based on mode
            switch filter.periodMode {
            case .byDate:
                ForEach(DatePeriod.allCases) { period in
                    PopoverRow(
                        label: period.rawValue,
                        isSelected: filter.datePeriod == period
                    ) {
                        filter.datePeriod = period
                        dismiss()
                    }
                }

                Divider()

                // Custom date row
                Button {
                    // Open date picker
                } label: {
                    Label("Custom...", systemImage: "calendar")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

            case .byGames:
                ForEach(GameCountPeriod.allCases) { period in
                    PopoverRow(
                        label: period.rawValue,
                        isSelected: filter.gameCountPeriod == period
                    ) {
                        filter.gameCountPeriod = period
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 220)
    }
}

// MARK: - Source Popover

struct SourcePopover: View {
    @Binding var selection: SourceFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SourceFilter.allCases) { source in
                PopoverRow(
                    label: source.rawValue,
                    icon: icon(for: source),
                    isSelected: selection == source
                ) {
                    selection = source
                    dismiss()
                }
            }
        }
        .frame(width: 180)
    }

    private func icon(for source: SourceFilter) -> String {
        switch source {
        case .all: "square.3.layers.3d"
        case .local: "iphone"
        case .online: "globe"
        }
    }
}

// MARK: - X01 Settings Popover

struct X01Popover: View {
    @Binding var filter: StatsFilter

    var body: some View {
        VStack(spacing: 0) {
            // Game Type
            HStack {
                Text("Game")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Game", selection: $filter.gameType) {
                    ForEach(GameType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 16)

            // Out Mode
            HStack {
                Text("Out")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Out", selection: $filter.outMode) {
                    ForEach(OutMode.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.leading, 16)

            // In Mode
            HStack {
                Text("In")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("In", selection: $filter.inMode) {
                    ForEach(InMode.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 260)
    }
}

// MARK: - Shared Popover Row

struct PopoverRow: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .frame(width: 20)
                }
                Text(label)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Usage in Statistics View

struct StatisticsView: View {
    @State private var filter = StatsFilter()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter pills — always visible, anchoring popovers
                FilterPillsBar(filter: $filter)
                    .padding(.vertical, 8)

                // Stats content — stays visible when popovers open
                ScrollView {
                    // ... your stats cards, charts, etc.
                }
            }
            .navigationTitle("Statistics")
        }
    }
}
