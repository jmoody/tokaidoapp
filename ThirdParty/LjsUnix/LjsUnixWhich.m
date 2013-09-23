#import "LjsUnixWhich.h"

static NSString *LjsUnixWhichWhichLaunchPath = @"/usr/bin/which";

static NSString *LjsUnixWhichIfconfig = @"ifconfig";
static NSString *LjsUnixWhichIfconfigDefaultLaunchPath = @"/sbin/ifconfig";
static NSString *LjsUnixWhichIfconfigCommandName = @"me.twistedpair.TwistedPair which ifconfig";

static NSString *LjsUnixWhichIpconfig = @"ipconfig";
static NSString *LjsUnixWhichIpconfigDefaultLaunchPath = @"/usr/sbin/ipconfig";
static NSString *LjsUnixWhichIpconfigCommandName = @"me.twistedpair.TwistedPair which ipconfig";

static NSString *LjsUnixWhichDefaults = @"defaults";
static NSString *LjsUnixWhichDefaultDefaultsLaunchPath = @"/usr/bin/defaults";
static NSString *LjsUnixWhichDefaultsCommandName = @"me.twistedpair.TwistedPair which defaults";

@implementation LjsUnixWhich

#pragma mark Memory Management
- (void) dealloc {
  [self.opqueue cancelAllOperations];
}

- (id) init {
  self = [super init];
  if (self != nil) {
  
    self.ifconfigLaunchPath = LjsUnixWhichIfconfigDefaultLaunchPath;
    self.ipconfigLaunchPath = LjsUnixWhichIpconfigDefaultLaunchPath;
    self.defaultsLaunchPath = LjsUnixWhichDefaultDefaultsLaunchPath;
    
    self.opqueue = [[NSOperationQueue alloc]
                     init];
    
    [self asyncFindIfConfigLaunchPath];
    [self asyncFindIpConfigLaunchPath];
    [self asyncFindDefaultsLaunchPath];
  }
  return self;
}

#pragma mark Unix Operation Callback Delegate
/** @name LjsUnixOperationCallbackDelegate Protocol */
/**
 A callback that the LjsUnixOperation will use to deliver results at the end
 of execution.
 
 The name parameter is a unique id that the callback delegate can use to 
 discern what operation completion prompted the callback.
 
 There is no special error handling - here failure is not a disaster because
 we can fall back on the hardcoded command paths.
 
 @param aName the name of the operation that completed
 @param aResult the result of the operation
 @warning could use a refactor to reduce code duplication.
 */
- (void) operationCompletedWithName:(NSString *)aName result:(LjsUnixOperationResult *)aResult {
  if ([LjsUnixWhichIfconfigCommandName isEqualToString:aName]) {
    if (aResult.wasCancelled == YES) {
      NSLog(@"operation was cancelled - nothing to do");
    } else if (aResult.launchError != nil) {
      NSLog(@"ERROR: there was a launch ERROR:  %@", [aResult.launchError localizedDescription]);
    } else if (aResult.executionError != nil) {
      NSLog(@"ERROR: there was an execution ERROR:  %@", [aResult.executionError localizedDescription]);
    } else if (aResult.stdOutput == nil || [aResult.stdOutput length] == 0) {
      NSLog(@"ERROR: expected some output to standard out - found < %@ >", aResult.stdOutput);
    } else {
      NSLog(@"setting ifconfig launch path to %@", aResult.stdOutput);
      self.ifconfigLaunchPath = aResult.stdOutput;
    }
  } else if ([LjsUnixWhichIpconfigCommandName isEqualToString:aName]) {
    if (aResult.wasCancelled == YES) {
      NSLog(@"operation was cancelled - nothing to do");
    } else if (aResult.launchError != nil) {
      NSLog(@"ERROR: there was a launch ERROR:  %@", [aResult.launchError localizedDescription]);
    } else if (aResult.executionError != nil) {
      NSLog(@"ERROR: there was an execution ERROR:  %@", [aResult.executionError localizedDescription]);
    } else if (aResult.stdOutput == nil || [aResult.stdOutput length] == 0) {
      NSLog(@"ERROR: expected some output to standard out - found < %@ >", aResult.stdOutput);
    } else {
      NSLog(@"setting ifconfig launch path to %@", aResult.stdOutput);
      self.ipconfigLaunchPath = aResult.stdOutput;
    }
  } else if ([LjsUnixWhichDefaultsCommandName isEqualToString:aName]) {
    if (aResult.wasCancelled == YES) {
      NSLog(@"operation was cancelled - nothing to do");
    } else if (aResult.launchError != nil) {
      NSLog(@"ERROR: there was a launch ERROR:  %@", [aResult.launchError localizedDescription]);
    } else if (aResult.executionError != nil) {
      NSLog(@"ERROR: there was an execution ERROR:  %@", [aResult.executionError localizedDescription]);
    } else if (aResult.stdOutput == nil || [aResult.stdOutput length] == 0) {
      NSLog(@"ERROR: expected some output to standard out - found < %@ >", aResult.stdOutput);
    } else {
      NSLog(@"setting defaults launch path to %@", aResult.stdOutput);
      self.defaultsLaunchPath = aResult.stdOutput;
    }
  } else {
    NSLog(@"ERROR: unknown common name = %@", aName);
    //NSAssert(NO, nil);
  }
}


- (void) asyncFindIfConfigLaunchPath {
  NSLog(@"starting async find of ifconfig launch path");
  LjsUnixOperation *uop = [[LjsUnixOperation alloc]
                           initWithLaunchPath:LjsUnixWhichWhichLaunchPath
                           launchArgs:@[LjsUnixWhichIfconfig]
                           commonName:LjsUnixWhichIfconfigCommandName
                           callbackDelegate:self];
  
  [self.opqueue addOperation:uop];
}

- (void) asyncFindIpConfigLaunchPath {
  NSLog(@"starting async find of ipconfig launch path");
  LjsUnixOperation *uop = [[LjsUnixOperation alloc]
                           initWithLaunchPath:LjsUnixWhichWhichLaunchPath
                           launchArgs:@[LjsUnixWhichIpconfig]
                           commonName:LjsUnixWhichIpconfigCommandName
                           callbackDelegate:self];
  
  [self.opqueue addOperation:uop];
}

- (void) asyncFindDefaultsLaunchPath {
  NSLog(@"starting async find of defaults launch path");
  LjsUnixOperation *uop = [[LjsUnixOperation alloc]
                           initWithLaunchPath:LjsUnixWhichWhichLaunchPath
                           launchArgs:@[LjsUnixWhichDefaults]
                           commonName:LjsUnixWhichDefaultsCommandName
                           callbackDelegate:self];
  
  [self.opqueue addOperation:uop];
}


@end
