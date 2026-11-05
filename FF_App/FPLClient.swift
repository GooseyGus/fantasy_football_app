import Foundation

/// Reads the public FPL API. None of these endpoints need a login.
struct FPLClient {
    enum Failure: LocalizedError {
        case teamNotFound
        /// The game returns 503 while it updates, mostly around deadlines.
        case updating
        case offline
        case unexpected

        var errorDescription: String? {
            switch self {
            case .teamNotFound: "There's no team with that ID."
            case .updating: "The game is being updated. Try again in a few minutes."
            case .offline: "Couldn't reach the FPL servers. Check your connection."
            case .unexpected: "Something went wrong loading your team."
            }
        }
    }

    private static let base = URL(string: "https://fantasy.premierleague.com/api/")!

    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func bootstrap() async throws -> Bootstrap {
        try await get("bootstrap-static/")
    }

    func entry(_ teamID: Int) async throws -> Entry {
        try await get("entry/\(teamID)/")
    }

    func picks(_ teamID: Int, gameweek: Int) async throws -> Picks {
        try await get("entry/\(teamID)/event/\(gameweek)/picks/")
    }

    func live(gameweek: Int) async throws -> Live {
        try await get("event/\(gameweek)/live/")
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: Self.base.appending(path: path))
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw Failure.offline
        }
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200: break
        case 404: throw Failure.teamNotFound
        case 503: throw Failure.updating
        default: throw Failure.unexpected
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw Failure.unexpected
        }
    }
}
