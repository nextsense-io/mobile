#import "NextsenseBasePlugin.h"
#if __has_include(<nextsense_base/nextsense_base-Swift.h>)
#import <nextsense_base/nextsense_base-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "nextsense_base-Swift.h"
#endif

@implementation NextsenseBasePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNextsenseBasePlugin registerWithRegistrar:registrar];
}
@end
