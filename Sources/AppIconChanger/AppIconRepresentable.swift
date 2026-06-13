//
//  AppIconRepresentable.swift
//  AppIconChanger
//
//  Created by SwiftMan on 6/14/26.
//

import Foundation

@available(macOS 10.15, *)
public protocol AppIconRepresentable: CaseIterable, Identifiable, Equatable, Sendable {
  var iconName: String? { get }
  var displayName: String { get }
}

@MainActor
@available(macOS 10.15, *)
public protocol AppIconServiceProtocol: AnyObject {
  var supportsAlternateIcons: Bool { get }
  var alternateIconName: String? { get }

  func applyAlternateIconName(_ alternateIconName: String?) async throws
}
