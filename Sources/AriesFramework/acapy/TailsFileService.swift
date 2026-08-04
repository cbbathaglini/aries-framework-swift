//
//  TailsFileService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public protocol TailsFileService {
    
   
    func getTailsBasePath() async throws -> String

    func uploadTailsFile(
        options: UploadTailsFileOptions
    ) async throws -> UploadTailsFileResult

    func getTailsFile(
        options: GetTailsFileOptions
    ) async throws -> GetTailsFileResult
}
