//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

@objc(PollOptionDTO)
class PollOptionDTO: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var text: String
    @NSManaged var custom: Data?
    @NSManaged var poll: PollDTO?
    @NSManaged var latestVotes: Set<PollVoteDTO>
    
    static func loadOrCreate(
        pollId: String,
        optionId: String,
        context: NSManagedObjectContext,
        cache: PreWarmedCache?
    ) -> PollOptionDTO {
        let request = fetchRequest(for: optionId)
        if let existing = load(by: request, context: context).first {
            return existing
        }

        let new = NSEntityDescription.insertNewObject(into: context, for: request)
        new.id = optionId
        return new
    }
    
    static func fetchRequest(for optionId: String) -> NSFetchRequest<PollOptionDTO> {
        let request = NSFetchRequest<PollOptionDTO>(entityName: PollOptionDTO.entityName)
        request.predicate = NSPredicate(format: "id == %@", optionId)
        return request
    }
}

extension PollOptionDTO {
    func asModel() throws -> PollOption {
        var customData: [String: RawJSON] = [:]
        if let custom,
           !custom.isEmpty,
           let decoded = try? JSONDecoder.default.decode([String: RawJSON].self, from: custom) {
            customData = decoded
        }
        return PollOption(
            id: id,
            text: text,
            latestVotes: try latestVotes.map { try $0.asModel() },
            custom: customData
        )
    }
}

extension NSManagedObjectContext {
    func savePollOption(
        payload: PollOptionPayload,
        pollId: String,
        cache: PreWarmedCache?
    ) throws -> PollOptionDTO {
        let dto = PollOptionDTO.loadOrCreate(
            pollId: pollId,
            optionId: payload.id,
            context: self,
            cache: cache
        )
        dto.text = payload.text
        dto.custom = try JSONEncoder.default.encode(payload.custom)
        return dto
    }
}
