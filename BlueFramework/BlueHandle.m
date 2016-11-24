//
//  BlueHandle.m
//  BlueFramework
//
//  Created by Ly on 16/8/11.
//  Copyright © 2016年 L. All rights reserved.
//

#import "BlueHandle.h"
#define ServiceUUID @"0000fee7-0000-1000-8000-00805f9b34fb"
#define CharaUUID_WRITE  @"0000fec7-0000-1000-8000-00805f9b34fb"
#define CharaUUID_READ  @"0000fec8-0000-1000-8000-00805f9b34fb"
@interface BlueHandle()<CBPeripheralDelegate,CBCentralManagerDelegate>{

    NSString *deafults;
}
@property (nonatomic, strong)CBPeripheral *peripheral;
@property (strong,nonatomic) CBCentralManager *centralManager;
@end
static BOOL ReConnect = NO;
static BOOL AutoConnect = NO;
@implementation BlueHandle

/**打开蓝牙*/
- (void)openBluetooth{
    UInt64 recordTime = [[NSDate date] timeIntervalSince1970] * 1000;

    _centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
    
}

/**关闭蓝牙*/
- (void)closeBluetooth{

    
}

/**开始扫描设备*/
- (void)startScanDevice{
    switch (_centralManager.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE已打开.");
            //[self writeToLog:@"BLE已打开."];
            //扫描外围设备
            //            [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:k_ServiceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备.");
            break;
    }
}

/**结束扫描设备*/
- (void)stopScanDevice{
    [_centralManager stopScan];
}

/**连接设备*/
- (void)connectDevice:(CBPeripheral *)peripheral{
    self.peripheral = peripheral;
    self.peripheral.delegate = self;
   [self.centralManager connectPeripheral:peripheral options:nil];
    NSUserDefaults *user_datas = [NSUserDefaults standardUserDefaults];
    [user_datas setObject:peripheral.identifier.UUIDString forKey:@"Default_per"];
}


/**断开连接*/
- (void)disconnectDevice{
    [self cleanup];
}

//发送消息
- (void)sendDataToDevice:(NSString *)data{

    [self sendMessage:data];
}

//设置断开连接
- (void)setReConnect:(BOOL)isReconnect{

    ReConnect = isReconnect;
}

//设置连接上次设备
- (void)setAutoConnect:(BOOL)isAutoConnect{

    AutoConnect = isAutoConnect;
}

//将bytes转化成16进制字符串
- (NSString *)binaryToHexString:(Byte[])bytes binaryLengh:(int)lengh{
    NSString *hexStr=@"";
    for(int i=0;i<lengh;i++)
        
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        
        if([newHexStr length]==1)
            
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        
        else
            
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr]; 
    }
    return hexStr;
}
void ByteToHexStr(const unsigned char* source, char* dest, int sourceLen)
{
    short i;
    unsigned char highByte, lowByte;
    
    for (i = 0; i < sourceLen; i++)
    {
        highByte = source[i] >> 4;
        lowByte = source[i] & 0x0f ;
        
        highByte += 0x30;
        
        if (highByte > 0x39)
            dest[i * 2] = highByte + 0x07;
        else
            dest[i * 2] = highByte;
        
        lowByte += 0x30;
        if (lowByte > 0x39)
            dest[i * 2 + 1] = lowByte + 0x07;
        else
            dest[i * 2 + 1] = lowByte;
    }
    return ;
}
#pragma mark -- 蓝牙回调函数
//中心服务器状态更新后
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"BLE已打开.");
            //[self writeToLog:@"BLE已打开."];
            [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
            break;
            
        default:
            NSLog(@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备.");
            //[self writeToLog:@"此设备不支持BLE或未打开蓝牙功能，无法作为外围设备."];
            break;
    }
}

