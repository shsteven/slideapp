//
//  MvrSlide.h
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MuiKit/MuiKit.h>

#import "Network+Storage/MvrProtocol.h" // for kMvrIndeterminateProgress

@interface MvrSlide : L0DraggableView {
	UIView* contentView;
	
	UILabel* titleLabel;
	UIImageView* imageView;
	UIButton* actionButton;
	UIImageView* highlightView;
	UIImageView* backdropView;
	UIActivityIndicatorView* spinner;
	UIProgressView* progressBar;
	
	id actionButtonTarget;
	SEL actionButtonSelector;
	
	BOOL editing;
	BOOL highlighted;
	BOOL transferring;
	CGFloat progress;
}

@property(retain) IBOutlet UIView* contentView;
@property(assign) IBOutlet UILabel* titleLabel;
@property(assign) IBOutlet UIImageView* imageView;
@property(assign) IBOutlet UIImageView* backdropView;
@property(assign) IBOutlet UIButton* actionButton;

@property(assign) IBOutlet UIActivityIndicatorView* spinner;
@property(assign) IBOutlet UIProgressView* progressBar;

@property(retain) IBOutlet UIImageView* highlightView;

- (void) setActionButtonTarget:(id) target selector:(SEL) action;

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;
@property(getter=isEditing) BOOL editing;

- (void) setHighlighted:(BOOL) highlighted animated:(BOOL) animated animationDuration:(NSTimeInterval) duration;
@property(getter=isHighlighted) BOOL highlighted;

- (IBAction) performDelete;

@property(getter=isTransferring) BOOL transferring;
@property(assign) CGFloat progress;

@end
