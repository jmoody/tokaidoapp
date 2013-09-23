#import <Foundation/Foundation.h>
#import "LjsUnixOperationResult.h"

extern NSString *LjsUnixOperationTaskErrorDomain;

typedef enum : NSUInteger {
  LjsUnixOperationLaunchErrorCode = 5446,
  LjsUnixOperationExecutionErrorCode = -4398116,
  // for those times when the task is still running, but has exited the while loop
  LjsUnixOperationTaskStillRunningExitCode = 711
} LjsUnixOpErrorCode;


/**
 Provides a callback that the LjsUnixOperation can use to deliver the result
 of executing a Unix command.
 */
@protocol LjsUnixOperationCallbackDelegate <NSObject>

@required
/**
 A callback that the LjsUnixOperation will use to deliver results at the end
 of execution.
 
 The name parameter is a unique id that the callback delegate can use to 
 discern what operation completion prompted the callback.
 
 @param aName the name of the operation that completed
 @param aResult the result of the operation
 */
- (void) operationCompletedWithName:(NSString *) aName
                             result:(LjsUnixOperationResult *) aResult;
@end

/**
 LjsUnixOperation is a robust wrapper around NSTask.  The TpUnixOperationResult
 is a comprehensive record of the unlying Unix command and this NSTask's
 execution.
 
 The following error codes are extern'd to help the caller determine what went
 wrong during execution.
 
 - LjsUnixOperationLaunchErrorCode - problem launching
 - LjsUnixOperationExecutionErrorCode - problem executing
 
 The exit code of the Unix command is recorded in the TpUnixOperationResult, but
 sometimes the task is still running when the main is complete.  This is not an
 error per-se, but rather a condition that must be handled.  To help identify
 such states, the following exit code is extern'd:

 - LjsUnixOperationTaskStillRunningExitCode - indicates the task is still running

 */
@interface LjsUnixOperation : NSOperation

/** @name Properties */
/** the common name of this operation  - might be better described as the unique id */
@property (nonatomic, copy) NSString *commonName;
/** data from stdout */
@property (nonatomic, strong) NSMutableData *standardOutput;
/** data from stderr */
@property (nonatomic, strong) NSMutableData *standardError;
/** true iff stdout is closed */
@property (nonatomic, assign) BOOL outputClosed;
/** true iff stderr is closed */
@property (nonatomic, assign) BOOL errorClosed;
/** true iff task is complete - this never happens, but is included for completeness */
@property (nonatomic, assign) BOOL taskComplete;
/** the task associated with this operation */
@property (nonatomic, strong) NSTask *task;
/** a character set used to trim white space and newlines from stdout and stderr*/
@property (nonatomic, strong) NSCharacterSet *trimSet;
/** the callback delegate */
@property (nonatomic, unsafe_unretained) id<LjsUnixOperationCallbackDelegate> callbackDelegate;

/** @name Memory Management */
- (id) initWithLaunchPath: (NSString *) aLaunchPath 
               launchArgs: (NSArray *) aLaunchArgs 
               commonName:(NSString *) aCommonName
         callbackDelegate:(id<LjsUnixOperationCallbackDelegate>) aCallbackDelegate;

/** @name Notification Handling */
- (void) handleStandardOutNotification:(NSNotification *) aNotification;
- (void) handleStandardErrorNotification:(NSNotification *) aNotification;
- (void) handleTaskTerminatedNotification:(NSNotification *) aNotification;

/** @name Utility */
- (NSString *) stringWithData:(NSData *) aData;
- (NSError *) errorWithException:(NSException *) aException;
- (NSError *) errorWithStandardErrorString:(NSString *) aErrorString;


@end
