//
//  Ingredient.h
//  MusliMaker
//
//  Created by Jacob Fiskaali Hertz on 22/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IngredientType) {
    NotSet,
    Base,
    Topping
};

@interface Ingredient : NSObject

@property (strong,nonatomic) NSString* productName;
@property (strong,nonatomic) NSNumber* price;
@property (strong,nonatomic) NSNumber* amount;
@property (strong,nonatomic) NSNumber* maxAmount;
@property (strong,nonatomic) NSNumber* order;
@property (assign,nonatomic) IngredientType type;

+(id)ingredeintWithName:(NSString*)name Price:(float)price Amount:(float)amount Type:(IngredientType)type;

@end

NS_ASSUME_NONNULL_END
