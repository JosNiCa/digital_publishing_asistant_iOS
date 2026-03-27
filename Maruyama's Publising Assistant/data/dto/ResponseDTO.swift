//
//  LoginResponseDTO.swift
//  Maruyama's Publising Assistant
//
//  Created by LJD Technology on 23/03/26.
//

struct LoginResponseDTO: Codable {
    let ok: Bool
    let data: DataDTO?
    let error: ErrorDTO?
}

struct DataDTO: Codable {
    let token: String
    let tokenType: String
    let user: UserDTO
    let profile: ProfileDTO
}; extension DataDTO {
    func toDomain() -> AuthSession {
        return AuthSession(
            token: token,
            tokenType: tokenType,
            user: User(
                id: user.id,
                username: user.username,
                isAdmin: user.isAdmin
            ),
            profile: UserProfile(
                distributorId: profile.distribuidorId ?? -1,
                distributorName: profile.distribuidorNombre ?? "Sin distribuidor"
            )
        )
    }
}

struct MeResponseDTO: Codable {
    let ok: Bool
    let data: MeDataDTO?
}

struct MeDataDTO: Codable {
    let user: UserDTO
    let profile: ProfileDTO
}; extension MeDataDTO {
    func toDomain(with token: String) -> AuthSession {
        return AuthSession(
            token: token,
            tokenType: "Bearer",
            user: User(
                id: user.id,
                username: user.username,
                isAdmin: user.isAdmin
            ),
            profile: UserProfile(
                distributorId: profile.distribuidorId ?? -1,
                distributorName: profile.distribuidorNombre ?? "Sin distribuidor"
            )
        )
    }
}

struct UserDTO: Codable {
    let id: Int
    let username: String
    let isAdmin: Bool
}

struct ProfileDTO: Codable {
    let distribuidorId: Int?
    let distribuidorNombre: String?
}

struct ErrorDTO: Codable {
    let code: String?
    let message: String
}
