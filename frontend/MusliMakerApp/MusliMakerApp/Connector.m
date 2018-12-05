//
//  Connector.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "Connector.h"

double const RSSI_RANGE = -35; // dB (signal strength)
double const RSSI_RANGE_LIM = -22; // dB (signal strength)
double const RSSI_TIMEOUT = 120; // seconds
double const RSSI_FREQUENCE = 1; // seconds
double const MAX_RESPONSE_TIME = 2; // seconds

NSString *const SERVICE_UUID = @"94C5C900-5C7A-40FF-806F-415D841288D9";

NSString *const INGR_UUID =    @"94C5C902-5C7A-40FF-806F-415D841288D9";
NSString *const PRICES_UUID =  @"94C5C903-5C7A-40FF-806F-415D841288D9";
NSString *const AMOUNT_UUID =  @"94C5C904-5C7A-40FF-806F-415D841288D9";
NSString *const TYPES_UUID =   @"94C5C905-5C7A-40FF-806F-415D841288D9";

NSString *const STATE_UUID = @"94C5C911-5C7A-40FF-806F-415D841288D9";
NSString *const ORDER_UUID = @"94C5C912-5C7A-40FF-806F-415D841288D9";
NSString *const PAY_VER_UUID = @"94C5C913-5C7A-40FF-806F-415D841288D9";

@interface Connector ()

@property (strong,nonatomic) CBCentralManager * manager;
@property (strong,nonatomic) CBPeripheral * peripheral;
@property (strong,nonatomic) CBService *mainService;
@property (assign,nonatomic) bool isConnected;
@property (assign,nonatomic) bool shouldConnect;
//@property (assign,nonatomic) bool disconnectToReconnect;

//@property (strong,nonatomic) NSMutableDictionary * characteristics;

@property (strong,nonatomic) NSData * dataToWrite;
@property (strong,nonatomic) NSMutableArray * toRead;
@property (strong,nonatomic) NSMutableArray * toWrite;

@property (strong,nonatomic) NSTimer *rssiTimer;
@property (strong,nonatomic) NSTimer *responseTimer;
@property (assign,nonatomic) int rssiTimerCount;
@property (assign,nonatomic) bool rssiDidRespond;

@end

@implementation Connector

+ (instancetype)sharedInstance
{
    static Connector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Connector alloc] init];
        sharedInstance.toWrite = [NSMutableArray arrayWithCapacity:2];
        //sharedInstance.disconnectToReconnect = false;
    });
    return sharedInstance;
}

#pragma mark - Interface methods
-(void)startSearch{
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
}

-(void)reset{
    _peripheral=nil;
    _mainService=nil;
    _toRead=nil;
    _dataToWrite=nil;
    [_toWrite removeAllObjects];
}

-(void)connect{
    _shouldConnect = true;
    [_manager connectPeripheral:_peripheral options:nil];
}
-(void)reconnect{
    NSLog(@"Re-connect");
    _shouldConnect = false;
    [_manager connectPeripheral:_peripheral options:nil];
}
-(void)disconnect{
    // TODO Unsubscribe
    _shouldConnect = false;
    [_manager cancelPeripheralConnection:_peripheral];
}

-(bool)isConnected{
    return _isConnected;
}

-(void)sendOrder:(NSArray *)amounts{
    NSError *error;
    _dataToWrite = [NSKeyedArchiver archivedDataWithRootObject:amounts requiringSecureCoding:NO error:&error];
    [_toWrite addObject:ORDER_UUID];
    if(error) NSLog(@"sendOrder %@",error);
    
    if(_rssiTimer != nil) return;
    _rssiDidRespond = true;
    _rssiTimer = [NSTimer scheduledTimerWithTimeInterval:RSSI_FREQUENCE target:self selector:@selector(checkRSSI) userInfo:nil repeats:YES];
}
-(void)cancelOrder{
    _dataToWrite=nil;
    [_rssiTimer invalidate];
    _rssiTimer = nil;
}

-(void)verifyPayment:(int)method{
    NSError *error;
    _dataToWrite = [NSKeyedArchiver archivedDataWithRootObject:[NSNumber numberWithInt:method] requiringSecureCoding:NO error:&error];
    [_toWrite addObject:PAY_VER_UUID];
    [_peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:PAY_VER_UUID]] forService:_mainService];
}

-(bool)rssiStatusOk{
    return _rssiDidRespond;
}

