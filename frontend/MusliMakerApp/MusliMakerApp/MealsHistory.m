//
//  MealsHistory.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 26/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "Server.h"
#import "Ingredient.h"
#import "MealsHistory.h"

@interface MealsHistory()

@property (strong,nonatomic) NSMutableArray* mealsSavedLocally;
@property (strong,nonatomic) NSMutableArray* unsyncedMeals;

@property (strong,nonatomic) Server *server;

@end

@implementation MealsHistory

- (instancetype)init
{
    self = [super init];
    if (self) {
        //[self resetUserDefaults];
        _server = [Server sharedInstance];
        if(![self loadLocally]) _mealsSavedLocally = [NSMutableArray array];
        _unsyncedMeals = [NSMutableArray array];
    }
    return self;
}

-(void)addMeal:(NSArray *)ingrdients ForDate:(NSDate *)date{
    NSDictionary * meal = @{@"Date":date,
                            @"Ingredients":ingrdients,
                            @"Synced":@"NO"
                            };
    NSLog(@"ADD MEAL \n%@",meal);
    [_mealsSavedLocally addObject:meal];
    [_unsyncedMeals addObject:meal];
    [self saveLocally];
}

-(NSArray *)meals{
    return _mealsSavedLocally;
}

-(NSArray *)productDescriptions{
    NSMutableArray*arr = [NSMutableArray arrayWithCapacity:_mealsSavedLocally.count];
    for (NSDictionary*meal in _mealsSavedLocally) {
        [arr addObject:
         [[meal[@"Ingredients"] valueForKey:@"productName"] componentsJoinedByString:@", "]];
    }
    return arr;
}
-(NSArray *)dateDescriptions{
    NSMutableArray*arr = [NSMutableArray arrayWithCapacity:_mealsSavedLocally.count];
    for (NSDictionary*meal in _mealsSavedLocally) {
        NSDate *d = meal[@"Date"];
        [arr addObject:[NSString stringWithFormat:@"%@",d]];
    }
    return arr;
}

-(bool)isSynced{
    return _unsyncedMeals.count==0;
}

-(void)syncMeal{
    
}

-(void)resetUserDefaults{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:@"MealsHistory"];
}

-(void)saveLocally{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSError* error;
    NSLog(@"%@",_mealsSavedLocally);
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self.mealsSavedLocally requiringSecureCoding:NO error:&error];
    if(error) NSLog(@"%@",error.description);
    
    [ud setObject:data forKey:@"MealsHistory"];
    NSLog(@"Meals saved");
    // TODO save unsynced indices
}
-(bool)loadLocally{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    NSData*data = [ud objectForKey:@"MealsHistory"];
    if(data==nil){
        NSLog(@"No meals saved locally");
        return false;
    }else{
        NSError*error;
        _mealsSavedLocally = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];

        if(error){
            NSLog(@"%@",error.description);
            return false;
        }
        NSLog(@"Did load meals %@",_mealsSavedLocally);
        return true;
    }
    
}

@end
