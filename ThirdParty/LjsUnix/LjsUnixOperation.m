#import "LjsUnixOperation.h"

// the error domain
NSString *LjsUnixOperationTaskErrorDomain = @"com.littlejoysoftware.Ljs Unix Operation";


@implementation LjsUnixOperation

#pragma mark Memory Management
- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                  name:NSFileHandleDataAvailableNotification
                                                object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                  name:NSTaskDidTerminateNotification
                                                object:nil];
}

/**
 Configures the task, sets up the pipes and file handles and registers for the
 appropriate notifications.
 
 @return an initialized receiver
 @param aLaunchPath the launch path of the unix command
 @param aLaunchArgs the arguments (as required by NSTask)
 @param aCommonName the name of this operation
 @param aCallbackDelegate the callback delegate
 */
- (id) initWithLaunchPath: (NSString *) aLaunchPath 
               launchArgs: (NSArray *) aLaunchArgs 
               commonName:(NSString *) aCommonName
         callbackDelegate:(id<LjsUnixOperationCallbackDelegate>) aCallbackDelegate {
  self = [super init];
  if (self != nil) {
    self.commonName = aCommonName;
    self.outputClosed = NO;
    self.errorClosed = NO;
    self.taskComplete = NO;
    self.callbackDelegate = aCallbackDelegate;
    
    NSMutableData *data;
    data = [[NSMutableData alloc] init];
    self.standardOutput = data;
    data = [[NSMutableData alloc] init];
    self.standardError = data;
    
    NSTask *tTask = [[NSTask alloc] init];
    self.task = tTask;
    
    [self.task setLaunchPath:aLaunchPath];
    [self.task setArguments:aLaunchArgs];
    NSPipe *tPipe;
    tPipe = [[NSPipe alloc] init];
    [self.task setStandardOutput:tPipe];
    tPipe = [[NSPipe alloc] init];
    [self.task setStandardError:tPipe];
    
    // might consider making these ivars for memory reasons
    NSFileHandle *stdOut = [[self.task standardOutput] fileHandleForReading];
    NSFileHandle *stdErr = [[self.task standardError] fileHandleForReading];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(handleStandardOutNotification:)
                   name:NSFileHandleDataAvailableNotification
                 object:stdOut];
    
    [center addObserver:self
               selector:@selector(handleStandardErrorNotification:) 
                   name:NSFileHandleDataAvailableNotification
                 object:stdErr];

    // we do this for completeness - it is unlikely that we ever see this
    [center addObserver:self
               selector:@selector(handleTaskTerminatedNotification:) 
                   name:NSTaskDidTerminateNotification
                 object:self.task];

    
    [stdOut waitForDataInBackgroundAndNotify];
    [stdErr waitForDataInBackgroundAndNotify];
    
    self.trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  }
  return self;
}

/**
 receives a data available notification and attempts to extract the data and
 append it to the stdout data.
 
 uses a try/catch block to handle cases where the data has become unavailable.
 in practice, this can occur when the operation is started and quickly cancelled.
 
 @param aNotification the object of which is the file handle for stdout
 */
- (void) handleStandardOutNotification:(NSNotification *) aNotification {
  NSFileHandle *handle = (NSFileHandle *)[aNotification object];
  
  @try {
    NSData *availableData = [handle availableData];
    if ([availableData length] == 0) {
      self.outputClosed = YES;
    } else {
      [self.standardOutput appendData:availableData];
      [handle waitForDataInBackgroundAndNotify];
    }
  }
  @catch (NSException *exception) {
    // this can can happen if the operation is cancelled
    NSLog(@"caught exception - nothing to do: %@", exception);
  }
  @finally {
    
  }
 
}

/**
 receives a data available notification and attempts to extract the data and
 append it to the stderr data.
 
 uses a try/catch block to handle cases where the data has become unavailable.
 in practice, this can occur when the operation is started and quickly cancelled.
 
 @param aNotification the object of which is the file handle for stderr
 */
- (void) handleStandardErrorNotification:(NSNotification *) aNotification {
  NSFileHandle *handle = (NSFileHandle *)[aNotification object];
  @try {
    NSData *availableData = [handle availableData];
    if ([availableData length] == 0) {
      self.errorClosed = YES;
    } else {
      [self.standardError appendData:availableData];
      [handle waitForDataInBackgroundAndNotify];
    }

  }
  @catch (NSException *exception) {
    // can happen if the operation is cancelled
    NSLog(@"caught exception - nothing to do: %@", exception);
  }
  @finally {
    
  }
}

