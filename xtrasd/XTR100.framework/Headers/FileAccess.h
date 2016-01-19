//
//  FileAccess.h
//  Petra
//
//  Created by Denis Londry on 2015-08-10.
//  Copyright (c) 2015 I Xtra Tech. All rights reserved.
//

#ifndef xtr100_FileAccess_h
#define xtr100_FileAccess_h


#define fileReadNotificationName @"com.ixtratech.fileReadNotification"
#define fileWriteNotificationName @"com.ixtratech.fileWriteNotification"
#define fileReadKey @"FileReadStatus"
#define fileWriteKey @"FileWriteStatus"

@interface FileAccess : NSObject

+ (instancetype) sharedFileAccess;

// File and directory accessors

- (NSURL*) getCurrentDirectory;

- (BOOL) changeDirectory:(NSURL*)newDirUrl error:(NSError**)error;

- (BOOL) deleteDir:(NSURL*)dirUrl error:(NSError**)error;

- (BOOL) deleteFile:(NSURL*)fileUrl error:(NSError**)error;

- (BOOL) renameFile:(NSURL*)currentFileUrl newName:(NSString*)newName;

- (BOOL) copyMoveFile:(NSURL*)fromUrl toUrl:(NSURL*)toUrl isDirectory:(BOOL)isDirectory isMove:(BOOL)isMove;

- (NSError *) getFile:(NSURL*)remotepath putInLocation:(NSURL*)localpath;

- (NSArray *) getContentsOfDirectory:(NSURL *)url error:(NSError**) error;

- (NSError *) startFileWrite:(NSURL*)remotepath ofSize:(uint32_t)size;

- (NSError *) sendFilePacket:(NSData*)data;

- (NSError *) endFileWrite:(NSURL*) remotepath;

// Hardware Functions all these functions go to the peripheral
- (BOOL)setGPIO:(uint32_t) address error:(NSError**)error;

//- (BOOL)getGPIO:(uint32_t) address error:(NSError**)error;
- (BOOL)getGPIO;

- (NSString*)getSerialNumber:(NSError**)error;

- (NSString*)getModelName:(NSError**)error;

// For debugging purpose
- (NSString*)getModelNumber:(NSError**)error;
- (NSString*)getManufacturerLabel:(NSError**)error;
- (NSString*)getHardwareRevision:(NSError**)error;
- (NSString*)getFirmwareRevision:(NSError**)error;

- (BOOL)isConnected;
- (BOOL)accessoryConnected;
- (BOOL)batteryCharging:(uint32_t) address error:(NSError**)error;


// general status functions
- (NSError*) getLastError;

- (NSError*) getDeviceErrors;

- (NSString*) readBuffer;

- (NSString *) getDebugString;

@end

#endif
