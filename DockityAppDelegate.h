//
//  DockityAppDelegate.h
//  Dockity
//
//  Created by Dmitry Chestnykh on 4/30/11.
//  Copyright 2011 Coding Robots. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DockityAppDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
  NSRect lastVisibleFrame;
  char lastDockPos;
}

@property (assign) IBOutlet NSWindow *window;
- (void)activateStatusMenu;
- (void)recalculate:(id)sender;
@end