#pragma mark - Internal methods
-(void)checkRSSI{
    if(_rssiDidRespond == false){
        NSLog(@"No rssi response!");
        _shouldConnect=true;
        [self handleDisconnect];
    }
    NSLog(@"Request RSSI");
    _rssiDidRespond=false;
    [_peripheral readRSSI];
}

-(void)handleDisconnect{
    NSLog(@"Handle disconnect %d",_shouldConnect);
    if(_rssiTimer!=nil){
        NSLog(@"Stop rssi timer");
        [_rssiTimer invalidate];
        _rssiTimer=nil;
    }
    if(_shouldConnect){
        [self reconnect];
        // TODO reconnect
        // Set timer
        // Try to reconnect
        // Alert user if not able to reconnect within short while
    }
    else
    {
        NSLog(@"didDisconnectPeripheral");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didDisconnect" object:self];
    }
}

-(void)didRecconect{
    if([_toWrite containsObject:ORDER_UUID]){
        NSLog(@"Restart rssi");
        _rssiDidRespond = true;
        _rssiTimer = [NSTimer scheduledTimerWithTimeInterval:RSSI_FREQUENCE target:self selector:@selector(checkRSSI) userInfo:nil repeats:YES];
    }
}

-(void)didNotReceiveResponse{ // (Order response)
    if(_rssiTimer==nil)
        _rssiTimer = [NSTimer scheduledTimerWithTimeInterval:RSSI_FREQUENCE target:self selector:@selector(checkRSSI) userInfo:nil repeats:YES];
}

