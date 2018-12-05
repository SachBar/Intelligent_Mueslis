//
//  Connector.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

/*
 Notifications:
 
 didFindMuesliMaker
 didConnect
 failedToConnect
 didDisconnect
 didReceiveIngredients
 didReceivePrices
 didReceiveTypes
 didUpdateAmounts
 didConfirmOrder
 didConfirmPayment
 willEndOrderRequest
 
 */


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Connector;

@interface Connector : NSObject <CBCentralManagerDelegate,CBPeripheralDelegate>

+ (instancetype)sharedInstance;

-(void)startSearch;
-(void)reset;
-(void)connect;
-(void)disconnect;
-(bool)isConnected;
-(void)sendOrder:(NSArray*)amounts;
-(void)cancelOrder;
-(void)verifyPayment:(int)method;
-(bool)rssiStatusOk;

@end

NS_ASSUME_NONNULL_END
