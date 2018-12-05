//
//  HistoryViewController.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 26/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MealsHistory.h"

NS_ASSUME_NONNULL_BEGIN

@interface HistoryViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>

@property (strong,nonatomic) MealsHistory* history;

@end

NS_ASSUME_NONNULL_END
