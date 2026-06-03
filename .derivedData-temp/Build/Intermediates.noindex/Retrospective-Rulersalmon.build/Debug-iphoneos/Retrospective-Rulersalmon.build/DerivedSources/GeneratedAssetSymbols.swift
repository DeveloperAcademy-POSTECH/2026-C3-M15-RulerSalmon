import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Blue50" asset catalog color resource.
    static let blue50 = DeveloperToolsSupport.ColorResource(name: "Blue50", bundle: resourceBundle)

    /// The "Blue500" asset catalog color resource.
    static let blue500 = DeveloperToolsSupport.ColorResource(name: "Blue500", bundle: resourceBundle)

    /// The "Blue600" asset catalog color resource.
    static let blue600 = DeveloperToolsSupport.ColorResource(name: "Blue600", bundle: resourceBundle)

    /// The "Gray200" asset catalog color resource.
    static let gray200 = DeveloperToolsSupport.ColorResource(name: "Gray200", bundle: resourceBundle)

    /// The "Gray300" asset catalog color resource.
    static let gray300 = DeveloperToolsSupport.ColorResource(name: "Gray300", bundle: resourceBundle)

    /// The "Gray50" asset catalog color resource.
    static let gray50 = DeveloperToolsSupport.ColorResource(name: "Gray50", bundle: resourceBundle)

    /// The "Gray600" asset catalog color resource.
    static let gray600 = DeveloperToolsSupport.ColorResource(name: "Gray600", bundle: resourceBundle)

    /// The "Gray900" asset catalog color resource.
    static let gray900 = DeveloperToolsSupport.ColorResource(name: "Gray900", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Gommin" asset catalog image resource.
    static let gommin = DeveloperToolsSupport.ImageResource(name: "Gommin", bundle: resourceBundle)

    /// The "Howard" asset catalog image resource.
    static let howard = DeveloperToolsSupport.ImageResource(name: "Howard", bundle: resourceBundle)

    /// The "MK" asset catalog image resource.
    static let MK = DeveloperToolsSupport.ImageResource(name: "MK", bundle: resourceBundle)

    /// The "MentorImg" asset catalog image resource.
    @available(watchOS, unavailable)
    static let mentorImg = DeveloperToolsSupport.ImageResource(thinnableName: "MentorImg", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "Blue50" asset catalog color.
    static var blue50: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blue50)
#else
        .init()
#endif
    }

    /// The "Blue500" asset catalog color.
    static var blue500: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blue500)
#else
        .init()
#endif
    }

    /// The "Blue600" asset catalog color.
    static var blue600: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .blue600)
#else
        .init()
#endif
    }

    /// The "Gray200" asset catalog color.
    static var gray200: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gray200)
#else
        .init()
#endif
    }

    /// The "Gray300" asset catalog color.
    static var gray300: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gray300)
#else
        .init()
#endif
    }

    /// The "Gray50" asset catalog color.
    static var gray50: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gray50)
#else
        .init()
#endif
    }

    /// The "Gray600" asset catalog color.
    static var gray600: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gray600)
#else
        .init()
#endif
    }

    /// The "Gray900" asset catalog color.
    static var gray900: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gray900)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "Blue50" asset catalog color.
    static var blue50: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .blue50)
#else
        .init()
#endif
    }

    /// The "Blue500" asset catalog color.
    static var blue500: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .blue500)
#else
        .init()
#endif
    }

    /// The "Blue600" asset catalog color.
    static var blue600: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .blue600)
#else
        .init()
#endif
    }

    /// The "Gray200" asset catalog color.
    static var gray200: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gray200)
#else
        .init()
#endif
    }

    /// The "Gray300" asset catalog color.
    static var gray300: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gray300)
#else
        .init()
#endif
    }

    /// The "Gray50" asset catalog color.
    static var gray50: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gray50)
#else
        .init()
#endif
    }

    /// The "Gray600" asset catalog color.
    static var gray600: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gray600)
#else
        .init()
#endif
    }

    /// The "Gray900" asset catalog color.
    static var gray900: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .gray900)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "Blue50" asset catalog color.
    static var blue50: SwiftUI.Color { .init(.blue50) }

    /// The "Blue500" asset catalog color.
    static var blue500: SwiftUI.Color { .init(.blue500) }

    /// The "Blue600" asset catalog color.
    static var blue600: SwiftUI.Color { .init(.blue600) }

    /// The "Gray200" asset catalog color.
    static var gray200: SwiftUI.Color { .init(.gray200) }

    /// The "Gray300" asset catalog color.
    static var gray300: SwiftUI.Color { .init(.gray300) }

    /// The "Gray50" asset catalog color.
    static var gray50: SwiftUI.Color { .init(.gray50) }

    /// The "Gray600" asset catalog color.
    static var gray600: SwiftUI.Color { .init(.gray600) }

    /// The "Gray900" asset catalog color.
    static var gray900: SwiftUI.Color { .init(.gray900) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "Blue50" asset catalog color.
    static var blue50: SwiftUI.Color { .init(.blue50) }

    /// The "Blue500" asset catalog color.
    static var blue500: SwiftUI.Color { .init(.blue500) }

    /// The "Blue600" asset catalog color.
    static var blue600: SwiftUI.Color { .init(.blue600) }

    /// The "Gray200" asset catalog color.
    static var gray200: SwiftUI.Color { .init(.gray200) }

    /// The "Gray300" asset catalog color.
    static var gray300: SwiftUI.Color { .init(.gray300) }

    /// The "Gray50" asset catalog color.
    static var gray50: SwiftUI.Color { .init(.gray50) }

    /// The "Gray600" asset catalog color.
    static var gray600: SwiftUI.Color { .init(.gray600) }

    /// The "Gray900" asset catalog color.
    static var gray900: SwiftUI.Color { .init(.gray900) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Gommin" asset catalog image.
    static var gommin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .gommin)
#else
        .init()
#endif
    }

    /// The "Howard" asset catalog image.
    static var howard: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .howard)
#else
        .init()
#endif
    }

    /// The "MK" asset catalog image.
    static var MK: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .MK)
#else
        .init()
#endif
    }

    /// The "MentorImg" asset catalog image.
    static var mentorImg: AppKit.NSImage? {
#if !targetEnvironment(macCatalyst)
        .init(thinnableResource: .mentorImg)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Gommin" asset catalog image.
    static var gommin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .gommin)
#else
        .init()
#endif
    }

    /// The "Howard" asset catalog image.
    static var howard: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .howard)
#else
        .init()
#endif
    }

    /// The "MK" asset catalog image.
    static var MK: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .MK)
#else
        .init()
#endif
    }

    /// The "MentorImg" asset catalog image.
    static var mentorImg: UIKit.UIImage? {
#if !os(watchOS)
        .init(thinnableResource: .mentorImg)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

