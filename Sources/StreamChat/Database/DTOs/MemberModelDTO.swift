//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

@objc(MemberDTO)
class MemberDTO: NSManagedObject {
    // Because we need to have a unique identifier of a member in the db, we use the combination of the related
    // user' id and the channel the member belongs to.
    @NSManaged fileprivate(set) var id: String

    // This value is optional only temprorary until this is fixed https://getstream.slack.com/archives/CE5N802GP/p1592925726015900
    @NSManaged var channelRoleRaw: String?
    @NSManaged var memberCreatedAt: DBDate
    @NSManaged var memberUpdatedAt: DBDate

    @NSManaged var banExpiresAt: DBDate?
    @NSManaged var isBanned: Bool
    @NSManaged var isShadowBanned: Bool
    @NSManaged var notificationsMuted: Bool

    @NSManaged var inviteAcceptedAt: DBDate?
    @NSManaged var inviteRejectedAt: DBDate?
    @NSManaged var isInvited: Bool

    // MARK: - Relationships

    @NSManaged var user: UserDTO
    @NSManaged var queries: Set<ChannelMemberListQueryDTO>
    @NSManaged var channel: ChannelDTO

    private static func createId(userId: String, channeldId: ChannelId) -> String {
        channeldId.rawValue + userId
    }
}

// MARK: - Fetch requests

extension MemberDTO {
    /// Returns a fetch request for the dto with the provided `userId`.
    static func member(_ userId: UserId, in cid: ChannelId) -> NSFetchRequest<MemberDTO> {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MemberDTO.memberCreatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "id == %@", Self.createId(userId: userId, channeldId: cid))
        return request
    }

    /// Returns a fetch request for the DTOs matching the provided `query`.
    static func members(matching query: ChannelMemberListQuery) -> NSFetchRequest<MemberDTO> {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "ANY queries.queryHash == %@", query.queryHash)
        request.sortDescriptors = query.sortDescriptors
        return request
    }
}

extension MemberDTO {
    static func load(userId: String, channelId: ChannelId, context: NSManagedObjectContext) -> MemberDTO? {
        let memberId = MemberDTO.createId(userId: userId, channeldId: channelId)
        return load(memberId: memberId, context: context)
    }

    static func load(memberId: String, context: NSManagedObjectContext) -> MemberDTO? {
        load(by: memberId, context: context).first
    }

    /// If a User with the given id exists in the context, fetches and returns it. Otherwise create a new
    /// `UserDTO` with the given id.
    ///
    /// - Parameters:
    ///   - id: The id of the user to fetch
    ///   - context: The context used to fetch/create `UserDTO`
    ///
    static func loadOrCreate(
        userId: String,
        channelId: ChannelId,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> MemberDTO {
        let memberId = MemberDTO.createId(userId: userId, channeldId: channelId)
        if let cachedObject = cache?.model(for: memberId, context: context, type: MemberDTO.self) {
            return cachedObject
        }

        if let existing = load(memberId: memberId, context: context) {
            return existing
        }

        let request = fetchRequest(id: memberId)
        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = memberId
        return new
    }

    static func loadLastActiveMembers(cid: ChannelId, context: NSManagedObjectContext) -> [MemberDTO] {
        let request = NSFetchRequest<MemberDTO>(entityName: MemberDTO.entityName)
        request.predicate = NSPredicate(format: "channel.cid == %@", cid.rawValue)
        request.sortDescriptors = [
            ChannelMemberListSortingKey.lastActiveSortDescriptor,
            ChannelMemberListSortingKey.defaultSortDescriptor
        ]
        request.fetchLimit = context.localCachingSettings?.chatChannel.lastActiveMembersLimit ?? 100
        return load(by: request, context: context)
    }
}

extension NSManagedObjectContext {
    func saveMember(
        payload: ChannelMember,
        channelId: ChannelId,
        query: ChannelMemberListQuery?,
        cache: PreWarmedCache?
    ) throws -> MemberDTO {
        let dto = MemberDTO.loadOrCreate(userId: payload.userId ?? .newUniqueId, channelId: channelId, context: self, cache: cache)

        // Save user-part of member first
        if let userPayload = payload.user {
            dto.user = try saveUser(payload: userPayload, query: nil, cache: cache)
        }

        // Save member specific data
        dto.channelRoleRaw = payload.channelRole

        dto.memberCreatedAt = payload.createdAt.bridgeDate
        dto.memberUpdatedAt = payload.updatedAt.bridgeDate
        dto.isBanned = payload.banned
        dto.isShadowBanned = payload.shadowBanned
        dto.banExpiresAt = payload.banExpires?.bridgeDate
        dto.isInvited = payload.invited ?? false
        dto.inviteAcceptedAt = payload.inviteAcceptedAt?.bridgeDate
        dto.inviteRejectedAt = payload.inviteRejectedAt?.bridgeDate
//        dto.notificationsMuted = payload.notificationsMuted //TODO: missing

        if let query = query {
            let queryDTO = try saveQuery(query)
            queryDTO.members.insert(dto)
        }

        if let channelDTO = channel(cid: channelId) {
            channelDTO.members.insert(dto)
        }

        return dto
    }
    
