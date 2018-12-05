//
//  MuesliMaker.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 23/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "MuesliMaker.h"

double const MIN_PRICE = 3.00;

@interface MuesliMaker ()

@property (strong,nonatomic) NSMutableArray* ingredients;
@property (strong,nonatomic) NSMutableArray* recommendedProducts;
@property (strong,nonatomic) MealsHistory* history;

@end

@implementation MuesliMaker

-(instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveIngredients:) name:@"didReceiveIngredients" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePrices:) name:@"didReceivePrices" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveTypes:) name:@"didReceiveTypes" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAmounts:) name:@"didUpdateAmounts" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderCompleted:) name:@"didCompleteOrder" object:nil];
        
        _history = [[MealsHistory alloc] init];
    }
    return self;
}

-(void)initIngredientsWithSize:(NSInteger)size{
    NSLog(@"Init ingredients");
    _ingredients = [NSMutableArray arrayWithCapacity:size];
    for (int i=0; i<size; ++i) {
        [_ingredients addObject:[[Ingredient alloc] init]];
    }
}

#pragma mark - Setters
-(void)setProducts:(NSArray *)products{
    if(_ingredients==nil) [self initIngredientsWithSize:products.count];
    for (int i=0; i<_ingredients.count; ++i)
        ((Ingredient*)_ingredients[i]).productName = products[i];
}
-(void)setPrices:(NSArray *)prices{
    if(_ingredients==nil) [self initIngredientsWithSize:prices.count];
    for (int i=0; i<_ingredients.count; ++i)
        ((Ingredient*)_ingredients[i]).price = prices[i];
}
-(void)setAmounts:(NSArray *)amounts{
    if(_ingredients==nil) [self initIngredientsWithSize:amounts.count];
    for (int i=0; i<_ingredients.count; ++i)
        ((Ingredient*)_ingredients[i]).amount = amounts[i];
}
-(void)setTypes:(NSArray *)types{
    if(_ingredients==nil) [self initIngredientsWithSize:types.count];
    for (int i=0; i<_ingredients.count; ++i)
        ((Ingredient*)_ingredients[i]).type = [types[i] integerValue];
}

-(void)setMaxAmounts:(NSArray *)maxAmounts{
    if(_ingredients==nil) [self initIngredientsWithSize:maxAmounts.count];
    for (int i=0; i<_ingredients.count; ++i)
        ((Ingredient*)_ingredients[i]).maxAmount = maxAmounts[i];
}

-(void)setOrderAmount:(float)amount At:(NSInteger)index{
    ((Ingredient*)_ingredients[index]).order = [NSNumber numberWithFloat:amount];
}
-(void)setOrderAmounts:(NSArray *)amounts ForProducts:(NSArray *)products{
    
    NSLog(@"setOrder Prods: %@",products);
    for (Ingredient*i in _ingredients) {
        NSInteger index = [products indexOfObject:i.productName];
        if(index==NSNotFound) continue;
        if([amounts[index] floatValue]>=0)
            i.order = amounts[index];
        else{
            // TODO
            if(i.type==Base) i.order = @100;
            else i.order = @10;
        }
    }
    NSLog(@"Created new order: %@",self.Order);
}

-(void)setOrderPortion:(PortionSize)portion ForProducts:(NSArray *)products{
    
    int bases = 0;
    int toppings = 0;
    for (int i=0; i<products.count; ++i) {
        Ingredient* ingr = [self ingredientAt:[self indexOfProduct:products[i]]];
        if(ingr.type==Base) ++bases;
        else ++toppings;
    }
    
    float baseSize;
    float toppingSize;
    switch (portion) {
        case Small:
            baseSize = 100;
            toppingSize = 10;
            break;
            
        case Medium:
            baseSize = 200;
            toppingSize = 20;
            break;
            
        case Large:
            baseSize = 300;
            toppingSize = 30;
            break;
    }
    baseSize /= bases;
    toppingSize /= toppings;
    
    for (int i=0; i<products.count; ++i) {
        Ingredient* ing = [self ingredientAt:[self indexOfProduct:products[i]]];
        if(ing.type==Base) ing.order = [NSNumber numberWithFloat:baseSize];
        else ing.order = [NSNumber numberWithFloat:toppingSize];
    }

    NSLog(@"Created new order: %@",self.Order);
}

