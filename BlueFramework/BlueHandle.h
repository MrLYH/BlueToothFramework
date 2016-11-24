//
//  BlueHandle.h
//  BlueFramework
//
//  Created by Ly on 16/8/11.
//  Copyright © 2016年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger, DeviceStatus) {
    PeripheralDisConnect,//断开连接
    PeripheralConnectSucceed,//连接成功
    PeripheralConnectFalse,//连接失败
};
@protocol BlueHandleDelegate <NSObject>

@required

@optional
-(void)onDeviceStateChange:(DeviceStatus)status;//监听蓝牙连接的状态

-(void)onScanDeviceResult:(CBPeripheral *)peripheral andRSSI:(NSNumber *)number andAdvertisementData:(NSDictionary *)AdvertisementData;//搜索到外设回调函数

- (void)receieveDataFromDevice:(NSString *)infos;//接收外设发送的消息
@end

@interface BlueHandle : NSObject
@property (nonatomic, strong)NSString *ServiceUUID;
@property (nonatomic, strong)NSString *CharaUUID_WRITE;
@property (nonatomic, strong)NSString *CharaUUID_READ;

@property (nonatomic,retain) id<BlueHandleDelegate> delegate;
/**打开蓝牙*/
- (void)openBluetooth;
/**关闭蓝牙*/
- (void)closeBluetooth;
/**开始扫描设备*/
- (void)startScanDevice;
/**结束扫描设备*/
- (void)stopScanDevice;
/**连接设备*/
- (void)connectDevice:(CBPeripheral *)peripheral;
/**断开连接*/
- (void)disconnectDevice;
/**向外设发送消息*/
- (void)sendDataToDevice:(NSString *)data;

/**设置是否断线重连*/
- (void)setReConnect:(BOOL)isReconnect;
/**设置自动连接*/
- (void)setAutoConnect:(BOOL)isAutoConnect;
/**将bytes转换成16进制字符串*/
- (NSString *)binaryToHexString:(Byte[])bytes binaryLengh:(int)lengh;

@end
