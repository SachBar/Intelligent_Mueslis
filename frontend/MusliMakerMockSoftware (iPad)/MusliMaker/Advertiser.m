//
//  Advertiser.m
//  MusliMaker
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "Advertiser.h"

NSString *const SERVICE_UUID = @"94C5C900-5C7A-40FF-806F-415D841288D9";

NSString *const INGR_UUID =    @"94C5C902-5C7A-40FF-806F-415D841288D9";
NSString *const PRICES_UUID =  @"94C5C903-5C7A-40FF-806F-415D841288D9";
NSString *const AMOUNT_UUID =  @"94C5C904-5C7A-40FF-806F-415D841288D9";
NSString *const TYPES_UUID =   @"94C5C905-5C7A-40FF-806F-415D841288D9";

NSString *const STATE_UUID = @"94C5C911-5C7A-40FF-806F-415D841288D9";
NSString *const ORDER_UUID = @"94C5C912-5C7A-40FF-806F-415D841288D9";
NSString *const PAY_VER_UUID = @"94C5C913-5C7A-40FF-806F-415D841288D9";

@interface Advertiser ()
{
    CBMutableCharacteristic *_cbcIngredients;
    CBMutableCharacteristic *_cbcPrices;
    CBMutableCharacteristic *_cbcAmounts;
    CBMutableCharacteristic *_cbcTypes;
    CBMutableCharacteristic *_cbcState;
    CBMutableCharacteristic *_cbcOrder;
    CBMutableCharacteristic *_cbcPayVer;
}
@property (strong,nonatomic) NSString * localName;
@property (strong,nonatomic) NSDictionary* peripheralData;
@property (strong, nonatomic) CBPeripheralManager* peripheralManager;
@property (strong, nonatomic) CBMutableService *service;
@property (strong, nonatomic) CBCentral *servicedCentral;

@end

@implementation Advertiser

-(instancetype)initWithName:(NSString*)name Delegate:(id)delegate{
    self = [super init];
    if(self){
        _localName = name;
        _delegate = delegate;
        [self initCharacteristics];
        [self prepareAdvertisment];
    }
    return self;
}

-(void)setName:(NSString*)name{
    _localName = name;
    [self prepareAdvertisment];
}

-(void)startServicing{
    if(_peripheralManager==nil)
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    else
    {
        if([_peripheralManager state]==CBManagerStatePoweredOn){
            [_peripheralManager addService:_service];
            [_peripheralManager startAdvertising:_peripheralData];
        }else{
            NSLog(@"_peripheralManager not powered on!");
        }
    }
}

-(void)stopServicing{
    [_peripheralManager removeAllServices];
    [_peripheralManager stopAdvertising];
}

-(void)disconnectCurrentUser{
    _servicedCentral=nil;
}

-(void)updateAmounts{
    /*NSLog(@"Update amounts %@",[self.delegate amountsArray]);
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self.delegate amountsArray] requiringSecureCoding:NO error:nil];
    NSLog(@"Data: %@",data);
    [_peripheralManager updateValue:data forCharacteristic:_cbcAmounts onSubscribedCentrals:nil];*/
}

-(void)initCharacteristics{
    [self prepareInfoCharacteristics];
    [self prepareOrderCharacteristics];
}

-(void)prepareInfoCharacteristics{
    NSArray *ingredients = [self.delegate ingredientsArray];
    
    NSMutableArray *ingr = [NSMutableArray arrayWithCapacity:ingredients.count];
    for (Ingredient *i in ingredients) {
        [ingr addObject:i.productName];
    }
    NSData *ingredientsData = [NSKeyedArchiver archivedDataWithRootObject:ingr requiringSecureCoding:NO error:nil];

    _cbcIngredients =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:INGR_UUID]
                                       properties:CBCharacteristicPropertyRead
                                            value:ingredientsData
                                      permissions:CBAttributePermissionsReadable];

    NSMutableArray *prices = [NSMutableArray arrayWithCapacity:ingredients.count];
    for (Ingredient *i in ingredients) {
        [prices addObject:i.price];
    }
    NSData *pricingData = [NSKeyedArchiver archivedDataWithRootObject:prices requiringSecureCoding:NO error:nil];
    _cbcPrices =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PRICES_UUID]
                                       properties:CBCharacteristicPropertyRead
                                            value:pricingData
                                      permissions:CBAttributePermissionsReadable];

    NSMutableArray *types = [NSMutableArray arrayWithCapacity:ingredients.count];
    for (Ingredient *i in ingredients) {
        [types addObject:[NSNumber numberWithInteger:i.type]];
    }
    NSData *typesData = [NSKeyedArchiver archivedDataWithRootObject:types requiringSecureCoding:NO error:nil];
    _cbcTypes =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TYPES_UUID]
                                       properties:CBCharacteristicPropertyRead
                                            value:typesData
                                      permissions:CBAttributePermissionsReadable];

    _cbcAmounts =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:AMOUNT_UUID]
                                       properties:CBCharacteristicPropertyRead
                                                | CBCharacteristicPropertyNotify
                                            value:nil // <- will change (don't chache)
                                      permissions:CBAttributePermissionsReadable];
     
    [self updateAmounts];
}

