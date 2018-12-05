//
//  Advertiser.h
//  MusliMaker
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "Ingredient.h"

NS_ASSUME_NONNULL_BEGIN

@class Advertiser;

@protocol AdvertiserDelegate <NSObject>
-(NSArray*)ingredientsArray;
@optional
-(void)didStartAdvertising;
-(void)didReceiveOrder:(NSArray*)order From:(NSString*)uuid;
-(void)didReceivePaymentVerification:(NSInteger)method;

@end

@interface Advertiser : NSObject <CBPeripheralManagerDelegate>

@property (strong,nonatomic) id delegate;

-(instancetype)initWithName:(NSString*)name Delegate:(id)delegate;
-(void)startServicing;
-(void)stopServicing;
-(void)setName:(NSString*)name;
-(void)updateAmounts;
-(void)disconnectCurrentUser;

@end

NS_ASSUME_NONNULL_END
