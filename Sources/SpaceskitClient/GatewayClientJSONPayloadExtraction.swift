// GatewayClient raw JSON payload extraction.

import Foundation

extension GatewayClient {
    /// Extract the raw JSON bytes of the "payload" key from a gateway message,
    /// avoiding the AnyCodable decode→re-encode round-trip that can corrupt
    /// bridged Foundation objects.
    static func extractPayloadData(from data: Data) throws -> Data {
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let payload = obj?["payload"] else {
            return Data("null".utf8)
        }
        if payload is NSNull {
            return Data("null".utf8)
        }

        // JSONSerialization cannot encode top-level scalar values directly.
        // Wrap then slice to preserve scalar payloads like true/"ok"/1.
        let wrapped = try JSONSerialization.data(withJSONObject: ["payload": payload])
        let prefix = Data("{\"payload\":".utf8)
        guard wrapped.starts(with: prefix), wrapped.last == UInt8(ascii: "}") else {
            throw GatewayError(
                code: "PARSE_ERROR",
                message: "Malformed payload envelope",
                details: nil
            )
        }
        return wrapped.subdata(in: prefix.count ..< wrapped.count - 1)
    }
}
