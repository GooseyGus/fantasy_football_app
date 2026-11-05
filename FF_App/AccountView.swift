import SwiftUI

/// The team's details, and buttons to change or remove it.
struct AccountView: View {
    let team: Team
    /// Called with a new ID when the team is changed.
    let onChangeTeam: (Int) -> Void
    /// Called once the manager has confirmed they want to forget this team.
    let onRemoveTeam: () -> Void

    @State private var isChangingTeam = false
    @State private var isConfirmingRemove = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Account")
                .font(.din(.largeTitle))

            if let entry = team.entry {
                TeamSummary(entry: entry)
                    .padding(16)
                    .background(Color.card, in: .rect(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.ink.opacity(0.2), lineWidth: 1.5)
                    }
                    .padding(.top, 20)
            }

            Button("CHANGE TEAM") { isChangingTeam = true }
                .buttonStyle(BigButtonStyle())
                .padding(.top, 20)
            Button("REMOVE TEAM") { isConfirmingRemove = true }
                .buttonStyle(BigButtonStyle(isPrimary: false))
                .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.paper)
        .alert("Remove \(team.entry?.name ?? "this team")?", isPresented: $isConfirmingRemove) {
            Button("Cancel", role: .cancel) {}
            Button("Proceed", role: .destructive, action: onRemoveTeam)
        } message: {
            Text("You'll need to enter a team ID again to see it.")
        }
        .sheet(isPresented: $isChangingTeam) {
            TeamIDView(initialID: team.id, onCancel: { isChangingTeam = false }) { newID in
                isChangingTeam = false
                if newID != team.id { onChangeTeam(newID) }
            }
        }
    }
}

/// A team's name, manager and headline numbers.
struct TeamSummary: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.name)
                .font(.din(.title))
            Text([entry.managerName, entry.playerRegionName].compactMap(\.self).joined(separator: " · "))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            HStack(alignment: .firstTextBaseline) {
                stat("Total points", entry.summaryOverallPoints.formatted())
                stat("Overall rank", entry.summaryOverallRank?.formatted() ?? "–")
                stat("Last gameweek", entry.summaryEventPoints.map { "\($0) pts" } ?? "–")
            }
            .padding(.top, 16)
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.din(.caption)).foregroundStyle(.secondary)
            Text(value)
                .font(.din(.title3))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
