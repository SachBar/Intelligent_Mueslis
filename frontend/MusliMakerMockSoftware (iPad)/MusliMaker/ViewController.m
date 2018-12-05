//
//  ViewController.m
//  MusliMaker
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "ViewController.h"

NSTimeInterval const PAYMENT_TIME = 40;

@interface ViewController ()

typedef NS_ENUM(NSInteger, AppState) {
    AppStateOff,
    AppStateIdle,
    AppStateAdvertising,
    AppStateOrderReceived,
    AppStateAwaitingPayment,
    AppStateAwaitingServing,
    AppStateOrderDone
};

@property (assign,nonatomic) AppState appState;
@property (strong, nonatomic) Advertiser *bluetooth;
@property (strong, nonatomic) NSMutableArray *ingredients;
@property (strong, nonatomic) CBPeripheral *currentUser;
@property (strong, nonatomic) NSMutableArray *order;
@property (strong, nonatomic) NSTimer *paymentTimer;

// GUI
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UITextField *lblDeviceName;
@property (weak, nonatomic) IBOutlet UITableView *tableIngredients;
@property (weak, nonatomic) IBOutlet UILabel *lblSubstatus;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _ingredients = [NSMutableArray arrayWithObjects:
     [Ingredient ingredeintWithName:@"Oats"            Price:0.025   Amount:534.0 Type:Base],
     [Ingredient ingredeintWithName:@"Cornflakes"      Price:0.025   Amount:432.0 Type:Base],
     [Ingredient ingredeintWithName:@"Crunchy"         Price:2.00    Amount:132.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Peanuts"         Price:0.20    Amount:672.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Almonds"         Price:0.025   Amount:534.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Walnuts"         Price:0.20    Amount:432.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Macadamia"       Price:0.20    Amount:672.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Pecan nuts"      Price:0.20    Amount:534.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Cashews"         Price:0.20    Amount:432.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Chia seeds"      Price:0.15    Amount:672.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Sunflower seeds" Price:0.15    Amount:132.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Pumpkin seeds"   Price:0.15    Amount:167.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Raisins"         Price:0.10    Amount:534.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Coconut flakes"  Price:0.1     Amount:432.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Cocoa beans"     Price:0.2     Amount:672.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Protein powder"  Price:2.0     Amount:132.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Cacao"           Price:1.0     Amount:167.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Cinnamon"        Price:1.0     Amount:167.0 Type:Topping],
     //[Ingredient ingredeintWithName:@"Vanilla"         Price:1.0     Amount:167.0 Type:Topping],
     [Ingredient ingredeintWithName:@"Dry fruit"       Price:1.0     Amount:167.0 Type:Topping],
      nil];
    
    _lblSubstatus.text = @"";
    
    _appState = AppStateOff;
    _bluetooth = [[Advertiser alloc] initWithName:_lblDeviceName.text Delegate:self];
}

- (IBAction)PowerSwitchChanged:(UISwitch*)pswitch {
    if(pswitch.isOn){
        [self setState:AppStateIdle];
    }else{
        [self setState:AppStateOff];
        [_bluetooth stopServicing];
    }
}

#pragma mark - Internal methods

-(void)setState:(AppState)appState{
    NSLog(@"Set state from %d to %d",(int)_appState,(int)appState);
    _appState = appState;
    
    switch (_appState) {
        case AppStateOff:
            _lblStatus.text = @"Powered off";
            _lblDeviceName.enabled = true;
            break;
            
        case AppStateIdle:
            _lblStatus.text = @"Idle";
            [_lblDeviceName endEditing:YES];
            _lblDeviceName.enabled = false;
            [_bluetooth setName:_lblDeviceName.text];
            [_bluetooth performSelector:@selector(startServicing) withObject:nil afterDelay:1];
            break;
            
        case AppStateAdvertising:
            _lblStatus.text = @"Broadcasting";
            _lblSubstatus.text = @"(Awaiting order)";

            break;
        case AppStateOrderReceived:
            _lblStatus.text = @"Order received";
            [self startPaymentTimer:PAYMENT_TIME];
            [self startServing:_order];
            break;
            
        case AppStateAwaitingServing:
            //_lblStatus.text = @"Await serving done";
            break;
            
        case AppStateAwaitingPayment:
            //_lblStatus.text = @"Awaiting Payment";
            break;

        case AppStateOrderDone:
            _lblStatus.text = @"Done";
            _lblSubstatus.text = @"Disconnecting client";
            [self performSelector:@selector(completeOrder) withObject:nil afterDelay:1];
            break;
    }
}

