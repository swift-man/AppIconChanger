//
//  AppIconChangerError.swift
//  AppIconChanger
//
//  Created by SwiftMan on 6/14/26.
//

import Foundation

public enum AppIconChangerError: Error, Equatable {
  case alternateIconsUnsupported
}

extension AppIconChangerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .alternateIconsUnsupported:
      "Alternate app icons are not supported by this application."
    }
  }
}
