import Foundation

struct DailyTipResponse: Decodable, Sendable {
    let tip: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let tip = try? container.decode(String.self, forKey: .tip) {
            self.tip = tip
            return
        }

        if let message = try? container.decode(String.self, forKey: .message) {
            self.tip = message
            return
        }

        if let nested = try? container.nestedContainer(keyedBy: DataKeys.self, forKey: .data),
           let tip = try? nested.decode(String.self, forKey: .tip) {
            self.tip = tip
            return
        }

        throw DecodingError.dataCorruptedError(
            forKey: .tip,
            in: container,
            debugDescription: "Daily tip not found in response."
        )
    }

    private enum CodingKeys: String, CodingKey {
        case tip
        case message
        case data
    }

    private enum DataKeys: String, CodingKey {
        case tip
    }
}
