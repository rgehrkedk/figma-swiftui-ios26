// MARK: - Filter Pills with Popovers (replaces FilterSheet)
// 3 pills: Period (When?) · Opponent (Who?) · Game Settings (What?)
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

enum OpponentCategory: Equatable, Hashable {
    case all
    case solo
    case vsBots
    case vsPlayers
    case specific(String) // opponent name

    var label: String {
        switch self {
        case .all: "vs All"
        case .solo: "Solo"
        case .vsBots: "vs Bots"
        case .vsPlayers: "vs Players"
        case .specific(let name): "vs \(name)"
        }
    }

    var icon: String {
        switch self {
        case .all: "person.2"
        case .solo: "person"
        case .vsBots: "cpu"
        case .vsPlayers: "person.2.fill"
        case .specific: "person.circle"
        }
    }
}

enum OpponentType {
    case player
    case bot
}

struct OpponentEntry: Identifiable {
    let id = UUID()
    let name: String
    let type: OpponentType
    let icon: String

    static let samplePlayers: [OpponentEntry] = [
        OpponentEntry(name: "Dan", type: .player, icon: "person.circle.fill"),
        OpponentEntry(name: "Mike", type: .player, icon: "person.circle.fill"),
        OpponentEntry(name: "Sarah", type: .player, icon: "person.circle.fill"),
        OpponentEntry(name: "Guest 1", type: .player, icon: "person.circle"),
    ]

    static let sampleBots: [OpponentEntry] = [
        OpponentEntry(name: "Bot Easy", type: .bot, icon: "cpu"),
        OpponentEntry(name: "Bot Medium", type: .bot, icon: "cpu"),
        OpponentEntry(name: "Bot Hard", type: .bot, icon: "cpu"),
    ]
}

enum SourceFilter: String, CaseIterable, Identifiable {
    case all = "All Games"
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

    var shortLabel: String {
        switch self {
        case .doubleOut: "Dbl"
        case .straightOut: "Str"
        case .masterOut: "Mst"
        }
    }
}

enum InMode: String, CaseIterable, Identifiable {
    case openIn = "Open In"
    case doubleIn = "Double In"

    var id: String { rawValue }
}

struct StatsFilter {
    // Period
    var periodMode: PeriodMode = .byDate
    var datePeriod: DatePeriod = .last90Days
    var gameCountPeriod: GameCountPeriod = .last20
    var customDateRange: ClosedRange<Date>?

    // Opponent
    var opponentCategory: OpponentCategory = .all
    var source: SourceFilter = .all

    // Game settings
    var gameType: GameType = .fiveOhOne
    var outMode: OutMode = .doubleOut
    var inMode: InMode = .openIn

    /// Display label for the period pill
    var periodLabel: String {
        if let range = customDateRange, periodMode == .byDate {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return "\(fmt.string(from: range.lowerBound))–\(fmt.string(from: range.upperBound))"
        }
        switch periodMode {
        case .byDate: return datePeriod.rawValue
        case .byGames: return gameCountPeriod.rawValue
        }
    }

    /// Display label for the opponent pill
    var opponentLabel: String {
        opponentCategory.label
    }

    /// Compact label for x01 settings pill
    var x01Label: String {
        "\(gameType.rawValue) · \(outMode.shortLabel)"
    }
}

// MARK: - Filter Pills Bar

struct FilterPillsBar: View {
    @Binding var filter: StatsFilter

    @State private var showPeriod = false
    @State private var showOpponent = false
    @State private var showX01 = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 8) {
                // Pill 1: Period (When?)
                FilterPill(label: filter.periodLabel) {
                    showPeriod.toggle()
                }
                .popover(isPresented: $showPeriod) {
                    PeriodPopover(filter: $filter)
                        .presentationCompactAdaptation(.popover)
                }

                // Pill 2: Opponent (Who?)
                FilterPill(
                    label: filter.opponentLabel,
                    icon: filter.opponentCategory.icon
                ) {
                    showOpponent.toggle()
                }
                .popover(isPresented: $showOpponent) {
                    OpponentPopover(filter: $filter)
                        .presentationCompactAdaptation(.popover)
                }

                // Pill 3: Game Settings (What?)
                FilterPill(label: filter.x01Label) {
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
}

// MARK: - Filter Pill Button

struct FilterPill: View {
    let label: String
    var icon: String? = nil
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
        .glassEffect(.interactive, in: .capsule)
    }
}

// MARK: - Period Popover

