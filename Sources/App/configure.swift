import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register routes to the router
    services.register(Router.self) { _ -> EngineRouter in
        let router = EngineRouter.default()
        try routes(router)
        return router
    }
    
    // Register our custom Punk API wrapper
    services.register(BeerService.self)

    // Set MemoryKeyedCache as the preferred cache implementation
    config.prefer(MemoryKeyedCache.self, for:KeyedCache.self)
}
