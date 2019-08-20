import Vapor

/// A simple wrapper around the Punk API.
final class BeerService {
    /// The HTTP client powering this API.
    let client: Client
    
    /// Internal cache for optimizing HTTP client API usage.
    let cache: KeyedCache
    
    /// Creates a new API wrapper from the supplied client and cache.
    init(client: Client, cache: KeyedCache) {
        self.client = client
        self.cache = cache
    }
    
    /// Returns a list of beers.
    ///
    /// - parameter worker: The async worker to use.
    func fetch(on worker: Worker) -> Future<Beers> {
        /// create a consistent cache key
        let key = "beers"
        return cache.get(key, as: Beers.self).flatMap { result in
            if let exists = result {
                /// The verification result has been cached, no need to continue!
                /// Note: we must wrap the result in a Future here because we are inside of `flatMap`
                /// and the API fetch that happens after this is async.
                return worker.eventLoop.newSucceededFuture(result: exists)
            }

            /// The results was not cached, we need to query the Punk API, cache it and return the results.
            return self.fetchBeers().flatMap { response in
                switch response.http.status.code {
                case 200..<300:
                    let beers = try response.content.syncDecode(Beers.self)
                    return self.cache.set(key, to: beers).transform(to: beers)
                default:
                    /// The API returned a 500. Only thing we can do is forward the error.
                    throw Abort(.internalServerError, reason: "Unexpected service response: \(response.http.status)")
                }
            }
        }
    }
    
    /// Fetches a list of beers from the Punk API.
    func fetchBeers() -> Future<Response> {
        return client.get("https://api.punkapi.com/v2/beers")
    }
}

/// Allow our custom API wrapper to be used as a Vapor service.
extension BeerService: ServiceType {
    /// See `ServiceType.makeService(for:)`
    static func makeService(for container: Container) throws -> BeerService {
        /// Use the container to create the Client and KeyedCache services our API wrapper needs.
        return try BeerService(client: container.make(), cache: container.make())
    }
}