-(void)completeOrder{
    [self setState:AppStateAdvertising];
}

-(void)startServing:(NSArray*)serv{
    __block int servingProgress=0;
    [NSTimer scheduledTimerWithTimeInterval:2.2 repeats:YES block:^(NSTimer*timer){
        if(servingProgress >= serv.count){
            [timer invalidate];
            [self didFinishServing];
            return;
        }
        Ingredient *i = serv[servingProgress];
        self.lblStatus.text = [NSString stringWithFormat:@"Pouring %@ (%d g)",i.productName,[i.order intValue]];
        ++servingProgress;
    }];
}

#pragma mark (FSM) serving done
-(void)didFinishServing{
    //    [_bluetooth updateAmounts];
    if(_appState==AppStateOrderReceived)
        [self setState:AppStateAwaitingPayment];
    else if(_appState==AppStateAwaitingServing)
//        [self setState:AppStateAdvertising];
        [self setState:AppStateOrderDone];
    else
        NSLog(@"Did finish serving while in state %d",(int)_appState);
}

-(void)startPaymentTimer:(int)seconds{
    __block int time_left=seconds;
    _paymentTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer*timer){
        --time_left;
        if(self.appState==AppStateAwaitingPayment)
            self.lblStatus.text = [NSString stringWithFormat:@"Awaiting Payment (%d)",time_left];
        if(time_left==0){
            [timer invalidate];
            timer=nil;
            [self awaitPaymentTimedOut];
        }
    }];
}
-(void)stopPaymentTimer{
    if(_paymentTimer){
        [_paymentTimer invalidate];
        _paymentTimer = nil;
    }
}

#pragma mark (FSM) timed out
-(void)awaitPaymentTimedOut{
    NSLog(@"Payment timed out");
    // TODO notify client
    [_bluetooth disconnectCurrentUser];
    _lblSubstatus.text = @"Timed out";
    [self setState:AppStateOrderDone];
}

#pragma mark - Bluetooth Delegate

-(NSArray *)ingredientsArray{
    return _ingredients;
}

-(void)didStartAdvertising{
    if(_appState==AppStateIdle){
        [self setState:AppStateAdvertising];
    }else{
        NSLog(@"Started advertising while in state %d",(int)_appState);
    }
}

#pragma mark (FSM) m: order placed
-(void)didReceiveOrder:(NSArray *)order From:(NSString *)uuid{
    if(_appState==AppStateAdvertising){
        _order = [NSMutableArray array];
        for (int i=0; i<order.count; ++i) {
            if([order[i] floatValue]>0){
                ((Ingredient*)_ingredients[i]).order = order[i];
                [_order addObject:_ingredients[i]];
            }
        }
        _lblSubstatus.text = [NSString stringWithFormat:@"Connected client: %@",uuid];
        [self setState:AppStateOrderReceived];
    }else{
        NSLog(@"Did receive order while in state %d",(int)_appState);
    }
}

#pragma mark (FSM) m: payment verification
-(void)didReceivePaymentVerification:(NSInteger)method{
    if(_appState==AppStateOrderReceived || _appState==AppStateAwaitingPayment){
        switch (method) {
            case 0:
                NSLog(@"Paid with DK-APP");
                break;
            case 1:
                NSLog(@"Paid with MP");
                break;
            case 2:
                NSLog(@"Pay at counter");
                break;
        }
        [self stopPaymentTimer];
//        if(_appState==AppStateAwaitingPayment) [self setState:AppStateAdvertising];
//        else [self setState:AppStateAwaitingServing];
        if(_appState==AppStateAwaitingPayment) [self setState:AppStateOrderDone];
        else{NSLog(@"setAwaitServ in PayVer"); [self setState:AppStateAwaitingServing];}
    }
    else{
        NSLog(@"Did receive payver while in state %d",(int)_appState);
    }
}

#pragma mark - Table data source

- (nonnull UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"IngredientsTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    Ingredient *i = _ingredients[indexPath.row];
    
    cell.textLabel.text = i.productName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Price: %.2f dkk/g, %d grams left",
                                 i.price.doubleValue,i.amount.intValue];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_ingredients count];
}

@end
