#import <Foundation/Foundation.h>
#import <sysexits.h>
#import <dlfcn.h>

@interface NSDictionary ()
+ (NSDictionary *)plistWithDescriptionData:(NSData *)data error:(NSError **)error;
- (id)plistDescriptionUTF8Data;
@end

@protocol PBXPListArchiverStringWithComment <NSObject>

- (id)initWithString:(NSString *)string comment:(NSString *)comment;

@end

int main(int argc, char *const *argv) { @autoreleasepool {

    NSLog(@"start");
    
    if (!getenv("D0NE")) {
        setenv("D0NE", "", 1);
        
        NSString *xcodePath =
        [[NSString alloc] initWithData:
         [[[NSFileHandle alloc] initWithFileDescriptor:fileno(popen("/usr/bin/xcode-select --print-path", "r"))
                                        closeOnDealloc:YES] readDataToEndOfFile]
                              encoding:NSUTF8StringEncoding];
        NSCParameterAssert([xcodePath length] > 0);

        NSLog(@"xcode-select");
        
        setenv("DYLD_FRAMEWORK_PATH",
               [[NSString stringWithFormat:@"%1$@/Frameworks:%1$@/SharedFrameworks:%1$@/PlugIns/Xcode3Core.ideplugin/Contents/Frameworks",
                 xcodePath.stringByDeletingLastPathComponent]
                cStringUsingEncoding:NSUTF8StringEncoding],
               1);
        
        NSCParameterAssert(execvp(argv[0], argv) != -1);
    }

    NSLog(@"loaded");
    
    NSCAssert(dlopen("DevToolsCore.framework/DevToolsCore", RTLD_NOW), @"%s", dlerror());

    NSLog(@"dlopen");
    
    NSArray *arguments = [NSProcessInfo processInfo].arguments;
    arguments = [arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)];
    
    if ([arguments count] == 0) {
        arguments = [[NSFileManager defaultManager]
                     contentsOfDirectoryAtPath:[[NSFileManager defaultManager] currentDirectoryPath]
                     error:nil];
        arguments = [arguments filteredArrayUsingPredicate:
                     [NSPredicate predicateWithFormat:@"self ENDSWITH 'xcodeproj'"]];
        NSCAssert([arguments count] != 0, @"xcodeproj file not found in the current directory");
        NSCAssert([arguments count] == 1, @"multiple xcodeproj files found in the current directory");
    }

    NSLog(@"found project");
    
    for (NSString *arg in arguments) {
        NSString *path = arg;
        if ([path.lastPathComponent.pathExtension isEqualToString:@"xcodeproj"]) {
            path = [path stringByAppendingPathComponent:@"project.pbxproj"];
        }
        
        NSError *error = nil;
        NSData *dataIn = [NSData dataWithContentsOfFile:path options:0 error:&error];
        NSCAssert(dataIn && error == nil, [error description]);
        NSMutableDictionary *obj = (id)[NSMutableDictionary plistWithDescriptionData:dataIn error:nil];
        NSCParameterAssert(obj);

        NSMutableDictionary *res = [@{} mutableCopy];

        [obj[@"objects"] enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableDictionary *obj, BOOL *stop) {
            if ([obj[@"isa"] isEqual:@"PBXBuildFile"] || [obj[@"isa"] isEqual:@"PBXFileReference"]) {
                obj[@"___PlistArchiveAtomicDictionary"] = @YES;
            }
            key = [[NSClassFromString(@"PBXPListArchiverStringWithComment") alloc] initWithString:key comment:@"LALA"];
            res[key] = obj;
        }];

        obj[@"objects"] = res;

        NSData *dataOut = [obj plistDescriptionUTF8Data];
        NSCParameterAssert(dataOut);
        NSCParameterAssert([dataOut writeToFile:path options:0 error:nil]);

        NSLog(@"written");
    }
    
    return EX_OK;
}}
