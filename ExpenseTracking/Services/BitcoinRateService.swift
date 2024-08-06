import Foundation

class BitcoinRateService {
    static let shared = BitcoinRateService()
    
    private let rateURL = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")!
    private let lastUpdateKey = "lastBitcoinRateUpdate"
    private let rateKey = "bitcoinRate"
    
    var rate: String? {
        return UserDefaults.standard.string(forKey: rateKey)
    }
    
    func fetchRateIfNeeded(completion: @escaping (String?) -> Void) {
        let lastUpdated = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date ?? Date.distantPast
        if Date().timeIntervalSince(lastUpdated) > 3600 {
            fetchRate(completion: completion)
        } else {
            completion(rate)
        }
    }
    
    private func fetchRate(completion: @escaping (String?) -> Void) {
        let task = URLSession.shared.dataTask(with: rateURL) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let bpi = json["bpi"] as? [String: Any],
                   let usd = bpi["USD"] as? [String: Any],
                   let rate = usd["rate"] as? String {
                    
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(Date(), forKey: self.lastUpdateKey)
                        UserDefaults.standard.set(rate, forKey: self.rateKey)
                        completion(rate)
                    }
                } else {
                    completion(nil)
                }
            } catch {
                print("Failed to parse JSON: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
}
