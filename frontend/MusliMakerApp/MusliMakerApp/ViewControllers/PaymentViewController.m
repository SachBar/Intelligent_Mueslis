//
//  PaymentViewController.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 19/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "PaymentViewController.h"

NSTimeInterval const PAYMENT_TIME = 44;

@interface PaymentViewController ()

@property (strong,nonatomic) Connector *bluetooth;
@property (strong,nonatomic) MuesliMaker *muesliMaker;

@property (strong,nonatomic) NSArray * paymentMethods;
@property (assign, nonatomic) double price;
@property (assign, nonatomic) bool paymentConfirmed;
@property (strong, nonatomic) NSTimer *paymentTimer;
@property (strong, nonatomic) NSTimer *rssiStatusTimer;

@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@property (weak, nonatomic) IBOutlet UILabel *lblPrice;
@property (weak, nonatomic) IBOutlet UIPickerView *pckMethod;
@property (weak, nonatomic) IBOutlet UIButton *btnPay;

@property (strong, nonatomic) UIView *overlayView;
@property (strong, nonatomic) UILabel *lblRssiStatus;

@end

@implementation PaymentViewController
{
    bool _didGoToPaymentApp;
    bool _didPay;
}
-(void)viewDidLoad{
    _paymentMethods = @[@"DankortApp",@"MobilePay",@"At counter"];
    [self reset];
    
    NSLog(@"Payment view did load!!");
    
    _overlayView = [self createOverlay];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderConfirmed:) name:@"didConfirmOrder" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderDenied:) name:@"didDenyOrder" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderTimedOut:) name:@"willEndOrderRequest" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paymentConfirmed:) name:@"didConfirmPayment" object:nil];

    _bluetooth = [Connector sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated{
    [self updatePrice];
    [self.view addSubview:_overlayView];
    if(_rssiStatusTimer==nil){
        _rssiStatusTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer*timer){
            self.lblRssiStatus.textColor = [self.bluetooth isConnected] ? [UIColor greenColor] : [UIColor redColor];
        }];
    }
}

-(void)reset{
    _didGoToPaymentApp = false;
    _didPay = false;
    _paymentConfirmed = false;
    _lblStatus.text = @"Order confirmed!";
    _pckMethod.userInteractionEnabled = YES;
    [_pckMethod selectRow:0 inComponent:0 animated:NO];
}

