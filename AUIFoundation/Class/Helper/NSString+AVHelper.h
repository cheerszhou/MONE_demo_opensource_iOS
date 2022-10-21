//
//  NSString+AVHelper.h
//  AlivcAIO_Demo
//
//  Created by Bingo on 2022/5/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (AVHelper)

+ (NSString *) av_randomString;

- (NSString *)av_MD5;

@end

NS_ASSUME_NONNULL_END
