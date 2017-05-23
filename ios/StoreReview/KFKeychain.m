/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2015 Keyflow AB
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

#import "KFKeychain.h"

@implementation KFKeychain

+ (BOOL)checkOSStatus:(OSStatus)status {
    return status == noErr;
}

+ (NSMutableDictionary *)keychainQueryForKey:(NSString *)key {
    return [@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService : key,
              (__bridge id)kSecAttrAccount : key,
              (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleAfterFirstUnlock
              } mutableCopy];
}

+ (BOOL)saveObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self keychainQueryForKey:key];
    // Deleting previous object with this key, because SecItemUpdate is more complicated.
    [self deleteObjectForKey:key];
    
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:object] forKey:(__bridge id)kSecValueData];
    return [self checkOSStatus:SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL)];
}

+ (id)loadObjectForKey:(NSString *)key {
    id object = nil;
    
    NSMutableDictionary *keychainQuery = [self keychainQueryForKey:key];
    
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    CFDataRef keyData = NULL;
    
    if ([self checkOSStatus:SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData)]) {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *exception) {
            NSLog(@"Unarchiving for key %@ failed with exception %@", key, exception.name);
            object = nil;
        }
        @finally {}
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return object;
}

+ (BOOL)deleteObjectForKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self keychainQueryForKey:key];
    return [self checkOSStatus:SecItemDelete((__bridge CFDictionaryRef)keychainQuery)];
}

@end
