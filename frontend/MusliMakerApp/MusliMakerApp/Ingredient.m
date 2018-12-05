//
//  Ingredient.m
//  MusliMaker
//
//  Created by Jacob Fiskaali Hertz on 22/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "Ingredient.h"

@implementation Ingredient

-(NSString *)description{
    return [NSString stringWithFormat:@"%@ %.2f %@/%@ (%ld)",_productName,[_price floatValue],_order,_amount,(long)_type];
}

+(id)ingredeintWithName:(NSString*)name Price:(float)price Amount:(float)amount Type:(IngredientType)type
{
    Ingredient*i = [[Ingredient alloc] init];
    i.productName = name;
    i.price = [NSNumber numberWithFloat:price];
    i.amount = [NSNumber numberWithFloat:amount];
    i.maxAmount = @0;
    i.type = type;
    i.order = @0;
    return i;
}

-(id)init{
    self = [super init];
    if(self){
        _order=@0;
        _type=NotSet;
    }
    return self;
}

-(bool)isFullyConstructed{
    return (_productName!=nil
            && _price!=nil
//            && _amount!=nil
//            && _maxAmount!=nil
            && _type!=NotSet
            );

}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _productName = [coder decodeObjectForKey:@"ProductName"];
        _price = [coder decodeObjectForKey:@"Price"];
        _amount = [coder decodeObjectForKey:@"Amount"];
        _maxAmount = [coder decodeObjectForKey:@"MaxAmount"];
        _order = [coder decodeObjectForKey:@"Order"];
        _type = [[coder decodeObjectForKey:@"Type"] integerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_productName forKey:@"ProductName"];
    [coder encodeObject:_price forKey:@"Price"];
    [coder encodeObject:_amount forKey:@"Amount"];
    [coder encodeObject:_maxAmount forKey:@"MaxAmount"];
    [coder encodeObject:_order forKey:@"Order"];
    [coder encodeObject:[NSNumber numberWithInteger:_type] forKey:@"Type"];
}

@end
