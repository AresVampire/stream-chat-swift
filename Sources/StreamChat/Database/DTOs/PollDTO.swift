//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PollDTO)
class PollDTO: NSManagedObject {
    @NSManaged var allowAnswers: Bool
    @NSManaged var allowUserSuggestedOptions: Bool
    @NSManaged var answersCount: Int
    @NSManaged var createdAt: DBDate
    @NSManaged var createdById: String
    @NSManaged var pollDescription: String
    @NSManaged var enforceUniqueVote: Bool
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var updatedAt: DBDate
    @NSManaged var voteCount: Int
    @NSManaged var custom: Data?
    @NSManaged var voteCountsByOption: [String: Int]?
    @NSManaged var isClosed: Bool
    @NSManaged var maxVotesAllowed: Int
    @NSManaged var votingVisibility: String?
    @NSManaged var createdBy: UserDTO?
    @NSManaged var latestAnswers: Set<PollVoteDTO>
    @NSManaged var message: MessageDTO?
    @NSManaged var options: Set<PollOptionDTO>
    @NSManaged var latestVotesByOption: Set<PollOptionDTO>
    
    static func loadOrCreate(
        pollId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollDTO {
//        if let cachedObject = cache?.model(for: pollId, context: context, type: PollDTO.self) {
//            return cachedObject
//        }
        let request = fetchRequest(for: pollId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = pollId
        return new
    }
    
    static func fetchRequest(for pollId: String) -> NSFetchRequest<PollDTO> {
        let request = NSFetchRequest<PollDTO>(entityName: PollDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", pollId)
        return request
    }
}

extension PollDTO {
    func asModel() throws -> Poll {
        var customData: [String: RawJSON] = [:]
        if let custom, !custom.isEmpty {
            do {
                customData = try JSONDecoder.default.decode([String: RawJSON].self, from: custom)
            } catch {
                log
                    .error(
                        "Failed to decode custom data for poll option with id: <\(id)>, using default value instead. Error: \(error)"
                    )
            }
        }
        return try Poll(
            allowAnswers: allowAnswers,
            allowUserSuggestedOptions: allowUserSuggestedOptions,
            answersCount: answersCount,
            createdAt: createdAt.bridgeDate,
            createdById: createdById,
            pollDescription: pollDescription,
            enforceUniqueVote: enforceUniqueVote,
            id: id,
            name: name,
            updatedAt: updatedAt.bridgeDate,
            voteCount: voteCount,
            custom: customData,
            voteCountsByOption: voteCountsByOption,
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            votingVisibility: votingVisibility,
            createdBy: createdBy?.asModel(),
            latestAnswers: latestAnswers.map { try $0.asModel() },
            options: options.map { try $0.asModel() },
            latestVotesByOption: latestVotesByOption.map { try $0.asModel() }
        )
    }
}

extension NSManagedObjectContext {
    func savePoll(payload: PollPayload, cache: PreWarmedCache?) throws -> PollDTO {
        let pollDto = PollDTO.loadOrCreate(pollId: payload.id, context: self, cache: cache)
        pollDto.createdBy = UserDTO.loadOrCreate(id: payload.createdById, context: self, cache: cache)
        pollDto.options = try Set(
            payload.options.compactMap { payload in
                if let payload {
                    let optionDto = try savePollOption(
                        payload: payload,
                        pollId: payload.id,
                        cache: cache
                    )
                    return optionDto
                } else {
                    return nil
                }
            }
        )
        pollDto.latestVotesByOption = try Set(
            payload.latestVotesByOption.compactMap { optionId, votesByOption in
                let optionDto = PollOptionDTO.loadOrCreate(
                    pollId: payload.id,
                    optionId: optionId,
                    context: self,
                    cache: cache
                )
                
                optionDto.latestVotes = Set(
                    try votesByOption.compactMap { vote in
                        if let vote {
                            return try savePollVote(payload: vote, cache: cache)
                        } else {
                            return nil
                        }
                    }
                )
                
                return optionDto
            }
        )
        pollDto.latestAnswers = try Set(
            payload.latestAnswers?.compactMap { payload in
                if let payload {
                    let answerDto = try savePollVote(payload: payload, cache: cache)
                    return answerDto
                } else {
                    return nil
                }
            } ?? []
        )
        
        pollDto.allowAnswers = payload.allowAnswers
        pollDto.allowUserSuggestedOptions = payload.allowUserSuggestedOptions
        pollDto.answersCount = payload.answersCount
        pollDto.createdAt = payload.createdAt.bridgeDate
        pollDto.createdById = payload.createdById
        pollDto.pollDescription = payload.description
        pollDto.enforceUniqueVote = payload.enforceUniqueVote
        pollDto.id = payload.id
        pollDto.name = payload.name
        pollDto.updatedAt = payload.updatedAt.bridgeDate
        pollDto.voteCount = payload.voteCount
        pollDto.custom = try JSONEncoder.default.encode(payload.custom)
        pollDto.voteCountsByOption = payload.voteCountsByOption
        pollDto.isClosed = payload.isClosed ?? false
        pollDto.maxVotesAllowed = payload.maxVotesAllowed ?? 1
        pollDto.votingVisibility = payload.votingVisibility
        
        return pollDto
    }
}
