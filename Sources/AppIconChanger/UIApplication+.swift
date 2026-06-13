//
//  UIApplication+.swift
//  AppIconChanger
//
//  Created by SwiftMan on 6/14/26.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIApplication: AppIconServiceProtocol {
  @MainActor
  public func applyAlternateIconName(_ alternateIconName: String?) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      setAlternateIconName(alternateIconName) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }
}

extension AppIconChanger {
  @available(iOSApplicationExtension, unavailable)
  public convenience init() {
    self.init(applicationService: UIApplication.shared)
  }
}
#endif
