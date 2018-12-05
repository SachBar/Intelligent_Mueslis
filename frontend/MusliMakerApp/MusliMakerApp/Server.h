//
//  Server.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 19/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Server;

typedef NS_ENUM(NSInteger, ResponseType) {
    ServerResponseSuggestion,
    ServerResponseUserRecommendation
};

@protocol ServerDelegate <NSObject>

@optional
- (void)ServerDelegate:(id)delegate didGetResponse:(id)response OfType:(ResponseType)type;
//- (void)ServerDelegate:(id)delegate didGetResponseWithSuggestions:(NSArray*)suggestions;
- (void)ServerDelegate:(id)delegate failedToGetResponseWithError:(NSString*)error;

@end

@interface Server : NSObject

@property (nonatomic, weak) id <ServerDelegate> delegate;

+ (instancetype)sharedInstance;

-(void)getSuggestions:(NSArray*)products;
-(void)getUserRecommendations:(NSString*)userID;
-(void)callServer:(NSString*)word;

@end

NS_ASSUME_NONNULL_END