-(void)resetOrder{
    for (Ingredient*i in _ingredients) i.order=@0;
}

-(void)setRecommendation:(NSArray*)recommendedProducts{
    _recommendedProducts = [NSMutableArray arrayWithCapacity:recommendedProducts.count];
    for (int i=0; i<recommendedProducts.count; ++i) {
        if([self indexOfProduct:recommendedProducts[i]]!=NSNotFound){
            [_recommendedProducts addObject:recommendedProducts[i]];
        }
    }
}

#pragma mark - Getters
- (NSString *)ProductAt:(NSInteger)index{
    return ((Ingredient*)_ingredients[index]).productName;
}

-(NSInteger)indexOfProduct:(NSString *)product{
    for (int i=0; i<_ingredients.count; ++i) {
        if([[self ProductAt:i] isEqual:product]) return i;
    }
    return NSNotFound;
}

-(NSArray *)Products{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients) [arr addObject:i.productName];
    return arr;
}
-(NSArray *)Prices{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients) [arr addObject:i.price];
    return arr;
}
-(NSArray *)Amounts{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients) [arr addObject:i.amount];
    return arr;
}
-(NSArray *)Types{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients) [arr addObject:[NSNumber numberWithInteger:i.type]];
    return arr;
}
-(NSArray *)MaxAmounts{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients) [arr addObject:i.maxAmount];
    return arr;
}
-(NSArray *)OrderAmounts{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients) [arr addObject:i.order];
    return arr;
}

-(NSArray *)Order{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:_ingredients.count];
    for (Ingredient *i in _ingredients)
        if(![i.order isEqual:@0]){
            [arr addObject:i];
        }
    return arr;
}


-(Ingredient *)ingredientAt:(NSInteger)index{
    return _ingredients[index];
}

-(NSArray *)Ingredients{
    if(!self.ingredientsReady) return nil;
    return _ingredients;
}

-(NSArray *)BaseIngredients{
    return [self Ingredients]; // TODO
}

-(NSArray*)Recommendation{
    return _recommendedProducts;
}

#pragma mark - Checks
- (bool)ingredientsReady{
    bool ready = true;
    for (Ingredient*i in _ingredients) {
        ready = ready && i.isFullyConstructed;
    }
    return ready;
}

-(bool)checkIngredient:(NSString*)name Amount:(float)amount{
    for (Ingredient* i in _ingredients) {
        if([i.productName isEqual:name]
           && ([i.amount integerValue]==-1 || [i.amount floatValue]>amount))
            return true;
    }
    return false;
    /*Ingredient* i = [_ingredients filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.productName == %@",name]][0];
    return [i.amount integerValue]==-1 || [i.amount floatValue]>amount;*/
}

-(MealsHistory*) MealsHistory{
    return _history;
}

-(void)updateAmountsFromOrder{
    // TODO
}

#pragma mark - Notifications
- (void) didReceiveIngredients:(NSNotification *) notification
{
    NSLog(@"%@",notification.name);
    [self setProducts:notification.userInfo[@"value"]];
    if(self.ingredientsReady) [self notify];
}

- (void) didReceivePrices:(NSNotification *) notification
{
    NSLog(@"%@",notification.name);
    [self setPrices:notification.userInfo[@"value"]];
    if(self.ingredientsReady) [self notify];
}

- (void) didReceiveTypes:(NSNotification *) notification
{
    NSLog(@"%@",notification.name);
    [self setTypes:notification.userInfo[@"value"]];
    if(self.ingredientsReady) [self notify];
}

- (void) didReceiveAmounts:(NSNotification *) notification
{
    NSLog(@"%@",notification.name);
    [self setAmounts:notification.userInfo[@"value"]];
    if(self.ingredientsReady) [self notify];
}

-(void) orderCompleted:(NSNotification *) notification{
    [_history addMeal:[self Order] ForDate:[NSDate date]];
    [self resetOrder];
}

-(void)notify{
    //[self prepareOrder];
    if(_appState==AppStateAwaitingIngredients){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ingredientsAreReady" object:self];
    }
}
                               
@end
