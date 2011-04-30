//
//  DockityAppDelegate.m
//  Dockity
//
//  Created by Dmitry Chestnykh on 4/30/11.
//  Copyright 2011 Coding Robots. All rights reserved.
//

#import "DockityAppDelegate.h"


@implementation DockityAppDelegate

@synthesize window;

enum {
  DockPosLeft,
  DockPosRight,
  DockPosBottom
};

static CGFloat hiddenDockWidth = 4;
static CGFloat topMenuHeight = 22;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  [self activateStatusMenu];
  lastVisibleFrame = [[NSScreen mainScreen] visibleFrame];
//  [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(recalculate:) userInfo:nil repeats:YES];
  [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDragged handler:^(NSEvent *event) { [self recalculate:event];
  }];
}

- (void)activateStatusMenu
{
  NSMenu *menu = [[NSMenu alloc] init];
  NSMenuItem *refreshItem = [[NSMenuItem alloc] initWithTitle:@"Refresh" action:@selector(recalculate:) keyEquivalent:@""];
  [menu addItem:refreshItem];
  [refreshItem release];
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit Dockity" action:@selector(terminate:) keyEquivalent:@""];
  [menu addItem:[NSMenuItem separatorItem]];
  [menu addItem:quitItem];
  [quitItem release];
  
  NSStatusBar *bar = [NSStatusBar systemStatusBar];
  NSStatusItem *item = [[bar statusItemWithLength:NSVariableStatusItemLength] retain];
  [item setTitle:NSLocalizedString(@"D",@"")];
  [item setHighlightMode:YES];
  [item setMenu:menu];
}

- (BOOL)shouldHideDockForWindowRect:(NSRect)winRect {
  switch (lastDockPos) {
    case DockPosRight:
      return winRect.origin.x + winRect.size.width > lastVisibleFrame.size.width;
    case DockPosLeft:
      return winRect.origin.x < lastVisibleFrame.origin.x;
    case DockPosBottom:
      return winRect.origin.y + winRect.size.height - topMenuHeight > lastVisibleFrame.size.height;
  }
  return NO; // should not happen
}


- (void)updateLastDockPos {
  NSRect screenFrame = [[NSScreen mainScreen] frame];
  if (lastVisibleFrame.origin.x > screenFrame.origin.x) {
    lastDockPos = DockPosLeft;
    return;
  }
  if (lastVisibleFrame.size.width < screenFrame.size.width) {
    lastDockPos = DockPosRight;
    return;
  }
  lastDockPos = DockPosBottom;
}

- (BOOL)isDockHidden {
  NSRect visibleFrame = [[NSScreen mainScreen] visibleFrame];
  NSRect screenFrame = [[NSScreen mainScreen] frame];
  
  BOOL isHidden;
  switch (lastDockPos) {
    case DockPosLeft:
      isHidden = (visibleFrame.origin.x <= screenFrame.origin.x + hiddenDockWidth);
      break;
    case DockPosRight:
      isHidden = (visibleFrame.size.width + hiddenDockWidth >= screenFrame.size.width);
      break;
    case DockPosBottom:
      isHidden = (visibleFrame.size.height + hiddenDockWidth >= screenFrame.size.height - topMenuHeight);
      break;
  }

  if (!isHidden) {
    // Update lastVisibleFrame
    lastVisibleFrame = visibleFrame;
  }
  
  return isHidden;
}

- (long)currentAppPID {
  NSDictionary *currentAppInfo = [[NSWorkspace sharedWorkspace] activeApplication];
  return [[currentAppInfo objectForKey:@"NSApplicationProcessIdentifier"] longValue];
}

- (void)recalculate:(id)sender {
  BOOL shouldHideDock = NO;
//  BOOL shouldFillScreen = NO;
//  long currentAppPID = [self currentAppPID];
  
  [self updateLastDockPos];


  CFArrayRef windows = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
  for (NSDictionary *w in (NSArray*)windows) {
    NSString *owner = [w objectForKey:@"kCGWindowOwnerName"];
    if ([[w objectForKey:@"kCGWindowLayer"] integerValue] == 25 ||
        [owner isEqualToString:@"Dock"] ||
        [owner isEqualToString:@"SystemUIServer"] ||
        [owner isEqualToString:@"Window Server"]) {
      continue;
    }
    NSDictionary *bounds = [w objectForKey:@"kCGWindowBounds"];
    
    NSRect winRect = NSMakeRect([[bounds objectForKey:@"X"] floatValue], [[bounds objectForKey:@"Y"] floatValue], [[bounds objectForKey:@"Width"] floatValue], [[bounds objectForKey:@"Height"] floatValue]);

    if (!shouldHideDock) {
      shouldHideDock = [self shouldHideDockForWindowRect:winRect];      
    }
    
#if 0
    long pid = [[w objectForKey:@"kCGWindowOwnerPID"] longValue];
    //TODO: If top-most window on screen takes full (visible) screen (without dock),
    //hide dock, and resize it to fill the whole screen.
    if (!shouldFillScreen && pid == currentAppPID) {
      NSLog(@"HAVE: (%f, %f | %f, %f)", winRect.origin.x, winRect.origin.y, lastVisibleFrame.origin.x, lastVisibleFrame.origin.y);
      winRect.origin.y += topMenuHeight;
      shouldFillScreen = NSEqualRects(winRect, lastVisibleFrame);
      NSLog(@"Should fill screen: %d", shouldFillScreen);
    }
#endif
    if (shouldHideDock) {
      break;
    }
  }
  CFRelease(windows);
  
  if ([self isDockHidden] == shouldHideDock) {
    return;
  }
  
  NSString *msg;
  if (shouldHideDock) {
    msg = @"true";    
  } else {
    msg = @"false";
  }
  
  NSString *script = [NSString stringWithFormat:@"tell application \"System Events\" to set the autohide of the dock preferences to %@", msg];
  NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
  [appleScript executeAndReturnError:nil];
  [appleScript release];
}

- (void)resizeFrontMostWindow {
NSString *script =
@"tell application \"System Events\""
 "set frontApp to name of first application process whose frontmost is true"
 "end tell"
 "tell application frontApp"
 "set bounds of window 1 to {0, 0, screenWidth, screenHeight}"
 "end tell";
  NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
  [appleScript executeAndReturnError:nil];
  [appleScript release];  
}

@end
