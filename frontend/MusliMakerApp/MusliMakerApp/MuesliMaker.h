//
//  MuesliMaker.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 23/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MealsHistory.h"
#import "Ingredient.h"

NS_ASSUME_NONNULL_BEGIN

extern double const MIN_PRICE;

typedef NS_ENUM(NSInteger, PortionSize) {
    Small = -1,
    Medium = -2,
    Large = -3
};

typedef NS_ENUM(NSInteger, AppState) {
    AppStateNotAvailable,
    AppStateDiscovered,          // FSM Idle
    AppStateAwaitingIngredients, // FSM Get info
    AppStateSubscribed,          // FSM Create order
    AppStatePlaceOrder,          // FSM Place order
    AppStateOrderConfimred,      // FSM Verify
    AppStateOrderDone            // FSM Done
    // TODO
    //AppStateConnected
    //AppStateOrderSent
    //AppStateOrderConfirmed
    //AppStatePaymentConfirmed
};

@interface MuesliMaker : NSObject

@property (assign,nonatomic) AppState appState;

-(void)setProducts:(NSArray*)products;
-(void)setPrices:(NSArray*)prices;
-(void)setAmounts:(NSArray*)amounts;
-(void)setMaxAmounts:(NSArray*)maxAmounts;
-(void)setOrderAmount:(float)amount At:(NSInteger)index;
-(void)setOrderAmounts:(NSArray*)amounts ForProducts:(NSArray*)products;
-(void)setOrderPortion:(PortionSize)portion ForProducts:(NSArray*)products;
-(void)setRecommendation:(NSArray*)recommendedProducts;
-(void)resetOrder;
-(NSString*)ProductAt:(NSInteger)index;
-(NSInteger)indexOfProduct:(NSString*)product;
-(NSArray*)Products;
-(NSArray*)Prices;
-(NSArray*)Amounts;
-(NSArray*)MaxAmounts;
-(NSArray*)OrderAmounts;
-(NSArray*)Recommendation;

//-(void)prepareOrder;
-(MealsHistory*) MealsHistory;

-(Ingredient*)ingredientAt:(NSInteger)index;
-(NSArray*)Ingredients;
-(NSArray*)BaseIngredients;

-(bool)ingredientsReady;

-(bool)checkIngredient:(NSString*)name Amount:(float)amount;

@end

NS_ASSUME_NONNULL_END
