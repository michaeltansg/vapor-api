import Vapor

struct BeersController: RouteCollection {
    func boot(router: Router) throws {
        let routes = router.grouped("api", "beers")
        routes.get(use: getAllHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<Beers> {
        return try req.make(BeerService.self).fetch(on: req)
    }
}
