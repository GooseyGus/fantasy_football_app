import SwiftUI

/// The first screen: asks for a team ID, explains where to find it, and checks it's the right team.
struct TeamIDView: View {
    /// The team already chosen, if any, to start from.
    var initialID: Int?
    /// Shows a Cancel button when set, for changing an existing team.
    var onCancel: (() -> Void)?
    /// Called with the ID once the manager has confirmed it's their team.
    let onFound: (Int) -> Void

    /// Where to find a team ID. Safari is likely already signed in there, unlike a browser inside the app.
    private static let fplURL = URL(string: "https://fantasy.premierleague.com/")!

    @State private var text = ""
    @FocusState private var isFocused: Bool
    @State private var isChecking = false
    @State private var error: String?
    /// The team that was found, waiting for the manager to say whether it's theirs.
    @State private var found: Entry?

    private var teamID: Int? { Self.teamID(in: text) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.paper.ignoresSafeArea()
                    .onTapGesture { isFocused = false }

                // Stays put when the keypad opens; the field and button sit high enough not to be covered.
                content
                    .ignoresSafeArea(.keyboard)
            }
            .toolbar {
                if let onCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                }
            }
            .onAppear {
                if let initialID { text = String(initialID) }
            }
            .onChange(of: text) { tidyPastedText() }
            .sheet(item: $found) { entry in
                ConfirmTeamView(entry: entry) {
                    found = nil
                    onFound(entry.id)
                } onNo: {
                    found = nil
                    text = ""
                }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Find your team")
                .font(.din(.largeTitle))
            TextField("", text: $text, prompt: Text("Team ID").foregroundStyle(Color.ink.opacity(0.4)))
                .keyboardType(.numberPad)
                .focused($isFocused)
                .font(.din(.title2))
                .padding(.horizontal, 20)
                .frame(height: 64)
                .background(Color.card, in: .rect(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(isFocused ? Color.soft : Color.ink.opacity(0.12), lineWidth: 2)
                }
                .contentShape(.rect)
                .onTapGesture { isFocused = true }
                .padding(.top, 24)

            if let error {
                Text(error)
                    .font(.din(.subheadline))
                    .foregroundStyle(Color.soft)
                    .padding(.top, 10)
                    .padding(.horizontal, 4)
            }

            Button(action: find) {
                if isChecking {
                    ProgressView().tint(Color.ink)
                } else {
                    Text(teamID == nil ? "ENTER TEAM ID" : "FIND MY TEAM")
                }
            }
            .buttonStyle(BigButtonStyle())
            .disabled(teamID == nil || isChecking)
            .padding(.top, 14)

            help
                .padding(.top, 40)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, onCancel == nil ? 40 : 8)
    }

    private var help: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where's my team ID?")
                .font(.din(.headline))
            step(1, "Open the FPL website and sign in.")
            step(2, "Tap **Points**.")
            step(3, "Copy the address, then come back and paste it here. The ID is the number after “entry” in it.")
            Link(destination: Self.fplURL) {
                Label("Open FPL website", systemImage: "arrow.up.right.square")
                    .font(.din(.body))
            }
            .foregroundStyle(Color.soft)
            .padding(.top, 4)
        }
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.din(.footnote))
                .foregroundStyle(Color.paper)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.soft))
            Text(text)
                .font(.din(.subheadline))
                .foregroundStyle(.secondary)
        }
    }

    private func find() {
        guard let teamID, !isChecking else { return }
        isFocused = false
        isChecking = true
        error = nil
        Task {
            defer { isChecking = false }
            do {
                found = try await FPLClient().entry(teamID)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    /// A paste can bring in a whole link or other text, so keep just the ID.
    private func tidyPastedText() {
        guard text.contains(where: { !$0.isASCII || !$0.isNumber }) else {
            error = nil
            return
        }
        if let id = teamID {
            text = String(id)
            error = nil
        } else {
            text = ""
            error = "That doesn't look like a team ID or an FPL link."
        }
    }

    /// The team ID in a plain number or an FPL link like `.../entry/1234567/event/9`.
    /// IDs start at 1 and there are around 11 million teams, so up to 8 digits.
    static func teamID(in string: String) -> Int? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = if let match = trimmed.firstMatch(of: /entry\/(\d+)/) {
            String(match.1)
        } else {
            trimmed
        }
        guard (1...8).contains(digits.count), digits.allSatisfy(\.isASCII), let id = Int(digits), id > 0 else { return nil }
        return id
    }
}

/// "Is this your team?", with the team's headline numbers so it's easy to recognise.
private struct ConfirmTeamView: View {
    let entry: Entry
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Is this your team?")
                .font(.din(.subheadline))
                .foregroundStyle(.secondary)
            TeamSummary(entry: entry)
                .padding(.top, 4)

            Spacer(minLength: 20)

            Button("YES, THAT'S MY TEAM", action: onYes)
                .buttonStyle(BigButtonStyle())
            Button("NO, TRY AGAIN", action: onNo)
                .tracking(1.5)
                .font(.din(.headline))
                .foregroundStyle(Color.soft)
                .frame(maxWidth: .infinity, minHeight: 50)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 8)
        .presentationDetents([.medium])
        .presentationBackground(Color.paper)
        .interactiveDismissDisabled()
    }
}

#Preview {
    TeamIDView { _ in }
}
