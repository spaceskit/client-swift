// Auth.swift — Ed25519 challenge-response authentication via CryptoKit
// Zero external dependencies. Apple CryptoKit provides Ed25519 natively.

import Foundation
import CryptoKit

// MARK: - Auth Key Pair

/// An Ed25519 key pair for gateway authentication.
public struct AuthKeyPair: Sendable {
    /// The Ed25519 private key.
    public let privateKey: Curve25519.Signing.PrivateKey

    /// The Ed25519 public key.
    public var publicKey: Curve25519.Signing.PublicKey {
        privateKey.publicKey
    }

    /// Base64-encoded raw public key bytes (32 bytes) — sent to the gateway.
    public var publicKeyBase64: String {
        Data(publicKey.rawRepresentation).base64EncodedString()
    }

    /// Generate a new random Ed25519 key pair.
    public init() {
        self.privateKey = Curve25519.Signing.PrivateKey()
    }

    /// Initialize from an existing private key.
    public init(privateKey: Curve25519.Signing.PrivateKey) {
        self.privateKey = privateKey
    }

    /// Initialize from raw private key bytes (32 bytes).
    public init(rawPrivateKey: Data) throws {
        self.privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: rawPrivateKey)
    }
}

// MARK: - Challenge Signing

/// Sign a base64-encoded challenge from the gateway.
/// Returns the Ed25519 signature as a base64 string.
public func signChallenge(_ challengeBase64: String, with keyPair: AuthKeyPair) throws -> String {
    guard let challengeData = Data(base64Encoded: challengeBase64) else {
        throw AuthError.invalidChallenge("Challenge is not valid base64")
    }

    let signature = try keyPair.privateKey.signature(for: challengeData)
    return Data(signature).base64EncodedString()
}

/// Verify a challenge signature (useful for testing).
public func verifySignature(
    _ signatureBase64: String,
    for challengeBase64: String,
    publicKey: Curve25519.Signing.PublicKey
) -> Bool {
    guard let challengeData = Data(base64Encoded: challengeBase64),
          let signatureData = Data(base64Encoded: signatureBase64) else {
        return false
    }

    return publicKey.isValidSignature(signatureData, for: challengeData)
}

// MARK: - Auth Errors

public enum AuthError: Error, LocalizedError, Sendable {
    case invalidChallenge(String)
    case signingFailed(String)
    case authenticationFailed(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidChallenge(let msg): return "Invalid challenge: \(msg)"
        case .signingFailed(let msg): return "Signing failed: \(msg)"
        case .authenticationFailed(let msg): return "Authentication failed: \(msg)"
        case .timeout: return "Authentication timed out"
        }
    }
}
