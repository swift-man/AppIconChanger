//
//  AppIconRepresentable.swift
//  AppIconChanger
//
//  Created by SwiftMan on 6/14/26.
//

import Foundation

public protocol AppIconRepresentable: CaseIterable, Identifiable, Equatable {
  var iconName: String? { get }
  var displayName: String { get }
}

@MainActor
public protocol AppIconServiceProtocol: AnyObject {
  var supportsAlternateIcons: Bool { get }
  var alternateIconName: String? { get }

  func setAlternateIconName(_ alternateIconName: String?) async throws
}

@available(*, deprecated, renamed: "AppIconServiceProtocol")
public typealias URLIconServiceProtocol = AppIconServiceProtocol