/**
 If received, sets the taskComplete property to YES.  However, I have never
 seen this called, although it should be.  See the while loop in the main to 
 see how we check for task completion.
 @param aNotification ignored
 */
- (void) handleTaskTerminatedNotification:(NSNotification *) aNotification {
  self.taskComplete = YES;
}

/**
 @return a string from the data using NSUTF8StringEncoding
 @param aData the data
 */
- (NSString *) stringWithData:(NSData *) aData {
  return [[NSString alloc] initWithData:aData
                                encoding:NSUTF8StringEncoding];
}

/**
 @return an error using the exception
 @param aException the exception to make the error from
 */
- (NSError *) errorWithException:(NSException *) aException {
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey: [aException reason]};

  NSError *result = [NSError errorWithDomain:LjsUnixOperationTaskErrorDomain
                                        code:LjsUnixOperationLaunchErrorCode
                                    userInfo:userInfo];
  return result;
}

/**
 @return an error with a string 
 @param aErrorString a string from stderr
 */
- (NSError *) errorWithStandardErrorString:(NSString *) aErrorString {
  NSError *result = nil;
  if ([aErrorString length] > 0) {
    NSDictionary *userInfo =
    @{NSLocalizedDescriptionKey: aErrorString};
    result = [NSError
              errorWithDomain:LjsUnixOperationTaskErrorDomain
              code:LjsUnixOperationExecutionErrorCode
              userInfo:userInfo];
  }
  return result;
}

/** @name Main Method */

/** 
 Required method for NSOperation subclasses.
 */
- (void) main {
  @autoreleasepool {
    if (![self isCancelled]) {
    
      // I do not think this is necessary
      NSDictionary *environment = [[NSProcessInfo processInfo] environment];
      [self.task setEnvironment:environment];
      
      NSError *launchError = nil;
      NSString *outputString = nil;
      NSString *errorString = nil;

      @try {
        [self.task launch];
 
        // if the stdout and stderr are closed, then the task should be considered
        // done.  we cannot rely on the NSTaskDidTerminateNotification notification
        // to ever be sent.
        while (!self.outputClosed || !self.errorClosed) {

          // NSLog(@"is running       => %d", [self.task isRunning]);
          // NSLog(@"is error closed  => %d", self.errorClosed);
          // NSLog(@"is output closed => %d", self.outputClosed);
          // NSLog(@"is cancelled     => %d", [self isCancelled]);
          // NSLog(@"is complete      => %d", self.taskComplete);
          
          // could be put in the while invariant, but there are so many conditions
          // it becomes unclear what is really driving the loop.
          //
          // what is essential is that if we receive a cancel message
          // we need to respect it (see NSOperation subclassing notes).
          //
          // the taskComplete is syntatic sugar because in practice it is never
          // anything but NO
          if ([self isCancelled] || self.taskComplete) {
            break;
          }
        }
        
        outputString = [self stringWithData:self.standardOutput];
        errorString = [self stringWithData:self.standardError];
      } @catch (NSException *exception) {
        NSLog(@"received this exception: %@", exception);
        launchError = [self errorWithException:exception];
      } @finally {
        if ([self.task isRunning]) {
          // not guaranteed to stop the task
          [self.task terminate];
        }
        [[[self.task standardError] fileHandleForReading] closeFile];
        [[[self.task standardOutput] fileHandleForReading] closeFile];
      }
      
      
      NSError *executionError = [self errorWithStandardErrorString:errorString];
      NSInteger taskExitCode = LjsUnixOperationExecutionErrorCode;
      if (launchError == nil && ![self.task isRunning]) {
        taskExitCode = [self.task terminationStatus];
      } else {
        taskExitCode = LjsUnixOperationTaskStillRunningExitCode;
      }
      
      if (outputString != nil) {
        outputString = [outputString stringByTrimmingCharactersInSet:self.trimSet];
      }
      
      if (errorString != nil) {
        errorString = [errorString stringByTrimmingCharactersInSet:self.trimSet];
      }
      
      LjsUnixOperationResult *tResult = [[LjsUnixOperationResult alloc]
                                        initWithCommonName:self.commonName
                                        exitCode:taskExitCode 
                                        launchError:launchError 
                                        executionError:executionError
                                        stdOutput:outputString
                                        errOutput:errorString
                                        launchPath:[self.task launchPath]
                                        arguments:[self.task arguments]
                                        wasCancelled:[self isCancelled]];
                                         
      if (self.callbackDelegate != nil) {
        [self.callbackDelegate operationCompletedWithName:self.commonName
                                                   result:tResult];
      } 
    }
  }
}


@end
