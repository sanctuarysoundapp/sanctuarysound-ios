// ============================================================================
// PCOClient.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: HTTP client for Planning Center Online REST API (JSON:API 1.0).
//          Handles OAuth 2.0 with PKCE via ASWebAuthenticationSession,
//          token refresh, and typed API method calls. No third-party deps.
// ============================================================================

import Foundation
import AuthenticationServices
import CryptoKit


// MARK: - ─── PCO Client ──────────────────────────────────────────────────

@MainActor
final class PCOClient: ObservableObject {

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false

    private var tokens: PCOTokens?
    private let baseURL = "https://api.planningcenteronline.com"
    private let session = URLSession.shared

    init() {
        // Try to restore tokens from Keychain
        if let saved = SecureStorage.loadTokens() {
            tokens = saved
            isAuthenticated = true
        }
    }


    // MARK: - ─── OAuth 2.0 + PKCE ───────────────────────────────────────────

    /// Starts the OAuth 2.0 PKCE flow via ASWebAuthenticationSession.
    func authenticate() async throws {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        let authURL = buildAuthURL(codeChallenge: codeChallenge)

        let callbackURL = try await performWebAuth(url: authURL)

        guard let code = extractAuthCode(from: callbackURL) else {
            throw PCOError.authCodeMissing
        }

        let newTokens = try await exchangeCodeForTokens(
            code: code,
            codeVerifier: codeVerifier
        )

        tokens = newTokens
        isAuthenticated = true
        try SecureStorage.saveTokens(newTokens)
    }

    /// Disconnect — clear tokens from Keychain.
    func disconnect() {
        tokens = nil
        isAuthenticated = false
        SecureStorage.clearTokens()
    }


    // MARK: - ─── API Methods ─────────────────────────────────────────────────

    /// Fetch all service types for the organization.
    func fetchServiceTypes() async throws -> [PCOResource<PCOServiceTypeAttributes>] {
        let response: PCOResponse<PCOServiceTypeAttributes> = try await get(
            path: "/services/v2/service_types"
        )
        return response.data
    }

    /// Fetch recent plans for a service type.
    func fetchPlans(serviceTypeID: String, limit: Int = 10) async throws -> [PCOResource<PCOPlanAttributes>] {
        let response: PCOResponse<PCOPlanAttributes> = try await get(
            path: "/services/v2/service_types/\(serviceTypeID)/plans",
            query: ["order": "-sort_date", "per_page": "\(limit)"]
        )
        return response.data
    }

    /// Fetch plan items (songs) for a specific plan.
    func fetchPlanItems(serviceTypeID: String, planID: String) async throws -> [PCOResource<PCOPlanItemAttributes>] {
        let response: PCOResponse<PCOPlanItemAttributes> = try await get(
            path: "/services/v2/service_types/\(serviceTypeID)/plans/\(planID)/items",
            query: ["filter": "song"]
        )
        return response.data
    }

    /// Fetch team members for a specific plan.
    func fetchTeamMembers(serviceTypeID: String, planID: String) async throws -> [PCOResource<PCOTeamMemberAttributes>] {
        let response: PCOResponse<PCOTeamMemberAttributes> = try await get(
            path: "/services/v2/service_types/\(serviceTypeID)/plans/\(planID)/team_members",
            query: ["per_page": "100"]
        )
        return response.data
    }

    /// Fetch a single song's details (for key info).
    func fetchSong(songID: String) async throws -> PCOResource<PCOSongAttributes> {
        let response: PCOSingleResponse<PCOSongAttributes> = try await get(
            path: "/services/v2/songs/\(songID)"
        )
        return response.data
    }

    /// Fetch arrangements for a song (contains BPM and key).
    func fetchArrangements(songID: String) async throws -> [PCOResource<PCOArrangementAttributes>] {
        let response: PCOResponse<PCOArrangementAttributes> = try await get(
            path: "/services/v2/songs/\(songID)/arrangements"
        )
        return response.data
    }


    // MARK: - ─── HTTP ────────────────────────────────────────────────────────

    private func get<T: Decodable>(path: String, query: [String: String] = [:]) async throws -> T {
        try await refreshTokenIfNeeded()

        guard let tokens else {
            throw PCOError.notAuthenticated
        }

        var components = URLComponents(string: baseURL + path)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        isLoading = true
        defer { isLoading = false }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PCOError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw PCOError.unauthorized
            }
            throw PCOError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }


    // MARK: - ─── Token Management ────────────────────────────────────────────

    private func refreshTokenIfNeeded() async throws {
        guard let tokens, tokens.expiresAt < Date() else { return }

        let newTokens = try await refreshTokens(refreshToken: tokens.refreshToken)
        self.tokens = newTokens
        isAuthenticated = true
        try SecureStorage.saveTokens(newTokens)
    }

    private func refreshTokens(refreshToken: String) async throws -> PCOTokens {
        var components = URLComponents(string: "https://api.planningcenteronline.com/oauth/token")!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: AppConfig.pcoClientID),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: request)
        return try decodeTokenResponse(data)
    }

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> PCOTokens {
        var components = URLComponents(string: "https://api.planningcenteronline.com/oauth/token")!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: AppConfig.pcoClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.pcoRedirectURI),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: request)
        return try decodeTokenResponse(data)
    }

    private func decodeTokenResponse(_ data: Data) throws -> PCOTokens {
        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String
            let expires_in: Int
            let scope: String?
        }

        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        return PCOTokens(
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expires_in)),
            scope: response.scope ?? "services"
        )
    }


    // MARK: - ─── PKCE Helpers ────────────────────────────────────────────────

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func buildAuthURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://api.planningcenteronline.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConfig.pcoClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.pcoRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "services"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        return components.url!
    }

    private func performWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "sanctuarysound"
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: PCOError.authCancelled)
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private func extractAuthCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }
}


// MARK: - ─── PCO Errors ──────────────────────────────────────────────────

enum PCOError: LocalizedError {
    case notAuthenticated
    case authCodeMissing
    case authCancelled
    case unauthorized
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Planning Center"
        case .authCodeMissing:  return "Authorization code not received"
        case .authCancelled:    return "Authentication was cancelled"
        case .unauthorized:     return "Session expired — please reconnect"
        case .invalidResponse:  return "Invalid response from Planning Center"
        case .httpError(let code): return "Planning Center error (HTTP \(code))"
        }
    }
}
