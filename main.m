#import <Foundation/Foundation.h>
#import <sysexits.h>
#import <dlfcn.h>

@interface NSDictionary ()
+ (NSDictionary *)plistWithDescriptionData:(NSData *)data error:(NSError **)error;
- (id)plistDescriptionUTF8Data;
@end

@protocol PBXPListUnarchiver
- (id)initWithPListArchive:(NSDictionary *)archive userSettings:(id)settings contextInfo:(NSDictionary *)contextInfo;
- (void)setDelegate:(id)delegate;
- (id)decodeRootObject;
@end

@protocol PBXPListArchiver
- (id)initWithRootObject:(id)arg1 delegate:(id)arg2;
- (id)plistArchive;
@end

@protocol PBXProject
+ (void)removeContainerForResolvedAbsolutePath:(NSString *)idd;
@end

int main(int argc, char *const *argv) { @autoreleasepool {
    
    if (!getenv("D0NE")) {
        setenv("D0NE", "", 1);
        
        NSString *xcodePath =
        [[NSString alloc] initWithData:
         [[[NSFileHandle alloc] initWithFileDescriptor:fileno(popen("/usr/bin/xcode-select --print-path", "r"))
                                        closeOnDealloc:YES] readDataToEndOfFile]
                              encoding:NSUTF8StringEncoding];
        NSCParameterAssert([xcodePath length] > 0);
        
        setenv("DYLD_FRAMEWORK_PATH",
               [[NSString stringWithFormat:@"%1$@/Frameworks:%1$@/SharedFrameworks",
                 xcodePath.stringByDeletingLastPathComponent]
                cStringUsingEncoding:NSUTF8StringEncoding],
               1);
        
        NSCParameterAssert(execvp(argv[0], argv) != -1);
    }
    
    NSCAssert(dlopen("IDEFoundation.framework/IDEFoundation", RTLD_NOW), @"%s", dlerror());
    
    BOOL(*IDEInitialize)(int initializationOptions, NSError **error) = dlsym(RTLD_DEFAULT, "IDEInitialize");
    NSCParameterAssert(IDEInitialize);
    NSCParameterAssert(IDEInitialize(1, nil));
    
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
    
    for (NSString *arg in arguments) {
        NSString *path = arg;
        if ([path.lastPathComponent.pathExtension isEqualToString:@"xcodeproj"]) {
            path = [path stringByAppendingPathComponent:@"project.pbxproj"];
        }
        
        NSError *error = nil;
        NSData *dataIn = [NSData dataWithContentsOfFile:path options:0 error:&error];
        NSCAssert(dataIn && error == nil, [error description]);
        NSDictionary *obj = [NSDictionary plistWithDescriptionData:dataIn error:nil];
        NSCParameterAssert(obj);
        
        NSString *projectPath =
        [NSProcessInfo processInfo].environment[@"XCODEPROJ_PATH"]
        ?: [NSURL fileURLWithPath:path].absoluteURL.URLByDeletingLastPathComponent.path;
        
        NSDictionary *contextInfo = @{
            @"path": [NSURL fileURLWithPath:projectPath].absoluteURL.path,
            @"read-only": @0,
            @"upgrade-log": [NSClassFromString(@"PBXLogOutputString") new],
        };
        id<PBXPListUnarchiver> unarchiver = [[NSClassFromString(@"PBXPListUnarchiver") alloc]
                                             initWithPListArchive:obj userSettings:nil contextInfo:contextInfo];
        NSCParameterAssert(unarchiver);
        [unarchiver setDelegate:NSClassFromString(@"PBXProject")];
        id project = [unarchiver decodeRootObject];
        NSCParameterAssert(project);
        
        id<PBXPListArchiver> archiver = [[NSClassFromString(@"PBXPListArchiver") alloc]
                                         initWithRootObject:project delegate:project];
        NSCParameterAssert(archiver);
        NSData *dataOut = [[archiver plistArchive] plistDescriptionUTF8Data];
        NSCParameterAssert(dataOut);
        NSCParameterAssert([dataOut writeToFile:path options:0 error:nil]);
        
        [NSClassFromString(@"PBXProject") removeContainerForResolvedAbsolutePath:contextInfo[@"path"]];
    }
    
    return EX_OK;
}}
