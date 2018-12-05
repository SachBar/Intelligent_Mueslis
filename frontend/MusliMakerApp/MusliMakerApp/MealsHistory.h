//
//  MealsHistory.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 26/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MealsHistory : NSObject

-(void)addMeal:(NSArray*)ingrdients ForDate:(NSDate*)date;
-(bool)isSynced;
-(NSArray*)meals;
-(NSArray*)productDescriptions;
-(NSArray*)dateDescriptions;

@end

NS_ASSUME_NONNULL_END
