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
  service.delayNanoseconds = 10_000_000
  let changer = AppIconChanger<TestIcon>(applicationService: service)

  changer.changeIcon(to: .dark)
  await Task.yield()
  changer.changeIcon(to: .primary)

  try await Task.sleep(nanoseconds: 100_000_000)

  #expect(service.maximumConcurrentRequests == 1)
  #expect(service.requestedIconNames == [TestIcon.dark.iconName, TestIcon.primary.iconName])
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
  var delayNanoseconds: UInt64 = 0
  private(set) var activeRequests = 0
  private(set) var maximumConcurrentRequests = 0

  init(
    supportsAlternateIcons: Bool = true,
    alternateIconName: String? = nil
  ) {
    self.supportsAlternateIcons = supportsAlternateIcons
    self.alternateIconName = alternateIconName
  }

  func applyAlternateIconName(_ alternateIconName: String?) async throws {
    activeRequests += 1
    maximumConcurrentRequests = max(maximumConcurrentRequests, activeRequests)
    defer {
      activeRequests -= 1
    }

    requestedIconNames.append(alternateIconName)

    if delayNanoseconds > 0 {
      try await Task.sleep(nanoseconds: delayNanoseconds)
    }

    if let errorToThrow {
      throw errorToThrow
    }

    self.alternateIconName = alternateIconName
  }
}
