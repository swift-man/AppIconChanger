import Testing
@testable import AppIconChanger

@MainActor
@Test func initializerReadsCurrentIconNameFromService() {
  let service = MockIconService(alternateIconName: TestIcon.dark.iconName)
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  #expect(changer.currentIconName == TestIcon.dark.iconName)
  #expect(changer.supportsAlternateIcons)
  #expect(changer.lastError == nil)
}

@MainActor
@Test func setIconUpdatesCurrentIconName() async throws {
  let service = MockIconService()
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  try await changer.setIcon(to: .dark)

  #expect(service.requestedIconNames == [TestIcon.dark.iconName])
  #expect(changer.currentIconName == TestIcon.dark.iconName)
  #expect(changer.lastError == nil)
}

@MainActor
@Test func setIconCanRestorePrimaryIcon() async throws {
  let service = MockIconService(alternateIconName: TestIcon.dark.iconName)
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  try await changer.setIcon(to: .primary)

  #expect(service.requestedIconNames == [nil])
  #expect(changer.currentIconName == nil)
  #expect(changer.lastError == nil)
}

@MainActor
@Test func setIconThrowsWhenAlternateIconsAreUnsupported() async {
  let service = MockIconService(supportsAlternateIcons: false)
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  await #expect(throws: AppIconChangerError.alternateIconsUnsupported) {
    try await changer.setIcon(to: .dark)
  }

  #expect(service.requestedIconNames.isEmpty)
  #expect(changer.currentIconName == nil)
  #expect(changer.lastError is AppIconChangerError)
}

@MainActor
@Test func setIconPreservesStateWhenServiceFails() async {
  let service = MockIconService(alternateIconName: TestIcon.dark.iconName)
  service.errorToThrow = MockIconError.failed
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  await #expect(throws: MockIconError.failed) {
    try await changer.setIcon(to: .primary)
  }

  #expect(service.requestedIconNames == [TestIcon.primary.iconName])
  #expect(changer.currentIconName == TestIcon.dark.iconName)
  #expect(changer.lastError is MockIconError)
}

@MainActor
@Test func changeIconSerializesRapidRequests() async throws {
  let service = MockIconService()
  service.shouldSuspendRequests = true
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  changer.changeIcon(to: .dark)
  await service.waitForRequestCount(1)

  changer.changeIcon(to: .primary)

  await Task.yield()

  #expect(service.requestedIconNames == [TestIcon.dark.iconName])

  service.resumeNextRequest()
  await service.waitForRequestCount(2)

  #expect(service.requestedIconNames == [TestIcon.dark.iconName, TestIcon.primary.iconName])

  service.resumeNextRequest()
  await service.waitUntilIdle()

  #expect(service.maximumConcurrentRequests == 1)
  #expect(changer.currentIconName == nil)
  #expect(changer.lastError == nil)
}

@MainActor
@Test func setIconSerializesConcurrentRequests() async throws {
  let service = MockIconService()
  service.shouldSuspendRequests = true
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  let firstTask = Task {
    try await changer.setIcon(to: .dark)
  }
  await service.waitForRequestCount(1)

  let secondTask = Task {
    try await changer.setIcon(to: .primary)
  }
  await Task.yield()

  #expect(service.requestedIconNames == [TestIcon.dark.iconName])

  service.resumeNextRequest()
  await service.waitForRequestCount(2)

  #expect(service.requestedIconNames == [TestIcon.dark.iconName, TestIcon.primary.iconName])

  service.resumeNextRequest()
  try await firstTask.value
  try await secondTask.value

  #expect(service.maximumConcurrentRequests == 1)
  #expect(changer.currentIconName == nil)
  #expect(changer.lastError == nil)
}

private enum TestIcon: String, CaseIterable, Identifiable, AppIconRepresentable {
  case primary
  case dark

  var id: String {
    rawValue
  }

  var iconName: String? {
    switch self {
    case .primary:
      nil
    case .dark:
      rawValue
    }
  }

  var displayName: String {
    rawValue
  }
}

private enum MockIconError: Error, Equatable {
  case failed
}

@MainActor
private final class MockIconService: AppIconServiceProtocol {
  var supportsAlternateIcons: Bool
  var alternateIconName: String?
  var requestedIconNames: [String?] = []
  var errorToThrow: (any Error)?
  var shouldSuspendRequests = false
  private(set) var activeRequests = 0
  private(set) var maximumConcurrentRequests = 0
  private var requestCountWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
  private var idleWaiters: [CheckedContinuation<Void, Never>] = []
  private var suspendedRequests: [CheckedContinuation<Void, Never>] = []

  init(
    supportsAlternateIcons: Bool = true,
    alternateIconName: String? = nil
  ) {
    self.supportsAlternateIcons = supportsAlternateIcons
    self.alternateIconName = alternateIconName
  }

  func waitForRequestCount(_ count: Int) async {
    guard requestedIconNames.count < count else { return }

    await withCheckedContinuation { continuation in
      requestCountWaiters.append((count, continuation))
    }
  }

  func waitUntilIdle() async {
    guard activeRequests > 0 else { return }

    await withCheckedContinuation { continuation in
      idleWaiters.append(continuation)
    }
  }

  func resumeNextRequest() {
    suspendedRequests.removeFirst().resume()
  }

  func applyAlternateIconName(_ alternateIconName: String?) async throws {
    activeRequests += 1
    maximumConcurrentRequests = max(maximumConcurrentRequests, activeRequests)
    defer {
      activeRequests -= 1
      resumeIdleWaitersIfNeeded()
    }

    requestedIconNames.append(alternateIconName)
    resumeRequestCountWaitersIfNeeded()

    if shouldSuspendRequests {
      await withCheckedContinuation { continuation in
        suspendedRequests.append(continuation)
      }
    }

    if let errorToThrow {
      throw errorToThrow
    }

    self.alternateIconName = alternateIconName
  }

  private func resumeRequestCountWaitersIfNeeded() {
    var remainingWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    for waiter in requestCountWaiters {
      if requestedIconNames.count >= waiter.count {
        waiter.continuation.resume()
      } else {
        remainingWaiters.append(waiter)
      }
    }

    requestCountWaiters = remainingWaiters
  }

  private func resumeIdleWaitersIfNeeded() {
    guard activeRequests == 0 else { return }

    let waiters = idleWaiters
    idleWaiters.removeAll()

    for waiter in waiters {
      waiter.resume()
    }
  }
}
