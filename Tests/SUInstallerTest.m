//
//  SUInstallerTest.m
//  Sparkle
//
//  Created by Kornel on 24/04/2015.
//  Copyright (c) 2015 Sparkle Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "SUHost.h"
#import "SUInstaller.h"
#import "SUPlainInstaller.h"
#import "SUErrors.h"
#import "SPUInstallationInputData.h"
#import "SUSignatures.h"
#import "SUInstallerProtocol.h"
#import "SPUInstallationType.h"
#import <unistd.h>

@interface SUInstallerTest : XCTestCase

@end

@implementation SUInstallerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExplicitVersionReplacementAuthorization
{
    // A selected build may move backward/equal/forward; absent authorization keeps
    // downgrade protection, and authorization for one version cannot install another.
    NSArray<NSArray *> *cases = @[
        @[@"20", @"10", NSNull.null, @NO],
        @[@"20", @"10", @"10", @YES],
        @[@"20", @"20", @"20", @YES],
        @[@"20", @"30", @"30", @YES],
        @[@"20", @"10", @"11", @NO],
        @[@"20", @"30", @"10", @NO],
        @[@"20", @"", @"", @NO],
    ];
    NSFileManager *manager = NSFileManager.defaultManager;
    for (NSArray *entry in cases) {
        NSURL *root = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]];
        NSURL *hostURL = [root URLByAppendingPathComponent:@"Host.app"];
        NSURL *updateURL = [root URLByAppendingPathComponent:@"Update.app"];
        for (NSArray *bundleEntry in @[@[hostURL, entry[0]], @[updateURL, entry[1]]]) {
            NSURL *contentsURL = [bundleEntry[0] URLByAppendingPathComponent:@"Contents"];
            XCTAssertTrue([manager createDirectoryAtURL:contentsURL withIntermediateDirectories:YES attributes:nil error:NULL]);
            NSMutableDictionary *info = [@{@"CFBundleIdentifier": @"app.sakuracord.installer-test", @"CFBundlePackageType": @"APPL"} mutableCopy];
            if ([bundleEntry[1] length] > 0) info[@"CFBundleVersion"] = bundleEntry[1];
            XCTAssertTrue([info writeToURL:[contentsURL URLByAppendingPathComponent:@"Info.plist"] atomically:YES]);
        }
        SUHost *host = [[SUHost alloc] initWithBundle:[NSBundle bundleWithURL:hostURL]];
        NSString *requested = entry[2] == NSNull.null ? nil : entry[2];
        SUPlainInstaller *installer = [[SUPlainInstaller alloc] initWithHost:host bundlePath:updateURL.path installationPath:hostURL.path explicitlyRequestedVersion:requested];
        NSError *error = nil;
        BOOL installed = [installer performInitialInstallation:&error];
        XCTAssertEqual(installed, [entry[3] boolValue], @"%@", entry);
        if (!installed) XCTAssertEqual(error.code, SUDowngradeError);
        [installer performCleanup];
        XCTAssertTrue([manager removeItemAtURL:root error:NULL]);
    }
}

- (void)testExplicitVersionAuthorizationSecureCoding
{
    SUSignatures *signatures = [[SUSignatures alloc] initWithEd:nil
#if SPARKLE_BUILD_LEGACY_DSA_SUPPORT
                                                        dsa:nil
#endif
    ];
    for (NSString *requested in @[@"10", @"11", @""]) {
        SPUInstallationInputData *input = [[SPUInstallationInputData alloc] initWithRelaunchPath:@"/Applications/Test.app" hostBundlePath:@"/Applications/Test.app" updateURLBookmarkData:NSData.data installationType:SPUInstallationTypeApplication signatures:signatures decryptionPassword:nil expectedVersion:@"10" expectedContentLength:123];
        input.explicitlyRequestedVersion = requested;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:input requiringSecureCoding:YES error:NULL];
        NSError *decodingError = nil;
        SPUInstallationInputData *decoded = [NSKeyedUnarchiver unarchivedObjectOfClass:SPUInstallationInputData.class fromData:data error:&decodingError];
        if ([requested isEqualToString:@"10"]) {
            XCTAssertEqualObjects(decoded.explicitlyRequestedVersion, @"10", @"%@", decodingError);
        } else {
            XCTAssertNil(decoded);
        }
    }
}

#if SPARKLE_BUILD_PACKAGE_SUPPORT
- (void)testInstallIfRoot
{
    uid_t uid = getuid();

    if (uid != 0) {
        NSLog(@"Test must be run as root: sudo xcodebuild -project Sparkle.xcodeproj -scheme Sparkle '-only-testing:Sparkle Unit Tests/SUInstallerTest/testInstallIfRoot' test");
        return;
    }

    NSString *expectedDestination = @"/tmp/sparklepkgtest.app";
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:expectedDestination error:nil];
    XCTAssertFalse([fm fileExistsAtPath:expectedDestination isDirectory:nil]);

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"test" ofType:@"pkg"];
    XCTAssertNotNil(path);

    SUHost *host = [[SUHost alloc] initWithBundle:bundle];

    NSError *installerError = nil;
    // Note: we may not be using the "correct" home directory or user name (they will be root) but our test pkg does not have
    // pre/post install scripts so it doesn't matter
    id<SUInstallerProtocol> installer = [SUInstaller installerForHost:host expectedInstallationType:SPUInstallationTypeGuidedPackage updateDirectory:[path stringByDeletingLastPathComponent] connectionCodeSigningValidationSkipped:NO homeDirectory:NSHomeDirectory() userName:NSUserName() explicitlyRequestedVersion:nil error:&installerError];
    
    if (installer == nil) {
        XCTFail(@"Installer is nil with error: %@", installerError);
        return;
    }
    
    NSError *initialInstallError = nil;
    if (![installer performInitialInstallation:&initialInstallError]) {
        XCTFail(@"Initial Installation failed with error: %@", initialInstallError);
        return;
    }

    NSError *finalInstallError = nil;
    if (![installer performFinalInstallationProgressBlock:nil error:&finalInstallError]) {
        XCTFail(@"Final installation failed with error: %@", finalInstallError);
        return;
    }

    XCTAssertTrue([fm fileExistsAtPath:expectedDestination isDirectory:nil]);

    [fm removeItemAtPath:expectedDestination error:nil];
}
#endif

@end
