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
import OSLog
import UIKit


// MARK: - ─── PCO Client ──────────────────────────────────────────────────

@MainActor
final class PCOClient: ObservableObject {

    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false

    private var tokens: PCOTokens?
    private let baseURL = "https://api.planningcenteronline.com"
    private let session = URLSession.shared

    /// Retains the auth session while the browser is presented.
    private var activeAuthSession: ASWebAuthenticationSession?

    /// Serializes token refresh to prevent concurrent refresh attempts.
    private var refreshTask: Task<Void, Error>?

    /// Provides the presentation anchor for ASWebAuthenticationSession.
    private let contextProvider = AuthPresentationContext()

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

        let authURL = try buildAuthURL(codeChallenge: codeChallenge)

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
        Logger.network.info("Planning Center authentication succeeded")
    }

    /// Disconnect — clear tokens from Keychain.
    func disconnect() {
        tokens = nil
        isAuthenticated = false
        Logger.network.info("Planning Center disconnected — tokens cleared")
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
        let safeTypeID = sanitizedPathSegment(serviceTypeID)
        let response: PCOResponse<PCOPlanAttributes> = try await get(
            path: "/services/v2/service_types/\(safeTypeID)/plans",
            query: ["order": "-sort_date", "per_page": "\(limit)"]
        )
        return response.data
    }

    /// Fetch plan items (songs) for a specific plan.
    func fetchPlanItems(serviceTypeID: String, planID: String) async throws -> [PCOResource<PCOPlanItemAttributes>] {
        let safeTypeID = sanitizedPathSegment(serviceTypeID)
        let safePlanID = sanitizedPathSegment(planID)
        let response: PCOResponse<PCOPlanItemAttributes> = try await get(
            path: "/services/v2/service_types/\(safeTypeID)/plans/\(safePlanID)/items",
            query: ["filter": "song"]
        )
        return response.data
    }

    /// Fetch team members for a specific plan.
    func fetchTeamMembers(serviceTypeID: String, planID: String) async throws -> [PCOResource<PCOTeamMemberAttributes>] {
        let safeTypeID = sanitizedPathSegment(serviceTypeID)
        let safePlanID = sanitizedPathSegment(planID)
        let response: PCOResponse<PCOTeamMemberAttributes> = try await get(
            path: "/services/v2/service_types/\(safeTypeID)/plans/\(safePlanID)/team_members",
            query: ["per_page": "100"]
        )
        return response.data
    }

    /// Fetch a single song's details (for key info).
    func fetchSong(songID: String) async throws -> PCOResource<PCOSongAttributes> {
        let safeSongID = sanitizedPathSegment(songID)
        let response: PCOSingleResponse<PCOSongAttributes> = try await get(
            path: "/services/v2/songs/\(safeSongID)"
        )
        return response.data
    }

    /// Fetch arrangements for a song (contains BPM and key).
    func fetchArrangements(songID: String) async throws -> [PCOResource<PCOArrangementAttributes>] {
        let safeSongID = sanitizedPathSegment(songID)
        let response: PCOResponse<PCOArrangementAttributes> = try await get(
            path: "/services/v2/songs/\(safeSongID)/arrangements"
        )
        return response.data
    }

    /// Fetch top-level folders (campuses) for the organization.
    /// Returns empty array if the org doesn't use folders.
    func fetchTopLevelFolders() async throws -> [PCOResource<PCOFolderAttributes>] {
        // PCO docs: GET /services/v2/folders returns org-level folders.
        // Use per_page=100 and order by name for consistent display.
        let response: PCOResponse<PCOFolderAttributes> = try await get(
            path: "/services/v2/folders",
            query: ["per_page": "100", "order": "name"]
        )
        return response.data
    }

    /// Fetch contents of a folder: sub-folders and service types.
    /// Returns a tuple of (subFolders, serviceTypes) for unified display.
    func fetchFolderContents(folderID: String) async throws -> (
        folders: [PCOResource<PCOFolderAttributes>],
        serviceTypes: [PCOResource<PCOServiceTypeAttributes>]
    ) {
        let safeFolderID = sanitizedPathSegment(folderID)
        async let subFolders: PCOResponse<PCOFolderAttributes> = get(
            path: "/services/v2/folders/\(safeFolderID)/folders",
            query: ["per_page": "100"]
        )
        async let serviceTypes: PCOResponse<PCOServiceTypeAttributes> = get(
            path: "/services/v2/folders/\(safeFolderID)/service_types",
            query: ["per_page": "100"]
        )

        let (foldersResponse, typesResponse) = try await (subFolders, serviceTypes)
        return (folders: foldersResponse.data, serviceTypes: typesResponse.data)
    }


    // MARK: - ─── Path Sanitization ───────────────────────────────────────────

    /// Character set for encoding individual path segments — excludes "/"
    /// to prevent path traversal via IDs containing "../".
    private static let pathSegmentAllowed: CharacterSet = {
        var set = CharacterSet.urlPathAllowed
        set.remove("/")
        return set
    }()

    /// Percent-encodes a path segment to prevent path traversal or injection
    /// via API IDs. PCO IDs are numeric, but this guard protects against
    /// malformed or tampered API responses containing special characters.
    private func sanitizedPathSegment(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: Self.pathSegmentAllowed) ?? segment
    }


    // MARK: - ─── HTTP ────────────────────────────────────────────────────────

    private func get<T: Decodable>(path: String, query: [String: String] = [:]) async throws -> T {
        try await refreshTokenIfNeeded()

        guard let tokens else {
            throw PCOError.notAuthenticated
        }

        // Safe unwrap — guards against malformed URL path
        guard var components = URLComponents(string: baseURL + path) else {
            throw PCOError.invalidURL(baseURL + path)
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        // Safe unwrap — guards against malformed URL components
        guard let url = components.url else {
            throw PCOError.invalidURL(path)
        }
        var request = URLRequest(url: url)
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
                Logger.network.error("PCO API returned 401 Unauthorized for \(path)")
                throw PCOError.unauthorized
            }
            Logger.network.error("PCO API returned HTTP \(httpResponse.statusCode) for \(path)")
            throw PCOError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }


    // MARK: - ─── Token Management ────────────────────────────────────────────

    private func refreshTokenIfNeeded() async throws {
        guard let tokens, tokens.expiresAt < Date() else { return }

        // If a refresh is already in flight, await it instead of starting another.
        // Prevents concurrent refreshes that could invalidate each other's tokens.
        if let existingTask = refreshTask {
            try await existingTask.value
            return
        }

        let task = Task<Void, Error> { [weak self] in
            guard let self else { return }
            defer { self.refreshTask = nil }

            guard let currentTokens = self.tokens else { return }
            Logger.network.info("PCO token expired — refreshing")
            let newTokens = try await self.refreshTokens(refreshToken: currentTokens.refreshToken)
            self.tokens = newTokens
            self.isAuthenticated = true
            try SecureStorage.saveTokens(newTokens)
            Logger.network.info("PCO token refresh succeeded")
        }

        refreshTask = task
        try await task.value
    }

    private func refreshTokens(refreshToken: String) async throws -> PCOTokens {
        // Safe unwrap — guards against malformed OAuth token URL
        guard var components = URLComponents(string: "https://api.planningcenteronline.com/oauth/token") else {
            throw PCOError.invalidURL("oauth/token")
        }
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: AppConfig.pcoClientID),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]

        // Safe unwrap — guards against malformed URL components
        guard let url = components.url else {
            throw PCOError.invalidURL("oauth/token")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: request)
        return try decodeTokenResponse(data)
    }

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> PCOTokens {
        // Safe unwrap — guards against malformed OAuth token URL
        guard var components = URLComponents(string: "https://api.planningcenteronline.com/oauth/token") else {
            throw PCOError.invalidURL("oauth/token")
        }
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: AppConfig.pcoClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.pcoRedirectURI),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
        ]

        // Safe unwrap — guards against malformed URL components
        guard let url = components.url else {
            throw PCOError.invalidURL("oauth/token")
        }
        var request = URLRequest(url: url)
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

    private func buildAuthURL(codeChallenge: String) throws -> URL {
        // Safe unwrap — guards against malformed OAuth authorize URL
        guard var components = URLComponents(string: "https://api.planningcenteronline.com/oauth/authorize") else {
            throw PCOError.invalidURL("oauth/authorize")
        }
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConfig.pcoClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.pcoRedirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "services"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        // Safe unwrap — guards against malformed URL components
        guard let url = components.url else {
            throw PCOError.invalidURL("oauth/authorize")
        }
        return url
    }

    private func performWebAuth(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            let authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "sanctuarysound"
            ) { [weak self] callbackURL, error in
                // Clear the retained session reference
                self?.activeAuthSession = nil

                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: PCOError.authCancelled)
                }
            }
            authSession.prefersEphemeralWebBrowserSession = true
            authSession.presentationContextProvider = self?.contextProvider

            // Retain the session so it isn't deallocated
            self?.activeAuthSession = authSession
            authSession.start()
        }
    }

    private func extractAuthCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value
    }
}


