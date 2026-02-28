//
//  MockVerifierRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 27/02/26.
//

@testable import AriesFramework
import Foundation

final class MockVerifierRepository: VerifierRepository {
    private(set) var saveCalled = false
    private(set) var saved: [VerifierRecord] = []

    override func save(_ record: VerifierRecord) async throws {
        saveCalled = true
        saved.append(record)
    }
}
