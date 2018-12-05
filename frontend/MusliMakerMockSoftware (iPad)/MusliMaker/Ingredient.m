//
//  Ingredient.m
//  MusliMaker
//
//  Created by Jacob Fiskaali Hertz on 22/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "Ingredient.h"

@implementation Ingredient

+(id)ingredeintWithName:(NSString*)name Price:(float)price Amount:(float)amount Type:(IngredientType)type
{
    Ingredient*i = [[Ingredient alloc] init];
    i.productName = name;
    i.price = [NSNumber numberWithFloat:price];
    i.amount = [NSNumber numberWithFloat:amount];
    i.maxAmount = @0;
    i.type = type;
    return i;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _productName = [coder decodeObjectForKey:@"ProductName"];
        _price = [coder decodeObjectForKey:@"Price"];
        _amount = [coder decodeObjectForKey:@"Amount"];
        _maxAmount = [coder decodeObjectForKey:@"MaxAmount"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_productName forKey:@"ProductName"];
    [coder encodeObject:_price forKey:@"Price"];
    [coder encodeObject:_amount forKey:@"Amount"];
    [coder encodeObject:_maxAmount forKey:@"MaxAmount"];
}

@end