struct PeriodPopover: View {
    @Binding var filter: StatsFilter
    @Environment(\.dismiss) private var dismiss
    @State private var showCustomDateSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // By Date / By Games segment
            Picker("Mode", selection: $filter.periodMode) {
                ForEach(PeriodMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: filter.periodMode) {
                // Clear custom range when switching modes
                filter.customDateRange = nil
            }

            Divider()

            // Options based on selected mode
            switch filter.periodMode {
            case .byDate:
                ForEach(DatePeriod.allCases) { period in
                    PopoverRow(
                        label: period.rawValue,
                        isSelected: filter.customDateRange == nil && filter.datePeriod == period
                    ) {
                        filter.customDateRange = nil
                        filter.datePeriod = period
                        dismiss()
                    }
                }

                Divider()

                // Custom date range
                Button {
                    showCustomDateSheet = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Custom...")
                        Spacer()
                        if filter.customDateRange != nil {
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
                .sheet(isPresented: $showCustomDateSheet) {
                    CustomDateRangeSheet(filter: $filter) {
                        showCustomDateSheet = false
                        dismiss()
                    }
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

// MARK: - Custom Date Range Sheet

struct CustomDateRangeSheet: View {
    @Binding var filter: StatsFilter
    let onConfirm: () -> Void

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now
    @State private var endDate = Date.now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("From", selection: $startDate, displayedComponents: .date)
                DatePicker("To", selection: $endDate, displayedComponents: .date)
            }
            .navigationTitle("Custom Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onConfirm() // dismisses both sheet and popover
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filter.customDateRange = startDate...endDate
                        onConfirm()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            // Pre-fill from existing custom range if set
            if let existing = filter.customDateRange {
                startDate = existing.lowerBound
                endDate = existing.upperBound
            }
        }
    }
}

// MARK: - Opponent Popover

struct OpponentPopover: View {
    @Binding var filter: StatsFilter
    @Environment(\.dismiss) private var dismiss

    // Sample data — replace with your actual data source
    let players: [OpponentEntry] = OpponentEntry.samplePlayers
    let bots: [OpponentEntry] = OpponentEntry.sampleBots

    var body: some View {
        NavigationStack {
            OpponentCategoryList(
                filter: $filter,
                players: players,
                bots: bots,
                onDismiss: { dismiss() }
            )
        }
        .frame(width: 240)
    }
}

// MARK: - Opponent Category List (root of NavigationStack)

private struct OpponentCategoryList: View {
    @Binding var filter: StatsFilter
    let players: [OpponentEntry]
    let bots: [OpponentEntry]
    let onDismiss: () -> Void

    private var categories: [(OpponentCategory, String)] {
        [
            (.all, "person.2"),
            (.solo, "person"),
            (.vsBots, "cpu"),
            (.vsPlayers, "person.2.fill"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category rows
            ForEach(Array(categories.enumerated()), id: \.offset) { _, item in
                let (category, icon) = item
                PopoverRow(
                    label: category.label,
                    icon: icon,
                    isSelected: filter.opponentCategory == category
                ) {
                    filter.opponentCategory = category
                    onDismiss()
                }
            }

            // Specific opponent drill-down
            NavigationLink {
                SpecificOpponentList(
                    filter: $filter,
                    players: players,
                    bots: bots,
                    onDismiss: onDismiss
                )
            } label: {
                HStack {
                    Image(systemName: "person.circle")
                        .frame(width: 20)
                    Text("Specific...")
                    Spacer()
                    if case .specific = filter.opponentCategory {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Source — secondary, tucked at bottom
            Divider()
                .padding(.vertical, 4)

            HStack {
                Text("Source")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Source", selection: $filter.source) {
                    ForEach(SourceFilter.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Specific Opponent List (drill-down)

private struct SpecificOpponentList: View {
    @Binding var filter: StatsFilter
    let players: [OpponentEntry]
    let bots: [OpponentEntry]
    let onDismiss: () -> Void

    @State private var searchText = ""

    private var filteredPlayers: [OpponentEntry] {
        if searchText.isEmpty { return players }
        return players.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredBots: [OpponentEntry] {
        if searchText.isEmpty { return bots }
        return bots.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var currentSelection: String? {
        if case .specific(let name) = filter.opponentCategory { return name }
        return nil
    }

    var body: some View {
        List {
            // Players section
            if !filteredPlayers.isEmpty {
                Section("Players") {
                    ForEach(filteredPlayers) { opponent in
                        opponentRow(opponent)
                    }
                }
            }

            // Bots section
            if !filteredBots.isEmpty {
                Section("Bots") {
                    ForEach(filteredBots) { opponent in
                        opponentRow(opponent)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search opponents")
        .navigationTitle("Opponent")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func opponentRow(_ opponent: OpponentEntry) -> some View {
        Button {
            filter.opponentCategory = .specific(opponent.name)
            onDismiss()
        } label: {
            HStack {
                Image(systemName: opponent.icon)
                    .frame(width: 20)
                Text(opponent.name)
                Spacer()
                if currentSelection == opponent.name {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.orange)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
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
                    ForEach(OutMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
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
                    ForEach(InMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
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