    func saveMembers(
        payload: MembersResponse,
        channelId: ChannelId,
        query: ChannelMemberListQuery?
    ) -> [MemberDTO] {
        let cache = payload.getPayloadToModelIdMappings(context: self)
        return payload.members.compactMapLoggingError {
            if let member = $0 {
                return try saveMember(payload: member, channelId: channelId, query: query, cache: cache)
            } else {
                return nil
            }
        }
    }
    
    func member(userId: UserId, cid: ChannelId) -> MemberDTO? {
        MemberDTO.load(userId: userId, channelId: cid, context: self)
    }
}

extension MemberDTO {
    func asModel() throws -> ChatChannelMember { try .create(fromDTO: self) }
}

extension ChatChannelMember {
    fileprivate static func create(fromDTO dto: MemberDTO) throws -> ChatChannelMember {
        let extraData: [String: RawJSON]
        do {
            extraData = try JSONDecoder.default.decode([String: RawJSON].self, from: dto.user.extraData)
        } catch {
            log.error(
                "Failed to decode extra data for user with id: <\(dto.user.id)>, using default value instead. "
                    + "Error: \(error)"
            )
            extraData = [:]
        }

        let role = dto.channelRoleRaw.flatMap { MemberRole(rawValue: $0) } ?? .member
        let language: TranslationLanguage? = dto.user.language.map(TranslationLanguage.init)

        return ChatChannelMember(
            id: dto.user.id,
            name: dto.user.name,
            imageURL: dto.user.imageURL,
            isOnline: dto.user.isOnline,
            isBanned: dto.user.isBanned,
            isFlaggedByCurrentUser: dto.user.flaggedBy != nil,
            userRole: UserRole(rawValue: dto.user.userRoleRaw),
            userCreatedAt: dto.user.userCreatedAt.bridgeDate,
            userUpdatedAt: dto.user.userUpdatedAt.bridgeDate,
            deactivatedAt: dto.user.userDeactivatedAt?.bridgeDate,
            lastActiveAt: dto.user.lastActivityAt?.bridgeDate,
            teams: Set(dto.user.teams),
            language: language,
            extraData: extraData,
            memberRole: role,
            memberCreatedAt: dto.memberCreatedAt.bridgeDate,
            memberUpdatedAt: dto.memberUpdatedAt.bridgeDate,
            isInvited: dto.isInvited,
            inviteAcceptedAt: dto.inviteAcceptedAt?.bridgeDate,
            inviteRejectedAt: dto.inviteRejectedAt?.bridgeDate,
            isBannedFromChannel: dto.isBanned,
            banExpiresAt: dto.banExpiresAt?.bridgeDate,
            isShadowBannedFromChannel: dto.isShadowBanned,
            notificationsMuted: dto.notificationsMuted
        )
    }
}

extension ChannelMemberListQuery {
    var sortDescriptors: [NSSortDescriptor] {
        let sortDescriptors = sort.compactMap { $0.key.sortDescriptor(isAscending: $0.isAscending) }
        return sortDescriptors.isEmpty ? [ChannelMemberListSortingKey.defaultSortDescriptor] : sortDescriptors
    }
}
