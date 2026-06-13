//
//  AppIconChanger.swift
//  AppIconChanger
//
//  Created by SwiftMan on 6/14/26.
//

import Combine
import Foundation

@MainActor
public final class AppIconChanger<Icon: AppIconRepresentable>: ObservableObject {
  @Published public private(set) var currentIconName: String?
  @Published public private(set) var lastError: (any Error)?

  private let applicationService: AppIconServiceProtocol
  private var pendingIcon: Icon?
  private var iconChangeTask: Task<Void, Never>?
  private var isSettingIcon = false
  private var iconOperationWaiters: [CheckedContinuation<Void, Never>] = []

  public var supportsAlternateIcons: Bool {
    applicationService.supportsAlternateIcons
  }

  public init(applicationService: AppIconServiceProtocol) {
    self.applicationService = applicationService
    self.currentIconName = applicationService.alternateIconName
  }

  public func setIcon(to icon: Icon) async throws {
    await waitForIconOperationTurn()
    defer {
      finishIconOperationTurn()
    }

    try Task.checkCancellation()
    try await applyIcon(to: icon)
  }

  private func applyIcon(to icon: Icon) async throws {
    guard supportsAlternateIcons else {
      let error = AppIconChangerError.alternateIconsUnsupported
      lastError = error
      throw error
    }

    do {
      try await applicationService.applyAlternateIconName(icon.iconName)
      currentIconName = applicationService.alternateIconName
      lastError = nil
    } catch {
      lastError = error
      throw error
    }
  }

  public func changeIcon(to icon: Icon) {
    pendingIcon = icon

    guard iconChangeTask == nil else { return }

    iconChangeTask = Task {
      await processPendingIconChanges()
    }
  }

  private func processPendingIconChanges() async {
    defer {
      iconChangeTask = nil
    }

    while let icon = pendingIcon {
      pendingIcon = nil

      do {
        try await setIcon(to: icon)
      } catch {
        // setIcon(to:) records lastError before throwing.
      }
    }
  }

  private func waitForIconOperationTurn() async {
    guard isSettingIcon else {
      isSettingIcon = true
      return
    }

    await withCheckedContinuation { continuation in
      iconOperationWaiters.append(continuation)
    }
  }

  private func finishIconOperationTurn() {
    guard !iconOperationWaiters.isEmpty else {
      isSettingIcon = false
      return
    }

    iconOperationWaiters.removeFirst().resume()
  }
}
