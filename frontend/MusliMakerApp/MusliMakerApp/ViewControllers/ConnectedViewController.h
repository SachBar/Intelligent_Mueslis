//
//  ConnectedViewController.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connector.h"
#import "PaymentViewController.h"
#import "Ingredient.h"
#import "MuesliMaker.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConnectedViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,PaymentVCDelegate>

//-(void)prepareIngredients:(NSDictionary*)ingredients;
-(void)setMuesliMaker:(MuesliMaker*)muesliMaker;


@end

NS_ASSUME_NONNULL_END
