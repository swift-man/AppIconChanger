//
//  AppIconRepresentable.swift
//  AppIconChanger
//
//  Created by SwiftMan on 6/14/26.
//

import Foundation

public protocol AppIconRepresentable: Sendable {
  var iconName: String? { get }
  var displayName: String { get }
}

@MainActor
public protocol AppIconServiceProtocol: AnyObject {
  var supportsAlternateIcons: Bool { get }
  var alternateIconName: String? { get }

  func applyAlternateIconName(_ alternateIconName: String?) async throws
}
