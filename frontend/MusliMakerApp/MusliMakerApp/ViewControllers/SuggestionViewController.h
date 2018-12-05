//
//  SuggestionViewController.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 25/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MuesliMaker.h"
#import "ConnectedViewController.h"
#import "Server.h"

NS_ASSUME_NONNULL_BEGIN

@interface SuggestionViewController : UIViewController <ServerDelegate,UITableViewDelegate,UITableViewDataSource>

-(void)setMuesliMaker:(MuesliMaker*)muesliMaker;

@end

NS_ASSUME_NONNULL_END
