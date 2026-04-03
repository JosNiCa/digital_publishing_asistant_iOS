protocol FusionRepository {
    func applyFusion(
        photoId: Int,
        distributorId: Int,
        coordinate: Int
    ) async throws -> FusionResult
}