-(UIView*)createOverlay{
    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    CGSize msize = self.view.frame.size;
    UILabel* lblPayInstuct = [[UILabel alloc] initWithFrame:CGRectMake(0, msize.height*0.2, msize.width, 20)];
    lblPayInstuct.text = @"Hold phone to MuesliMaker";
    lblPayInstuct.textAlignment = NSTextAlignmentCenter;
    [overlayView addSubview:lblPayInstuct];
    
    float btn_w = 100;
    UIButton* btnCancel = [[UIButton alloc] initWithFrame:CGRectMake(msize.width/2-btn_w/2, msize.height*0.8, btn_w, 33)];
    [btnCancel setTitle:@"Cancel" forState:UIControlStateNormal];
    [btnCancel addTarget:self action:@selector(CancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    [overlayView addSubview:btnCancel];
    
    _lblRssiStatus = [[UILabel alloc] initWithFrame:CGRectMake(10,10,30,30)];
    _lblRssiStatus.text = @"O";
    _lblRssiStatus.textColor = [UIColor greenColor];
    [overlayView addSubview:_lblRssiStatus];

    overlayView.backgroundColor = [UIColor blueColor];
    return overlayView;
}

#pragma mark - Interface methods
-(void)setPrice:(double)price{
    _price = price;
    [self updatePrice];
}
-(void)setMuesliMaker:(MuesliMaker*)muesliMaker{
    _muesliMaker = muesliMaker;
}

#pragma mark - GUI Actions
- (IBAction)PayButtonPressed:(id)sender {

    if(_muesliMaker.appState==AppStateOrderDone){
        #pragma mark (FSM) ui: ok
        //_muesliMaker.appState = AppStateSubscribed; // TODO jump all the way back
        
        [self dismiss];

        //rootViewController?.dismiss
        //[self.navigationController popToRootViewControllerAnimated:YES]; // does nothing
        if(!_paymentConfirmed){
            NSLog(@"Payment was not confirmed");
        }
    }else{
        if(_paymentConfirmed) NSLog(@"Error payment already confirmed!");
        
        switch ([_pckMethod selectedRowInComponent:0]) {
            case 0: // DankortApp
                [self payWithDankortApp];
                break;
            case 1: // MobilePay
                [self payWithMobilePay];
                break;
            case 2: // At counter
                [self payAtCounter];
                break;
        }
        _pckMethod.userInteractionEnabled = NO;
    }
        
}
-(void) CancelPressed:(id)sender{
    #pragma mark (FSM) ui: cancel
    NSLog(@"Cancel");
    if(_muesliMaker.appState==AppStatePlaceOrder){
        _muesliMaker.appState = AppStateSubscribed; // TODO jump all the way back
        [_bluetooth cancelOrder]; // TODO do here or in ConVC? Use completion maybe..?
        [self dismiss];
    }else NSLog(@"FSM error! (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateSubscribed);
}

-(void)dismiss{
    if(_paymentTimer!=nil){
        [_paymentTimer invalidate];
    }
    if(_rssiStatusTimer!=nil){
        [_rssiStatusTimer invalidate];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Internal methods
-(void)updatePrice{
    _lblPrice.text = [NSString stringWithFormat:@"%.2f DKK",_price];
}

-(void)toPayment{
    [UIView animateWithDuration:0.2f animations:^
     {
         [self->_overlayView setAlpha:0];
     }
                     completion:^(BOOL finished)
     {
         [self->_overlayView removeFromSuperview];
     }];
    _paymentTimer = [NSTimer scheduledTimerWithTimeInterval:PAYMENT_TIME target:self selector:@selector(paymentTimedOut) userInfo:nil repeats:NO];
}

-(void)paymentTimedOut{
    #pragma mark (FSM) payment timed out
    [_paymentTimer invalidate];
    _paymentTimer = nil;
    if(_muesliMaker.appState == AppStateOrderConfimred){
        
        if(_didPay){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Payment error"
                                                            message:@"Please show receipt at counter"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            _btnPay.enabled = true;
            [_btnPay setTitle:@"Ok" forState:UIControlStateNormal];
        }else{
            [_pckMethod selectRow:2 inComponent:0 animated:YES];
            _pckMethod.userInteractionEnabled = false;
            [_btnPay setTitle:@"Ok" forState:UIControlStateNormal];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Payment timed out"
                                                            message:@"Please pay at counter"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        _muesliMaker.appState = AppStateOrderDone;
    }
    else NSLog(@"FSM error (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateOrderDone);
}

-(void)payWithDankortApp{
    NSURL *appURL = [NSURL URLWithString:@"Dankort://"];
    
    [[UIApplication sharedApplication] openURL:appURL options:@{} completionHandler:^(BOOL success){
        if(success){
            self->_didGoToPaymentApp = true;
        }else{
            NSLog(@"DankortApp opening error");
        }
    }];
}

-(void)payWithMobilePay{
    NSURL *appURL = [NSURL URLWithString:@"MobilePay://"];
    
    [[UIApplication sharedApplication] openURL:appURL options:@{} completionHandler:^(BOOL success){
        if(success){
            self->_didGoToPaymentApp = true;
        }else{
            NSLog(@"MobilePay opening error");
        }
    }];
}

-(void)payAtCounter{
    [_bluetooth verifyPayment:(int)[_pckMethod selectedRowInComponent:0]];
}

#pragma mark - Notifications
-(void)orderConfirmed:(NSNotification*)notification{
    #pragma mark (FSM) m: order ack
    NSLog(@"Order confirmed!");
    if(_muesliMaker.appState==AppStatePlaceOrder){
        _muesliMaker.appState = AppStateOrderConfimred;
        NSLog(@"To payment");
        [self toPayment];
    }else NSLog(@"FSM error! (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateOrderConfimred);
}

-(void)orderDenied:(NSNotification*)notification{
    #pragma mark (FSM) m: error
    if(_muesliMaker.appState==AppStatePlaceOrder){
        _muesliMaker.appState = AppStateSubscribed;
        
        if([notification.userInfo[@"reason"]isEqual:@"InUse"]){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Order Denied"
                                                            message:@"Wait till the machine is free"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        [self dismiss];
    }else NSLog(@"FSM error! (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateSubscribed);
    
}

-(void)orderTimedOut:(NSNotification*)notification{
    #pragma mark (FSM) order timed out
    [self CancelPressed:self];
}

-(void)paymentConfirmed:(NSNotification*)notification{
    #pragma mark m: (FSM) payment ack
    NSLog(@"Payment CONFRIMED!");
    if(_paymentTimer){
        [_paymentTimer invalidate];
        _paymentTimer = nil;
    }else{
        NSLog(@"Received confirmation after time out");
    }

    if(_muesliMaker.appState==AppStateOrderConfimred){
        _muesliMaker.appState = AppStateOrderDone;
        _paymentConfirmed=true;
        if((int)[_pckMethod selectedRowInComponent:0]==2){
            _lblStatus.text = @"Order sent to counter";
        }else{
            _lblPrice.textColor = [UIColor greenColor];
            _lblStatus.text = @"Payment confirmed";
        }
        [_btnPay setTitle:@"Ok" forState:UIControlStateNormal];
        _btnPay.enabled = true;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didCompleteOrder" object:self];
    }
    else NSLog(@"FSM error! (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateOrderDone);
}

-(void)didEnterForeground:(NSNotification*)notification{
    if(_didGoToPaymentApp){
        _didPay = true;
        _btnPay.enabled = false;
        _lblStatus.text = @"Waiting for verification..";
        [_bluetooth verifyPayment:(int)[_pckMethod selectedRowInComponent:0]];
        NSLog(@"Payment complete!");
    }
}


#pragma mark - Picker View

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [_paymentMethods count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _paymentMethods[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if(row==2) [_btnPay setTitle:@"Ok" forState:UIControlStateNormal];
    else [_btnPay setTitle:@"Pay" forState:UIControlStateNormal];
}

-(void)dealloc{
    NSLog(@"Payment dealloc");
}


@end
