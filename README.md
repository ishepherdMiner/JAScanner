![效果图](https://i.loli.net/2019/04/09/5cac0d7d449ec.png)

## Installation

CocoaPods

```sh
pod 'JAScanner'
```

## Usage

```objc
#import <JAScanner/JAScanner.h>

```

```objc
// provide an container view
JAScanner *scanner = [JAScanner scanAtView:self.view];

// start scanning and set a completion block
[scanner startWithCompletionHandler:^(NSString * _Nonnull result) {
    NSLog(@"%@",result);
}];    
self.scanner = scanner;
```

when leave scan screen

```objc
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.scanner.state = JAScannerStateLeaveScene;
}

// or manual
[self.scanner stopRecognize];
```
