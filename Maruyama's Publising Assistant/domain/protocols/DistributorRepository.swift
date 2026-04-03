protocol DistributorRepository {
    func fetchDistributors() async throws -> [Distributor]
}