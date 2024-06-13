//
//  SnapshotLogger.swift
//  Meduza
//
//  Created by Samarenko Andrey on 12.06.2024.
//

import XCTest

private extension String {
    // Error prefixes
    static let errorPrefix: String =           "⛔️ [SNAPSHOT_TEST_EXECUTION_ERROR] ⛔️"
    static let errorComparisonPrefix: String = "⚠️ [SNAPSHOT_COMPARISON_FAIL] ⚠️"
    static let errorRecordModePrefix: String = "✅ [RECORD_MODE_ON] ✅"
    // Attachment names
    static let referenceAttachment: String = "Reference Image"
    static let renderedAttachment: String = "Rendered Image"
    static let diffAttachment: String = "Diff Image"
}

enum ErrorType {
    case executionError
    case comparisonError
    case recordModeError
}

final class SnapshotLogger {
    
    // MARK: - Initialization
    // Экземпляр класса создавать нельзя
    private init() {}

    // MARK: - Internal
    
    static func format(
        _ errorLocalizedDescription: String,
        errorType: ErrorType
    ) -> String {
        let descriptionMark: String
        switch errorType {
        case .executionError:
            descriptionMark = String.errorPrefix
        case .comparisonError:
            descriptionMark = String.errorComparisonPrefix
        case .recordModeError:
            descriptionMark = String.errorRecordModePrefix
        }
        
        return "\n\(descriptionMark)\n\(errorLocalizedDescription)\n\(descriptionMark)\n"
    }
    
    static func logFailedComparison(
        activityName: String,
        _ recordedImage: UIImage,
        _ renderedImage: UIImage,
        _ diffImage: UIImage
    ) {
        XCTContext.runActivity(named: activityName) { activity in
            let referenceAttachment = XCTAttachment(image: recordedImage)
            referenceAttachment.name = String.referenceAttachment
                        
            let renderedAttachment = XCTAttachment(image: renderedImage)
            renderedAttachment.name = String.renderedAttachment
            
            let diffAttachment = XCTAttachment(image: diffImage)
            diffAttachment.name = String.diffAttachment
            
            activity.add(referenceAttachment)
            activity.add(renderedAttachment)
            activity.add(diffAttachment)
        }
    }
}

extension String {
    
    func format(as errorType: ErrorType) -> Self {
        return SnapshotLogger.format(self, errorType: errorType)
    }
}

