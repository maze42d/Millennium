#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <iostream>
#include "exec.h"

void showErrorDialog(NSString *title, NSString *message) 
{
    dispatch_async(dispatch_get_main_queue(), 
    ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = title;
        alert.informativeText = message;
        alert.alertStyle = NSAlertStyleCritical;

        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    });
}

pid_t StartMillennium()
{
    @autoreleasepool
    {
        NSString *currentDirectoryPath = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
        NSString *executablePath = [currentDirectoryPath stringByAppendingPathComponent:@"Millennium.Patcher"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:executablePath])
        {
            NSString *errorMsg = [NSString stringWithFormat:@"Millennium executable not found at:\n%@", executablePath];
            std::cout << "Error: " << errorMsg.UTF8String << std::endl;
            showErrorDialog(@"Millennium Not Found", errorMsg);
            return -1;
        }
        
        if (![fileManager isExecutableFileAtPath:executablePath])
        {
            NSString *errorMsg = [NSString stringWithFormat:@"File is not executable:\n%@", executablePath];
            std::cout << "Error: " << errorMsg.UTF8String << std::endl;
            showErrorDialog(@"File Not Executable", errorMsg);
            return -1;
        }
        
        // Set up log file at /tmp/millennium.out
        NSString *logFilePath = @"/tmp/millennium.out";
        [fileManager createFileAtPath:logFilePath contents:nil attributes:nil];
        NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        
        if (!logFileHandle) 
        {
            NSString *errorMsg = @"Failed to create or open log file at /tmp/millennium.out";
            std::cout << "Error: " << errorMsg.UTF8String << std::endl;
            showErrorDialog(@"Log File Error", errorMsg);
            return -1;
        }
        
        [logFileHandle truncateFileAtOffset:0]; // Overwrite instead of append
        
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = executablePath;
        task.currentDirectoryPath = currentDirectoryPath;
        task.environment = [[NSProcessInfo processInfo] environment];
        task.standardOutput = logFileHandle;
        task.standardError = logFileHandle;
        
        task.terminationHandler = ^(NSTask *task) 
        {
            if ([task terminationStatus] != 0) 
            {
                NSString *errorMsg = [NSString stringWithFormat:@"Millennium process (PID: %d) terminated with error code: %d\n\nCheck /tmp/millennium.out for details.", [task processIdentifier], [task terminationStatus]];
                std::cout << "Millennium process (PID: " << [task processIdentifier] << ") terminated with error code: " << [task terminationStatus] << std::endl;
                showErrorDialog(@"Millennium Process Error", errorMsg);
            }
            [logFileHandle closeFile];
        };
        
        @try
        {
            [task launch];
            pid_t pid = [task processIdentifier];
            std::cout << "Successfully launched Millennium with PID: " << pid << std::endl;
            return pid;
        }
        @catch (NSException *exception)
        {
            NSString *errorMsg = [NSString stringWithFormat:@"Failed to launch Millennium:\n%@", exception.reason];
            std::cout << "Failed to launch Millennium: " << exception.reason.UTF8String << std::endl;
            showErrorDialog(@"Launch Failed", errorMsg);
            [logFileHandle closeFile];
            return -1;
        }
    }
}