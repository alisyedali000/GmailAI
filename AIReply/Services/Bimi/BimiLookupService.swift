//
//  BimiLookupService.swift
//  AIReply
//

import Foundation

/// Resolves BIMI (Brand Indicators for Message Identification) logo URL for an email domain via DNS-over-HTTPS.
protocol BimiLookupServiceProtocol {
    func fetchLogoURL(domain: String) async -> URL?
}

/// BIMI TXT record host: default._bimi.<domain>
private let bimiHostPrefix = "default._bimi."

/// Google DNS-over-HTTPS endpoint for TXT lookups.
private let dohURL = "https://dns.google/resolve"

struct GoogleDoHResponse: Codable {
    let answer: [DoHAnswer]?
    enum CodingKeys: String, CodingKey { case answer = "Answer" }
}

struct DoHAnswer: Codable {
    let data: String?
}

final class BimiLookupService: BimiLookupServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLogoURL(domain: String) async -> URL? {
        let trimmed = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, trimmed.contains(".") else { return nil }
        let name = bimiHostPrefix + trimmed
        guard var components = URLComponents(string: dohURL) else { return nil }
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "type", value: "TXT")
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode(GoogleDoHResponse.self, from: data)
            for ans in decoded.answer ?? [] {
                guard let raw = ans.data else { continue }
                if let logoURL = parseBimiLogo(from: raw) { return logoURL }
            }
        } catch { /* no BIMI record or network error */ }
        return nil
    }

    /// Parses "v=BIMI1; l=https://..." from TXT data (data may be quoted).
    private func parseBimiLogo(from txtData: String) -> URL? {
        let cleaned = txtData.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        guard cleaned.contains("v=BIMI1"), cleaned.contains("l=") else { return nil }
        guard let rangeL = cleaned.range(of: "l=") else { return nil }
        let afterL = String(cleaned[rangeL.upperBound...])
        let endIndex = afterL.firstIndex(of: ";") ?? afterL.endIndex
        let urlString = String(afterL[..<endIndex]).trimmingCharacters(in: .whitespaces)
        return URL(string: urlString)
    }
}