// MARK: - ─── Auth Presentation Context ──────────────────────────────────

/// Provides the key window as the presentation anchor for ASWebAuthenticationSession.
private final class AuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        // Prefer the active foreground scene's key window
        if let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }),
           let keyWindow = activeScene.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }

        // Fallback: any existing window from any scene
        if let anyWindow = scenes.flatMap(\.windows).first {
            return anyWindow
        }

        // Last resort: create a new window attached to any available scene.
        // A window scene always exists when OAuth is triggered from the UI.
        guard let fallbackScene = scenes.first else {
            Logger.network.error("No UIWindowScene available for OAuth presentation anchor")
            // Return a detached window rather than crashing — the OAuth flow
            // will fail gracefully if no scene is available.
            return ASPresentationAnchor()
        }
        return ASPresentationAnchor(windowScene: fallbackScene)
    }
}


// MARK: - ─── PCO Errors ──────────────────────────────────────────────────

enum PCOError: LocalizedError {
    case notAuthenticated
    case authCodeMissing
    case authCancelled
    case unauthorized
    case invalidResponse
    case invalidURL(String)
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not connected to Planning Center"
        case .authCodeMissing:  return "Authorization code not received"
        case .authCancelled:    return "Authentication was cancelled"
        case .unauthorized:     return "Session expired — please reconnect"
        case .invalidResponse:  return "Invalid response from Planning Center"
        case .invalidURL(let detail): return "Failed to construct URL: \(detail)"
        case .httpError(let code): return "Planning Center error (HTTP \(code))"
        }
    }
}
