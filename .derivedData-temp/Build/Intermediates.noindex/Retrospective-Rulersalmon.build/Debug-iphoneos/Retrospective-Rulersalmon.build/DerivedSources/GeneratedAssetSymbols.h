#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"DevPaul.Retrospective-Rulersalmon";

/// The "Blue50" asset catalog color resource.
static NSString * const ACColorNameBlue50 AC_SWIFT_PRIVATE = @"Blue50";

/// The "Blue500" asset catalog color resource.
static NSString * const ACColorNameBlue500 AC_SWIFT_PRIVATE = @"Blue500";

/// The "Blue600" asset catalog color resource.
static NSString * const ACColorNameBlue600 AC_SWIFT_PRIVATE = @"Blue600";

/// The "Gray200" asset catalog color resource.
static NSString * const ACColorNameGray200 AC_SWIFT_PRIVATE = @"Gray200";

/// The "Gray300" asset catalog color resource.
static NSString * const ACColorNameGray300 AC_SWIFT_PRIVATE = @"Gray300";

/// The "Gray50" asset catalog color resource.
static NSString * const ACColorNameGray50 AC_SWIFT_PRIVATE = @"Gray50";

/// The "Gray600" asset catalog color resource.
static NSString * const ACColorNameGray600 AC_SWIFT_PRIVATE = @"Gray600";

/// The "Gray900" asset catalog color resource.
static NSString * const ACColorNameGray900 AC_SWIFT_PRIVATE = @"Gray900";

/// The "Gommin" asset catalog image resource.
static NSString * const ACImageNameGommin AC_SWIFT_PRIVATE = @"Gommin";

/// The "Howard" asset catalog image resource.
static NSString * const ACImageNameHoward AC_SWIFT_PRIVATE = @"Howard";

/// The "MK" asset catalog image resource.
static NSString * const ACImageNameMK AC_SWIFT_PRIVATE = @"MK";

/// The "MentorImg" asset catalog image resource.
static NSString * const ACImageNameMentorImg AC_SWIFT_PRIVATE = @"MentorImg";

#undef AC_SWIFT_PRIVATE
