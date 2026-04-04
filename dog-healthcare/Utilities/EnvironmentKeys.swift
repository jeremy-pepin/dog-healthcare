import SwiftUI

private struct IsCloudKitActiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isCloudKitActive: Bool {
        get { self[IsCloudKitActiveKey.self] }
        set { self[IsCloudKitActiveKey.self] = newValue }
    }
}
