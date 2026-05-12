// GatewayClient notification REST helpers.

import Foundation

extension GatewayClient {
    func sendNotificationRestRequest<Body: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        body: Body?,
        responseType: ResponseBody.Type,
        tokenTTLSeconds: Int?
    ) async throws -> ResponseBody {
        let token = try await issueHttpPrincipalToken(ttlSeconds: tokenTTLSeconds)
        let url = try notificationRestURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("\(token.tokenType) \(token.token)", forHTTPHeaderField: "Authorization")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayError(code: "HTTP_ERROR", message: "Notification REST response was not HTTP.")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let gatewayError = try? decoder.decode(GatewayError.self, from: data) {
                throw gatewayError
            }
            throw GatewayError(
                code: "HTTP_\(httpResponse.statusCode)",
                message: String(data: data, encoding: .utf8) ?? "Notification REST request failed."
            )
        }
        return try decoder.decode(responseType, from: data)
    }

    func notificationRestURL(path: String) throws -> URL {
        guard var components = URLComponents(url: options.url, resolvingAgainstBaseURL: false) else {
            throw GatewayError(code: "INVALID_URL", message: "Gateway URL is invalid.")
        }
        switch components.scheme?.lowercased() {
        case "ws":
            components.scheme = "http"
        case "wss":
            components.scheme = "https"
        case "http", "https":
            break
        default:
            throw GatewayError(code: "INVALID_URL", message: "Gateway URL must use ws, wss, http, or https.")
        }
        components.path = path.hasPrefix("/") ? path : "/\(path)"
        components.query = nil
        components.fragment = nil
        guard let url = components.url else {
            throw GatewayError(code: "INVALID_URL", message: "Notification REST URL is invalid.")
        }
        return url
    }

    func emit(_ event: GatewayEvent) {
        eventContinuations.yield(event)
    }
}
