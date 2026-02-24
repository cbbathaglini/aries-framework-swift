//
//  MockHistoryRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//

import Foundation
@testable import AriesFramework

final class MockHistoryRepository: HistoryRepository {

    private(set) var saveCalled = false
    private(set) var lastSaved: HistoryRecord?

    override func save(_ record: HistoryRecord) async throws {
        saveCalled = true
        lastSaved = record
    }
}
