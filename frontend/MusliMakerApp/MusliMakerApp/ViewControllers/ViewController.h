//
//  ViewController.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connector.h"
#import "Server.h"
#import "Ingredient.h"

@interface ViewController : UIViewController <ServerDelegate,UITableViewDelegate,UITableViewDataSource>

@end

