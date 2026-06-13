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

  init(
    supportsAlternateIcons: Bool = true,
    alternateIconName: String? = nil
  ) {
    self.supportsAlternateIcons = supportsAlternateIcons
    self.alternateIconName = alternateIconName
  }

  func setAlternateIconName(_ alternateIconName: String?) async throws {
    requestedIconNames.append(alternateIconName)

    if let errorToThrow {
      throw errorToThrow
    }

    self.alternateIconName = alternateIconName
  }
}
