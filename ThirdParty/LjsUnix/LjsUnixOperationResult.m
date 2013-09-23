#import "LjsUnixOperationResult.h"


@implementation LjsUnixOperationResult

#pragma mark Memory Management

- (id) initWithCommonName:  (NSString *) aCommonName  
                 exitCode: (NSInteger) anExitCode  
              launchError: (NSError *) aLaunchError  
           executionError: (NSError *) anExecutionError 
                stdOutput: (NSString *) aStdOutput  
                errOutput: (NSString *) anErrOutput 
               launchPath:(NSString *)aLaunchPath 
                arguments:(NSArray *)aArguments 
             wasCancelled:(BOOL)aWasCancelled {
  self = [super init];
  if (self) {
    self.commonName = aCommonName;
    self.exitCode = anExitCode;
    self.launchError = aLaunchError;
    self.executionError = anExecutionError;
    self.stdOutput = aStdOutput;
    self.errOutput = anErrOutput;
    self.launchPath = aLaunchPath;
    self.arguments = aArguments;
    self.wasCancelled = aWasCancelled;
  }
  return self;
}

- (NSString *) description {
  return [NSString stringWithFormat:@"%@: %ld %@ %@", 
          self.commonName, self.exitCode, self.stdOutput, self.errOutput];
}

@end