#pragma mark - central manager delegate methods

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    switch (central.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"Powered on");
            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:nil];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Powered Off");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"Device not supported");
            break;
        case CBManagerStateUnknown:
            NSLog(@"Unknown");
            break;
        case CBManagerStateResetting:
            NSLog(@"Reseeting");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"Unauthorized");
            break;
        default:
            break;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if(advertisementData[CBAdvertisementDataLocalNameKey]==nil) return; // Only accept when name is provided
    
     if(_peripheral == nil){
         _peripheral = peripheral;
         [central stopScan];
         
         NSLog(@"Discovered %@ %@", peripheral.name, peripheral.identifier);
//         NSLog(@"Data: %@",advertisementData);
         NSLog(@"Rssi: %@",RSSI);
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"didFindMuesliMaker" object:self userInfo:@{@"MuesliMaker":advertisementData[CBAdvertisementDataLocalNameKey]}];
     }else{
         NSLog(@"Multiple Peripherals!");
     }
 }

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    peripheral.delegate = self;
    _isConnected=true;
    if(_shouldConnect){
        NSLog(@"Did connect peripheral!");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didConnect" object:self];
        [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
    }else
        [self didRecconect];
        [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
        NSLog(@"Did reconnect peripheral!");
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    _isConnected=false;
    [self handleDisconnect];
}

#pragma mark - peripheral delegate methods

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"Did discover services");
    if(error){
        NSLog(@"%@",error);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"failedToConnect" object:self];
        return;
    }
    if(peripheral.services.count==0){
        NSLog(@"No services!");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"failedToConnect" object:self];
        return;
    }
    
    _mainService = peripheral.services[0];
    NSLog(@"Main service: %@",_mainService);
    
    if(_shouldConnect){
        _toRead = [NSMutableArray arrayWithObjects:
                   [CBUUID UUIDWithString:INGR_UUID],
                   [CBUUID UUIDWithString:PRICES_UUID],
                   [CBUUID UUIDWithString:TYPES_UUID],
                   [CBUUID UUIDWithString:AMOUNT_UUID], nil];
        [peripheral discoverCharacteristics:_toRead forService:_mainService];
    }else{ // reconnected
        
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //NSLog(@"Did discover Characteristics\n%@",service.characteristics);
    
    for (CBCharacteristic *charac in service.characteristics) {
        NSString *uuid = [charac.UUID UUIDString];
        if([uuid isEqual:INGR_UUID] && [_toRead containsObject:charac.UUID])
        {
            // Read
            NSLog(@"Read ingredients");
            [_peripheral readValueForCharacteristic:charac];
            [_toRead removeObject:charac.UUID];
        }
        else if([uuid isEqual:PRICES_UUID]  && [_toRead containsObject:charac.UUID])
        {
            // Read
            NSLog(@"Read prices");
            [_peripheral readValueForCharacteristic:charac];
            [_toRead removeObject:charac.UUID];
        }
        else if([uuid isEqual:AMOUNT_UUID])
        {
            // Subscribe and read
            NSLog(@"Read amounts and subscribe");
            //[_peripheral setNotifyValue:YES forCharacteristic:charac];
            [_peripheral readValueForCharacteristic:charac];
        }
        else if([uuid isEqual:TYPES_UUID]  && [_toRead containsObject:charac.UUID])
        {
            // Read
            NSLog(@"Read types");
            [_peripheral readValueForCharacteristic:charac];
            [_toRead removeObject:charac.UUID];
        }
        else if([uuid isEqual:STATE_UUID])
        {
            
        }
        else if([uuid isEqual:ORDER_UUID] && [_toWrite containsObject:ORDER_UUID])
        {
            // Write with response
            NSLog(@"Write order");
            if(_dataToWrite==nil){
                NSLog(@"Order data not ready");
                continue;
            }
            [_peripheral writeValue:_dataToWrite forCharacteristic:charac type:CBCharacteristicWriteWithResponse];
            [_toWrite removeObject:ORDER_UUID];
        }
        else if([uuid isEqual:PAY_VER_UUID] && [_toWrite containsObject:PAY_VER_UUID])
        {
            // Write with response
            NSLog(@"Write order");
            if(_dataToWrite==nil){
                NSLog(@"Payment data not ready");
                continue;
            }
            [_peripheral writeValue:_dataToWrite forCharacteristic:charac type:CBCharacteristicWriteWithResponse];
            [_toWrite removeObject:PAY_VER_UUID];
        }
        
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Did update characteristic!");

    NSString* uuid = characteristic.UUID.UUIDString;
    if([uuid isEqual:INGR_UUID])
    {
        NSError* error;
        NSArray *ingredients = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:characteristic.value error:&error];
        
        if(error) NSLog(@"Error reading ingredients: %@",error.description);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceiveIngredients" object:self userInfo:@{@"value":ingredients}];
    }
    else if([uuid isEqual:PRICES_UUID])
    {
        NSArray *prices = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:characteristic.value error:nil];
        
        NSLog(@"%@",prices);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceivePrices" object:self userInfo:@{@"value":prices}];
    }
    else if([uuid isEqual:AMOUNT_UUID])
    {
        NSError *error;
        NSArray *amounts = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:characteristic.value error:&error];
        if(error) NSLog(@"%@",error.description);
        
        NSLog(@"Amounts: %@",amounts);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateAmounts" object:self userInfo:@{@"value":amounts}];
    }
    else if([uuid isEqual:TYPES_UUID])
    {
        NSArray *types = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:characteristic.value error:nil];
        
        NSLog(@"%@",types);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceiveTypes" object:self userInfo:@{@"value":types}];
    }
    else if([uuid isEqual:STATE_UUID])
    {

    }
    else
    {
        NSLog(@"Did updated unrecognized characteristic!");
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error){
        if(error.code==8){ // Someone else is ordering
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didDenyOrder" object:self userInfo:@{@"reason":@"InUse"}];
        }
        NSLog(@"Write error: %@",error.description);
        return;
    }
    
    NSLog(@"Write succes");
    NSString* uuid = characteristic.UUID.UUIDString;
    if([uuid isEqual:ORDER_UUID])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didConfirmOrder" object:self];
        [_responseTimer invalidate];
        _responseTimer = nil;

    }
    else if([uuid isEqual:PAY_VER_UUID])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didConfirmPayment" object:self];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    if(error){
        NSLog(@"RSSI error %@",error.description);
    }
    NSLog(@"Rssi: %@",RSSI);
    ++_rssiTimerCount;
    _rssiDidRespond = true;
    if([RSSI integerValue] > RSSI_RANGE && [RSSI integerValue] < RSSI_RANGE_LIM){
        NSLog(@"send order");
        if(_responseTimer!=nil) [_responseTimer invalidate];
        _responseTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_RESPONSE_TIME target:self selector:@selector(didNotReceiveResponse) userInfo:nil repeats:NO];
         [_peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ORDER_UUID]] forService:_mainService];
        [_rssiTimer invalidate];
        _rssiTimer = nil;

    }else if(_rssiTimerCount>RSSI_TIMEOUT)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"willEndOrderRequest" object:self];
        NSLog(@"Order request timed out");
        [_rssiTimer invalidate];
        _rssiTimer = nil;
    }
}

-(void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral{
    NSLog(@"peripheralIsReadyToSendWriteWithoutResponse");
}

@end
