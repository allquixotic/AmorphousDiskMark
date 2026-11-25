//
//  AmorphousDiskMarkTests.m
//  AmorphousDiskMarkTests
//
//  Created by Hidetomo Katsura on 10/7/2016.
//  Copyright © 2016 Katsura Shareware. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <DiskArbitration/DiskArbitration.h>
#import <sys/mount.h>
#import "../AmorphousDiskMark/DiskUtil.h"

@interface AmorphousDiskMarkTests : XCTestCase

@end

@implementation AmorphousDiskMarkTests

- (void)testBootVolumeAndTemporaryDirectoryAreLocal
{
    XCTAssertEqualObjects([DiskUtil mountPointForPath:@"/"], @"/");
    XCTAssertNotNil([DiskUtil mountPointForPath:NSTemporaryDirectory()]);
    XCTAssertNil([DiskUtil mountPointForPath:@"relative/path"]);
}

- (void)testSymbolicLinkToAutomountIsRejected
{
    struct statfs *mounts;
    int count = getmntinfo_r_np(&mounts, MNT_NOWAIT);
    XCTAssertGreaterThan(count, 0);
    if (count == 0)
    {
        return;
    }
    NSString *automount = nil;
    for (int i = 0; i < count; i++)
    {
        if (strcmp(mounts[i].f_fstypename, "autofs") == 0)
        {
            automount = [NSString stringWithUTF8String:mounts[i].f_mntonname];
            break;
        }
    }
    free(mounts);
    XCTSkipIf(automount == nil, @"No automount is configured on this Mac.");

    NSString *link = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSError *error = nil;
    if (![fileManager createSymbolicLinkAtPath:link withDestinationPath:automount error:&error])
    {
        XCTFail(@"Could not create the symbolic link: %@", error);
        return;
    }
    XCTAssertNil([DiskUtil mountPointForPath:automount]);
    XCTAssertNil([DiskUtil mountPointForPath:link]);
    [fileManager removeItemAtPath:link error:NULL];
}

@end
