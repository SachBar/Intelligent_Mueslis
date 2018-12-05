//
//  PaymentViewController.h
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 19/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Connector.h"
#import "MuesliMaker.h"

NS_ASSUME_NONNULL_BEGIN

@class PaymentViewController;

@protocol PaymentVCDelegate <NSObject>
-(void)didCancel;
-(void)didSucceed;
@end

@interface PaymentViewController : UIViewController <UIPickerViewDataSource,UIPickerViewDelegate>

@property (strong,nonatomic) id delegate;

-(void)setPrice:(double)price;
-(void)setMuesliMaker:(MuesliMaker*)muesliMaker;

@end

NS_ASSUME_NONNULL_END
