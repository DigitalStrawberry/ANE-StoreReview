/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2017 Digital Strawberry LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#import "StoreReview.h"
#import "KFKeychain.h"
#import "BITHockeyHelper.h"
#import "Functions/RequestReviewFunction.h"
#import "Functions/IsSupportedFunction.h"
#import "Functions/WillDialogDisplayFunction.h"
#import "Functions/NumRequestsFunctions.h"
#import "Functions/DaysSinceLastRequestFunction.h"
#import "Functions/LastRequestedReviewVersionFunction.h"
#import "Functions/CurrentAppVersionFunction.h"
#import <StoreKit/StoreKit.h>
#import <Security/Security.h>

FREContext StoreReviewExtContext = nil;
static StoreReview* StoreReviewSharedInstance = nil;

static NSString* const kSKInitialReviewRequestTimestamp = @"initialReviewRequestTimestamp";
static NSString* const kSKNumReviewRequests = @"numReviewRequests";
static NSString* const kSKLastReviewRequestTimestamp = @"lastReviewRequestTimestamp";
static NSString* const kSKLastReviewRequestVersion = @"lastReviewRequestVersion";

@implementation StoreReview {
    BIT_AppEnvironment mAppEnvironment;
    NSString* mAppVersion;
}

# pragma mark - Public API

+ (id) sharedInstance
{
    if( StoreReviewSharedInstance == nil )
    {
        StoreReviewSharedInstance = [[StoreReview alloc] init];
    }
    return StoreReviewSharedInstance;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        mAppEnvironment = [BITHockeyHelper bit_currentAppEnvironment];
        mAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    }
    
    return self;
}

- (void) requestReview
{
    if([self isSupported])
    {
        [self trackReviewRequest];
        
        [SKStoreReviewController requestReview];
    }
}

- (BOOL) isSupported
{
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.3") && ([SKStoreReviewController class] != nil);
}

- (BOOL) willDialogDisplay
{
    if(![self isSupported])
    {
        return NO;
    }
    
    // Does not show in TestFlight build
    if(mAppEnvironment == EnvTestFlight)
    {
        return NO;
    }
    
    // Will always show up during development
    if(mAppEnvironment != EnvAppStore)
    {
        return YES;
    }
    
    // Check the number of times we requested a review in the last 365 days,
    // dialog should show up if there have been less than 3 requests
    return [self reviewRequestsIn365Days] < 3;
}

- (int) reviewRequestsIn365Days
{
    NSNumber* timestamp = [self keychainInitialRequestTimestamp];
    
    // If there is no timestamp then there have not been any request
    if(timestamp == nil)
    {
        return 0;
    }
    
    [self refreshTimestamp: timestamp];
    
    NSNumber* numRequests = [self keychainNumRequests];
    if(numRequests == nil)
    {
        return 0;
    }
    
    return [numRequests intValue];
}

- (int) daysSinceLastRequest
{
    NSNumber* timestamp = [KFKeychain loadObjectForKey:kSKLastReviewRequestTimestamp];
    if(timestamp != nil)
    {
        NSDate* date = [NSDate date];
        NSTimeInterval now = date.timeIntervalSince1970;
        NSTimeInterval lastRequest = timestamp.doubleValue;
        return floor((now - lastRequest) / 86400); // 86400 = seconds in a day
    }
    
    return -1;
}

- (nullable NSString*) lastRequestedReviewVersion
{
    return [KFKeychain loadObjectForKey:kSKLastReviewRequestVersion];
}

- (nonnull NSString*) currentVersion
{
    return mAppVersion;
}


# pragma mark - Private API

- (void) trackReviewRequest
{
    NSNumber* timestamp = [self keychainInitialRequestTimestamp];
    NSDate* date = [NSDate date];
    
    // Track the first request
    if(timestamp == nil)
    {
        timestamp = [NSNumber numberWithDouble:date.timeIntervalSince1970];
        [KFKeychain saveObject:timestamp forKey:kSKInitialReviewRequestTimestamp];
    }
    else
    {
        [self refreshTimestamp: timestamp];
    }
    
    // Store current time as the last request timestamp
    [KFKeychain saveObject:[NSNumber numberWithDouble:date.timeIntervalSince1970] forKey:kSKLastReviewRequestTimestamp];
    
    // Store the current app version
    [KFKeychain saveObject:mAppVersion forKey:kSKLastReviewRequestVersion];
    
    // Update the number of requests made
    NSNumber* numRequests = [self keychainNumRequests];
    if(numRequests == nil)
    {
        numRequests = [NSNumber numberWithInt:1];
    }
    else
    {
        numRequests = [NSNumber numberWithInt:[numRequests intValue] + 1];
    }
    
    [KFKeychain saveObject:numRequests forKey:kSKNumReviewRequests];
}

- (void) refreshTimestamp:(nonnull NSNumber*) currentTimstamp
{
    // Get num of days between the first request and today
    NSTimeInterval today = [NSDate date].timeIntervalSince1970;
    NSTimeInterval diff = today - [currentTimstamp doubleValue];
    
    // Roughly a number of seconds in a year
    NSTimeInterval secondsInYear = 31536000;
    
    // A year has passed between the first request and today
    if(diff >= secondsInYear)
    {
        // Reset the number of requests
        [KFKeychain saveObject:[NSNumber numberWithInt:0] forKey:kSKNumReviewRequests];
        
        // Save a new timestamp
        [KFKeychain saveObject:[NSNumber numberWithDouble:today] forKey:kSKInitialReviewRequestTimestamp];
    }
}

- (nullable NSNumber*) keychainInitialRequestTimestamp
{
    return [KFKeychain loadObjectForKey:kSKInitialReviewRequestTimestamp];
}

- (nullable NSNumber*) keychainNumRequests
{
    return [KFKeychain loadObjectForKey:kSKNumReviewRequests];
}

@end

/**
 *
 *
 * Context initialization
 *
 *
 **/

FRENamedFunction airStoreReviewExtFunctions[] =
{
    { (const uint8_t*) "requestReview",              0, srev_requestReview },
    { (const uint8_t*) "isSupported",                0, srev_isSupported },
    { (const uint8_t*) "willDialogDisplay",          0, srev_willDialogDisplay },
    { (const uint8_t*) "daysSinceLastRequest",       0, srev_daysSinceLastRequest },
    { (const uint8_t*) "reviewRequestsIn365Days",    0, srev_numRequests },
    { (const uint8_t*) "lastRequestedReviewVersion", 0, srev_lastRequestedReviewVersion },
    { (const uint8_t*) "currentVersion",             0, srev_currentVersion }
};

void StoreReviewContextInitializer( void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToSet, const FRENamedFunction** functionsToSet )
{
    *numFunctionsToSet = sizeof( airStoreReviewExtFunctions ) / sizeof( FRENamedFunction );
    
    *functionsToSet = airStoreReviewExtFunctions;
    
    StoreReviewExtContext = ctx;
}

void StoreReviewContextFinalizer( FREContext ctx ) { }

void StoreReviewInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet )
{
    *extDataToSet = NULL;
    *ctxInitializerToSet = &StoreReviewContextInitializer;
    *ctxFinalizerToSet = &StoreReviewContextFinalizer;
}

void StoreReviewFinalizer( void* extData ) { }