-(void)prepareOrderCharacteristics{
    
    _cbcState =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:STATE_UUID]
                                       properties:CBCharacteristicPropertyRead |
                                                    CBCharacteristicPropertyNotify
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];
    
    _cbcOrder =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:ORDER_UUID]
                                       properties:CBCharacteristicPropertyWrite
                                            value:nil
                                      permissions:CBAttributePermissionsWriteable];
    
    _cbcPayVer =
    [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:PAY_VER_UUID]
                                       properties:CBCharacteristicPropertyWrite
                                            value:nil
                                      permissions:CBAttributePermissionsWriteable];
}

-(void)prepareAdvertisment{
    CBUUID *service_uuid = [CBUUID UUIDWithString:SERVICE_UUID];
    self.service = [[CBMutableService alloc] initWithType:service_uuid primary:YES];

    _service.characteristics = @[
                                 _cbcIngredients,
                                 _cbcPrices,
                                 //_cbcAmounts,
                                 _cbcTypes,
                                 _cbcState,
                                 _cbcOrder,
                                 _cbcPayVer
                                 ];
    self.peripheralData = @{
                            CBAdvertisementDataServiceUUIDsKey : @[service_uuid],
                            CBAdvertisementDataLocalNameKey : _localName
                           };
}

#pragma mark - delegate methods

- (void)peripheralManagerDidUpdateState:(nonnull CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBManagerStatePoweredOn:
            NSLog(@"Powered on");
            [_peripheralManager addService:_service];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"Powered Off");
            [peripheral stopAdvertising];
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

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Advertising: %@",_peripheralData);
    
    if([self.delegate respondsToSelector:@selector(didStartAdvertising)]){
        [self.delegate didStartAdvertising];
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Did add service");
    [peripheral startAdvertising:_peripheralData];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"Read request!!");
    if([request.characteristic isEqual:_cbcAmounts]){
        // Notify sender of the request with current value:
        NSLog(@"Request Amounts!");
        
        NSArray *ingredients = [self.delegate ingredientsArray];
        NSMutableArray *amounts = [NSMutableArray arrayWithCapacity:ingredients.count];
        for (Ingredient *i in ingredients) {
            [amounts addObject:i.amount];
        }
        NSError *error;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:amounts requiringSecureCoding:NO error:&error];
        if(error) NSLog(@"%@",error.description);
        NSLog(@"Amounts data: %@",data);
        
        bool sent = [_peripheralManager updateValue:data forCharacteristic:_cbcAmounts onSubscribedCentrals:@[request.central]];
        NSLog(@"Sent: %u",sent);
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"Did subscribe!");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests
{
    NSLog(@"Write request");
    for (CBATTRequest* request in requests) {
        NSLog(@"Central: %@",request.central.identifier.UUIDString);
        if([request.characteristic.UUID.UUIDString isEqual:ORDER_UUID]){
            if(_servicedCentral!=nil){
                [_peripheralManager respondToRequest:request withResult:CBATTErrorInsufficientAuthorization];
                return;
            }
            
            NSData* writeData = request.value;
            NSError *err;
            NSArray* order = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:writeData error:&err];//TODO handle errors
            if(err){
                NSLog(@"unarchieve error: %@",err.description);
            }
            NSLog(@"Order: %@",order);
            
            _servicedCentral = request.central;
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
            
            if([self.delegate respondsToSelector:@selector(didReceiveOrder:From:)]){
                [self.delegate didReceiveOrder:order From:_servicedCentral.identifier.UUIDString];
            }
        }
        else if([request.characteristic.UUID.UUIDString isEqual:PAY_VER_UUID])
        {
            NSData* writeData = request.value;
            NSError *err;
            NSNumber* pay_method = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSNumber class] fromData:writeData error:&err];//TODO handle errors
            
            [self disconnectCurrentUser];
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];

            if([self.delegate respondsToSelector:@selector(didReceivePaymentVerification:)])
                [self.delegate didReceivePaymentVerification:[pay_method integerValue]];
        }
    }
}

@end
