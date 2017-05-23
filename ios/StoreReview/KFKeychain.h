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

#import <Foundation/Foundation.h>

@interface KFKeychain : NSObject

/**
 @abstract Saves the object to the Keychain.
 @param object The object to save. Must be an object that could be archived with NSKeyedArchiver.
 @param key The key identifying the object to save.
 @return @p YES if saved successfully, @p NO otherwise.
 */
+ (BOOL)saveObject:(id)object forKey:(NSString *)key;

/**
 @abstract Loads the object with specified @p key from the Keychain.
 @param key The key identifying the object to load.
 @return The object identified by @p key or nil if it doesn't exist.
 */
+ (id)loadObjectForKey:(NSString *)key;

/**
 @abstract Deletes the object with specified @p key from the Keychain.
 @param key The key identifying the object to delete.
 @return @p YES if deletion was successful, @p NO if the object was not found or some other error ocurred.
 */
+ (BOOL)deleteObjectForKey:(NSString *)key;

@end