/**
 *  发现外围设备
 *
 *  @param central           中心设备
 *  @param peripheral        外围设备
 *  @param advertisementData 特征数据
 *  @param RSSI              信号质量（信号强度）
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    //返回外设信息
    [self.delegate onScanDeviceResult:peripheral andRSSI:RSSI andAdvertisementData:advertisementData];
    if (AutoConnect) {
        NSUserDefaults *user_datas = [NSUserDefaults standardUserDefaults];
        deafults = [user_datas stringForKey:@"Default_per"];
        if ([deafults isEqualToString:peripheral.identifier.UUIDString]) {
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    }
    
}

//连接到外围设备
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.delegate onDeviceStateChange:PeripheralConnectSucceed];
    NSLog(@"连接外围设备成功!");
    //[self writeToLog:@"连接外围设备成功!"];
    //设置外围设备的代理为当前视图控制器
    peripheral.delegate=self;
    //外围设备开始寻找服务
    [peripheral discoverServices:@[[CBUUID UUIDWithString:_ServiceUUID]]];
}

//连接外围设备失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self.delegate onDeviceStateChange:PeripheralConnectFalse];
    NSLog(@"连接外围设备失败!");
    //[self writeToLog:@"连接外围设备失败!"];
}

#pragma mark - CBPeripheral 代理方法
//外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"已发现可用服务...");
    NSLog(@"GESHU=%d",peripheral.services.count);
    //[self writeToLog:@"已发现可用服务..."];
    if(error){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
        //[self writeToLog:[NSString stringWithFormat:@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription]];
    }
    //遍历查找到的服务
    CBUUID *_TServiceUUID=[CBUUID UUIDWithString:_ServiceUUID];
    CBUUID *characteristicUUID_WRITE=[CBUUID UUIDWithString:_CharaUUID_WRITE];
     CBUUID *characteristicUUID_READ=[CBUUID UUIDWithString:_CharaUUID_READ];
    for (CBService *service in peripheral.services) {
        NSLog(@"sevice.uuid=%@",service.UUID);
        if([service.UUID isEqual:_TServiceUUID]){
            //外围设备查找指定服务中的特征
            [peripheral discoverCharacteristics:@[characteristicUUID_WRITE,characteristicUUID_READ] forService:service];
        }
    }
}

//外围设备寻找到特征后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"已发现可用特征...");
    //[self writeToLog:@"已发现可用特征..."];
    if (error) {
        NSLog(@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription);
        //[self writeToLog:[NSString stringWithFormat:@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription]];
    }
    //遍历服务中的特征
    CBUUID *_TServiceUUID=[CBUUID UUIDWithString:_ServiceUUID];
    CBUUID *characteristicUUID_WRITE=[CBUUID UUIDWithString:_CharaUUID_WRITE];
    CBUUID *characteristicUUID_READ=[CBUUID UUIDWithString:_CharaUUID_READ];
    if ([service.UUID isEqual:_TServiceUUID]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:characteristicUUID_WRITE]||[characteristic.UUID isEqual:characteristicUUID_READ]) {
                //情景一：通知
                /*找到特征后设置外围设备为已通知状态（订阅特征）：
                 *1.调用此方法会触发代理方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                 *2.调用此方法会触发外围设备的订阅代理方法
                 */
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
                //NSData * myData = [NSData dataWithBytes:dataArr length:2];
                
            }
        }
    }
}

//特征值被更新后
-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"收到特征更新通知...");
    //[self writeToLog:@"收到特征更新通知..."];
    if (error) {
        NSLog(@"更新通知状态时发生错误，错误信息：%@",error.localizedDescription);
    }
    //给特征值设置新的值
    CBUUID *characteristicUUID_WRITE=[CBUUID UUIDWithString:_CharaUUID_WRITE];
    CBUUID *characteristicUUID_READ=[CBUUID UUIDWithString:_CharaUUID_READ];
    if ([characteristic.UUID isEqual:characteristicUUID_WRITE] || [characteristic.UUID isEqual:characteristicUUID_READ]) {
        if (characteristic.isNotifying) {
            if (characteristic.properties==CBCharacteristicPropertyNotify) {
                NSLog(@"已订阅特征通知.");
                //[self writeToLog:@"已订阅特征通知."];
                return;
            }else if (characteristic.properties ==CBCharacteristicPropertyRead) {
                //从外围设备读取新值,调用此方法会触发代理方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
                [peripheral readValueForCharacteristic:characteristic];
            }
            
        }else if(characteristic.properties == CBCharacteristicPropertyWrite){
            NSLog(@"可读");
            //[self writeToLog:@"停止已停止."];
        }else if(characteristic.properties == CBCharacteristicPropertyIndicate){
            NSLog(@"wode");
        }else
        {
            NSLog(@"停止已停止.%lu",(unsigned long)characteristic.properties);
            //[self writeToLog:@"停止已停止."];
            
            //取消连接
            //[self.centralManager cancelPeripheralConnection:peripheral];
        }
    }
}

//更新特征值后（调用readValueForCharacteristic:方法或者外围设备在订阅后更新特征值都会调用此代理方法）
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"更新特征值时发生错误，错误信息：%@",error.localizedDescription);
        //[self writeToLog:[NSString stringWithFormat:@"更新特征值时发生错误，错误信息：%@",error.localizedDescription]];
        return;
    }
    if (characteristic.value) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:_CharaUUID_READ]]) {
            NSString *value=[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
            
            [self.delegate receieveDataFromDevice:value];
            NSLog(@"已收到的特征值更新：%@, value=%@",characteristic,value);
            //[self writeToLog:[NSString stringWithFormat:@"读取到特征值：%@",value]];
        }
    }else{
        NSLog(@"未发现特征值.");
        //[self writeToLog:@"未发现特征值."];
    }
}

//断开连接后
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self.delegate onDeviceStateChange:PeripheralDisConnect];
    if (ReConnect) {
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

#pragma mark -- 断开连接
- (void)cleanup {
    // See if we are subscribed to a characteristic on the peripheral
    if (_peripheral.services != nil) {
        for (CBService *service in _peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:_CharaUUID_WRITE]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:_CharaUUID_READ]]) {
                        if (characteristic.isNotifying) {
                            [_peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    [_centralManager cancelPeripheralConnection:_peripheral];
}

#pragma mark -- 发送消息
- (void)sendMessage:(NSString *)message{
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (_peripheral.services != nil) {
        self.peripheral.delegate = self;
        NSLog(@"找到服务");
        for (CBService *service in _peripheral.services) {
            if (service.characteristics != nil) {
                NSLog(@"找到特征");
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:_CharaUUID_WRITE]]) {//可写特征
                        NSLog(@"找到可写");
                        if (characteristic.isNotifying) {
                            NSLog(@"写入");
                            [_peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                        }
                    }
                }
            }
        }
    }else{
        
        NSLog(@"找不到服务");
    }
    
}



@end
