/*
 *  Copyright (C) 2014 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "WWidgetUpdate.h"
#import "ZipArchive.h"
#import "ASIHTTPRequest.h"
#import "BUtility.h"
#import  <CommonCrypto/CommonDigest.h>
#import "SpecConfigParser.h"
#define FWGTUPDATEPrompt 1000
#define FWGTUPDATEError  1001
#define FWGTUUPDATEUNIQUE   @"AppCanWgtID"
@implementation WWidgetUpdate
@synthesize downLoadURL =_downLoadURL;
-(void)dealloc{
    [saveWgtPath release];
    [uniqueId release];
    [_downProgress release];
    [super dealloc];
}
#pragma mark - common

-(void)ShowAlertView:(NSString*)inTitle msg:(NSString*)inMsg firstBtn:(NSString*)inFirst secondBtn:(NSString*)inSecond tag:(int)inTag{
    UIAlertView * alertView =[[UIAlertView alloc]initWithTitle:inTitle message:inMsg delegate:self cancelButtonTitle:inFirst otherButtonTitles:inSecond, nil];
    [alertView show];
    [alertView release];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    switch (alertView.tag) {
        case FWGTUPDATEPrompt:
            if (buttonIndex == 0) {
                if ([self.downLoadURL length]>0) {
                    [self doUpdateWgt];
                }
            }
            break;
        case FWGTUPDATEError:
            if (buttonIndex == 0) {
                [self doUpdateWgt];
            }
            break;
            
        default:
            break;
    }
    if (buttonIndex == 0) {
        if ([self.downLoadURL length]>0) {
            [self doUpdateWgt];
        }
    }
}


-(void)promptUpdate{
    //保存下载路径
    if (!uniqueId) {
        uniqueId = [[self md5:self.downLoadURL] retain];
    }
    NSString *dPathKey = [NSString stringWithFormat:@"%@_savePath",uniqueId];
    NSString *savePath =[[NSUserDefaults standardUserDefaults] objectForKey:dPathKey];
    if (savePath!=nil) {
        [self ShowAlertView:ACELocalized(@"继续更新") msg:ACELocalized(@"上次更新未完成请继续更新") firstBtn:ACELocalized(@"更新") secondBtn:ACELocalized(@"取消") tag:FWGTUPDATEPrompt];
    }else{
        [self ShowAlertView:ACELocalized(@"更新提示") msg:ACELocalized(@"部分内容更新优化，请更新后使用") firstBtn:ACELocalized(@"更新")  secondBtn:ACELocalized(@"取消") tag:FWGTUPDATEPrompt];
    }
}
//4.8
-(void)forceUpdateWgt{
    if (!uniqueId) {
        uniqueId = [[self md5:self.downLoadURL] retain];
    }
    //初始化Documents路径
    NSArray *cacheList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        //初始化临时文件路径
    NSString *folderPath = [cacheList objectAtIndex:0];
    if (!saveWgtPath) {
            saveWgtPath = [[NSString alloc] initWithFormat:@"%@/%@.zip",folderPath,[self md5:self.downLoadURL]];
        }
        NSString *tempPath = [NSString stringWithFormat:@"%@/%@.temp",folderPath,[self md5:self.downLoadURL]];
        ACENSLog(@"savePath=%@",tempPath);
        //
        NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
        NSString *dPathKey = [NSString stringWithFormat:@"%@_savePath",uniqueId];
        [udf setValue:saveWgtPath forKey:dPathKey];
        [udf synchronize];
        
        
        NSURL *url = [NSURL URLWithString:self.downLoadURL];
        ACENSLog(@" request url =%@",url);
        ASIHTTPRequest *asiRequest = [ASIHTTPRequest requestWithURL:url];
        [asiRequest setDelegate:self];
        [asiRequest setDownloadProgressDelegate:self];
        [asiRequest setDownloadDestinationPath:saveWgtPath];
        [asiRequest setTemporaryFileDownloadPath:tempPath];
        [asiRequest setAllowResumeForFileDownloads:YES];
        [asiRequest startAsynchronous];
}

-(void)doUpdateWgt{
    //处理路径
    //初始化Documents路径
	NSArray *cacheList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	//初始化临时文件路径
	NSString *folderPath = [cacheList objectAtIndex:0];
    if (!saveWgtPath) {
        saveWgtPath = [[NSString alloc] initWithFormat:@"%@/%@.zip",folderPath,[self md5:self.downLoadURL]];
    }
    ACENSLog(@"savePath=%@",saveWgtPath);
    NSString *tempPath = [NSString stringWithFormat:@"%@/%@.temp",folderPath,[self md5:self.downLoadURL]];
    ACENSLog(@"savePath=%@",tempPath);
    //
	NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
	NSString *dPathKey = [NSString stringWithFormat:@"%@_savePath",uniqueId];
	[udf setValue:saveWgtPath forKey:dPathKey];
	[udf synchronize];
    
    
	NSURL *url = [NSURL URLWithString:self.downLoadURL];
	ACENSLog(@" request url =%@",url);
	ASIHTTPRequest *asiRequest = [ASIHTTPRequest requestWithURL:url];
	[asiRequest setDelegate:self];
	[asiRequest setDownloadProgressDelegate:self];
	[asiRequest setDownloadDestinationPath:saveWgtPath];
	[asiRequest setTemporaryFileDownloadPath:tempPath];
    [asiRequest setAllowResumeForFileDownloads:YES];
    [asiRequest startAsynchronous];
    //
    UIAlertView *progressAlert =[[UIAlertView alloc] initWithTitle:ACELocalized(@"更新中") message:ACELocalized(@"请勿关闭或离开当前页面，以免造成更新失败") delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    if (!_downProgress) {
        _downProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _downProgress.frame = CGRectMake(20, 100, 240, 30);
    }
    [progressAlert addSubview:_downProgress];
    [progressAlert show];
    [progressAlert release];
}

#pragma mark -ASIhttpRequestDelegate
//
-(void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders{
    NSLog(@"header dict=%@",[responseHeaders description]);
    NSString *fileSizeKey = [NSString stringWithFormat:@"%@_currentSize",uniqueId];
    NSString *fileDownSize =[[NSUserDefaults standardUserDefaults] objectForKey:fileSizeKey];
    if (fileDownSize) {
        appendFileSize = [fileDownSize longLongValue];
    }else {
        appendFileSize = 0;
    }
    
    fileTotalLength = request.contentLength;
    if (fileTotalLength==0) {
		fileTotalLength = -1;
	}else {
		NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
		NSString *fsKey = [NSString stringWithFormat:@"%@_fileSize",uniqueId];
        if (![udf objectForKey:fsKey]) {
            [udf setValue:[NSString stringWithFormat:@"%lld",fileTotalLength] forKey:fsKey];
            [udf synchronize];
        }
	}
}

//失败
-(void)requestFailed:(ASIHTTPRequest *)request{
    //保存现场
	NSUserDefaults *udf = [NSUserDefaults standardUserDefaults];
	NSString *curKey = [NSString stringWithFormat:@"%@_currentSize",uniqueId];
	[udf setValue:[NSString stringWithFormat:@"%lld",appendFileSize] forKey:curKey];
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *dateString = [df stringFromDate:[NSDate date]];
	[df release];
	[udf setValue:dateString forKey:[NSString stringWithFormat:@"%@_lastTime",uniqueId]];
    
    
    if (_downProgress==nil) {
        return;
    }
    if ([_downProgress.superview isKindOfClass:[UIAlertView class]]) {
        UIAlertView *alertView =(UIAlertView*)_downProgress.superview;
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    [_downProgress release];
    _downProgress = nil;
    
    //提示
    [self ShowAlertView:@"更新失败" msg:@"可能网络传输或其他问题造成，请点击重试" firstBtn:@"重试" secondBtn:ACELocalized(@"取消") tag:FWGTUPDATEError];
}

//
-(void)requestFinished:(ASIHTTPRequest *)request{
	ACENSLog(@"requestFinished");
      NSLog(@"uniqueID=%@",uniqueId);
    [[NSUserDefaults standardUserDefaults] setObject:uniqueId forKey:F_UD_UpdateWgtID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (_downProgress==nil) {
        return;
    }
    if ([_downProgress.superview isKindOfClass:[UIAlertView class]]) {
        UIAlertView *alertView =(UIAlertView*)_downProgress.superview;
        [alertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    [_downProgress release];
    _downProgress = nil;
    
}

-(void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes{
	ACENSLog(@"has receive :%lld",bytes);
 	appendFileSize+=bytes;
}
-(void)setProgress:(float)newProgress{
    ACENSLog(@"has process :%f",newProgress);
    _downProgress.progress = newProgress;
}

-(void)unZipUpdateSubWgt:(NSString *)subWidgetPatchZipPath {
    
    ZipArchive *zip = [[ZipArchive alloc] init];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    //解压后的widget包的最终路径
    NSString *outputPath = [BUtility getDocumentsPath:@"widgets"];
    
    //创建临时目录做文件中转站
    NSString *tmpPatchPath = [BUtility getDocumentsPath:@"uexAppStoreMgrSubWidget"];
    
    [fileMgr removeItemAtPath:tmpPatchPath error:nil];
    [fileMgr createDirectoryAtPath:tmpPatchPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    if ([zip UnzipOpenFile:subWidgetPatchZipPath] &&
        [zip UnzipFileTo:tmpPatchPath overWrite:YES] &&
        [zip UnzipCloseFile]) {
        
        
        NSString *newVersion = @"";
        NSString *subAppID = @"";
        
        //先解压到临时目录,由于不同的EMM后台zip包的目录也不同,在copy前需判断zip包的目录结构
        
        NSArray *fileList = [fileMgr contentsOfDirectoryAtPath:tmpPatchPath error:nil];
        
        if ([fileList containsObject:@"widget"] && [fileList containsObject:@"plugin"]) {
            
            NSString  *tmpWidgetPath = [tmpPatchPath stringByAppendingPathComponent:@"widget"];
            
            NSArray *widgetPathFolderList = [fileMgr contentsOfDirectoryAtPath:tmpWidgetPath error:nil];
            
            subAppID = [NSString stringWithFormat:@"%@", [widgetPathFolderList firstObject]];
            //拼接上appID
            tmpWidgetPath = [tmpWidgetPath stringByAppendingPathComponent:subAppID];
            outputPath = [outputPath stringByAppendingPathComponent:subAppID];
            
            //新版补丁包config.xml目录结构: widget(plugin并列)/appID/config.xml
            NSString *configPath = [tmpWidgetPath stringByAppendingPathComponent:@"config.xml"];
            
            SpecConfigParser * widgetXml = [[SpecConfigParser alloc] init];
            
          newVersion = [widgetXml initwithReqData:configPath queryPara:@"version" type:YES];
            
            [widgetXml release];
            //widgets/appId/version/config.xml 最终子应用的目录
            outputPath =[outputPath stringByAppendingPathComponent:newVersion];
            
            if ([self copyItemsFromPath:tmpWidgetPath toPath:outputPath ]) {
                
                NSLog(@"appcan-->Engine-->ACEWidgetUpdateUtility.m-->unZipSubWidgetNeedPatchUpdate-->outputPath = %@", outputPath);
                
                [fileMgr removeItemAtPath:tmpPatchPath error:nil];
                [fileMgr removeItemAtPath:subWidgetPatchZipPath error:nil];
                
            } else {
                NSLog(@"新版本的补丁包--->>更新失败");
            }
            
        } else {
            
            NSArray *widgetPathFolderList = [fileMgr contentsOfDirectoryAtPath:tmpPatchPath error:nil];
            
            subAppID = [NSString stringWithFormat:@"%@", [widgetPathFolderList firstObject]];
            
            //拼接上appID
            NSString *tmpWidgetPath = [tmpPatchPath stringByAppendingPathComponent:subAppID];
            outputPath = [outputPath stringByAppendingPathComponent:subAppID];
            
            NSString *configPath = [tmpWidgetPath stringByAppendingPathComponent:@"config.xml"];
            
            SpecConfigParser * widgetXml = [[SpecConfigParser alloc] init];
            
            newVersion = [widgetXml initwithReqData:configPath queryPara:@"version" type:YES];
            
            [widgetXml release];
            
            //widgets/appId/version/config.xml 最终子应用的目录
            outputPath =[outputPath stringByAppendingPathComponent:newVersion];
            
            if ([self copyItemsFromPath:tmpWidgetPath toPath:outputPath]) {
                
                NSLog(@"appcan-->old-->Engine-->ACEWidgetUpdateUtility.m-->unZipSubWidgetNeedPatchUpdate-->outputPath = %@", outputPath);
                
                [fileMgr removeItemAtPath:tmpPatchPath error:nil];
                [fileMgr removeItemAtPath:subWidgetPatchZipPath error:nil];
                
            } else {
                
                NSLog(@"旧版本的补丁包--->>更新失败");
                
            }
        }
        
        if (newVersion && newVersion.length > 0){
            
            [NSUserDefaults.standardUserDefaults setObject:newVersion forKey:subAppID];
        }
    }
    
}

//unzip
- (BOOL)unZipUpdateWgt:(NSString *)inWgtName {
    
    ZipArchive *zipObj = [[[ZipArchive alloc] init] autorelease];
    NSFileManager * fileMgr = [NSFileManager defaultManager];
    
    NSString *sourceWgt = inWgtName;
    
    NSString *outPath = nil;
    
    if ([BUtility getSDKVersion] < 5.0) {
        outPath = [BUtility getCachePath:@"widget/"];
    }else {
        outPath = [BUtility getDocumentsPath:@"widget/"];
    }
    
    NSString * tempFolder = [[[NSUUID UUID] UUIDString] lowercaseString];
    NSString * tempFolderPath = [BUtility getDocumentsPath:tempFolder];
    
    [fileMgr createDirectoryAtPath:tempFolderPath withIntermediateDirectories:YES attributes:nil error:nil];//创建临时目录做文件中转
    
    if ([zipObj UnzipOpenFile:sourceWgt] && [zipObj UnzipFileTo:tempFolderPath overWrite:YES] && [zipObj UnzipCloseFile]) {//解压到临时目录
        
        NSArray * fileList = [fileMgr contentsOfDirectoryAtPath:tempFolderPath error:nil];
        
        if ([fileList containsObject:@"widget"] && [fileList containsObject:@"plugin"]) {//新版本的补丁包
            NSString * widgetPath = [tempFolderPath stringByAppendingPathComponent:@"widget/"];
            NSArray * widgetPathFolderList = [fileMgr contentsOfDirectoryAtPath:widgetPath error:nil];
            
            widgetPath = [widgetPath stringByAppendingPathComponent:[widgetPathFolderList firstObject]];
            
            ACENSLog(@"新版本的补丁包:\n%@\n%@\n%@",widgetPath,outPath);
            
            if ([self copyItemsFromPath:widgetPath toPath:outPath]) {
                
                NSLog(@"=====新版本的补丁包=====:\n%@\n%@",widgetPath,outPath);
                
                [fileMgr removeItemAtPath:tempFolderPath error:nil];
                [fileMgr removeItemAtPath:sourceWgt error:nil];
                return YES;
            }
        } else {//旧版本的补丁包
            ACENSLog(@"旧版本的补丁包:%@",tempFolderPath);
            if ([self copyItemsFromPath:tempFolderPath toPath:outPath]) {
                NSLog(@"=====旧版本的补丁包=====:\n%@\n%@",tempFolderPath,outPath);
                [fileMgr removeItemAtPath:tempFolderPath error:nil];
                [fileMgr removeItemAtPath:sourceWgt error:nil];
                return YES;
            }
        }
        
    }
    
    [fileMgr removeItemAtPath:tempFolderPath error:nil];
    return NO;
    
}

- (BOOL)copyItemsFromPath:(NSString *)fromPath toPath:(NSString *)toPath {
    
    NSError * error;
    NSFileManager * fileMgr = [NSFileManager defaultManager];
    
    BOOL folderFlag = YES;
    
    if (![fileMgr fileExistsAtPath:toPath isDirectory:&folderFlag]) {//如果目标路径不存在则创建
        BOOL result = [fileMgr createDirectoryAtPath:toPath withIntermediateDirectories:YES attributes:nil error:&error];
        [BUtility addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:toPath]];
        if (!result && error) {
            return NO;
        }
    }
    
    if ([fileMgr fileExistsAtPath:fromPath]) {
        NSError * error;
        NSDirectoryEnumerator * fromEnumerator = [fileMgr enumeratorAtPath:fromPath];
        NSString * fileName = nil;
        BOOL result;
        while ((fileName = [fromEnumerator nextObject])) {
            NSString * oldFilePath = [fromPath stringByAppendingPathComponent:fileName];
            NSString * newFilePath = [toPath stringByAppendingPathComponent:fileName];
            BOOL flag = YES;
            if ([fileMgr fileExistsAtPath:oldFilePath isDirectory:&flag]) {
                if (!flag) {
                    if (![[fileName substringToIndex:1] isEqualToString:@"."]) {
                        if ([fileMgr fileExistsAtPath:newFilePath]) {
                            result = [fileMgr removeItemAtPath:newFilePath error:&error];
                            if (!result && error) {
                                return NO;
                            }
                        }
                        result =  [fileMgr copyItemAtPath:oldFilePath toPath:newFilePath error:&error];
                        if (!result && error) {
                            return NO;
                        }
                    }
                } else {
                    result = [fileMgr createDirectoryAtPath:newFilePath withIntermediateDirectories:YES attributes:nil error:&error];
                    if (!result && error) {
                        return NO;
                    }
                }
            }
        }
    } else {
        return NO;
    }
    return YES;
}


-(NSString *)md5:(NSString *)str {
	const char *cStr = [str UTF8String];	
	unsigned char result[16];
	
	CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
	
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",			
			result[0], result[1], result[2], result[3], 			
			result[4], result[5], result[6], result[7],			
			result[8], result[9], result[10], result[11],			
			result[12], result[13], result[14], result[15]			
			]; 
}
-(void)removeAllUD:(NSString*)idStr{
    NSUserDefaults *ud =[NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:F_UD_UpdateWgtID];
    [ud removeObjectForKey:[NSString stringWithFormat:@"%@_currentSize",idStr]];
    [ud removeObjectForKey:[NSString stringWithFormat:@"%@_lastTime",idStr]];
    [ud removeObjectForKey:[NSString stringWithFormat:@"%@_fileSize",idStr]];
    [ud removeObjectForKey:[NSString stringWithFormat:@"%@@_savePath",idStr]];
    [ud synchronize];
}
@end
