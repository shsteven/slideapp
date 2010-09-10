//
//  MvrSlide.m
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrSlide.h"

@interface MvrSlide ()

- (void) removeHighlightViewIfPossible;

- (void) stopProgress;
- (void) updateProgress;

- (void) showOrHideEditingUI:(BOOL) animated;

@end



@implementation MvrSlide


@synthesize contentView, titleLabel, imageView, highlightView, backdropView, highQualityMark;
@synthesize spinner, progressBar;

- (id) initWithFrame:(CGRect) frame;
{
    if (self = [super initWithFrame:frame]) {
        [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:[NSDictionary dictionary]];
		
		self.contentView.frame = self.bounds;
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.contentView];
		
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.editing = NO;
		self.highlighted = NO;
		
		self.maximumSlideDistances = CGSizeMake(350, 150);
		self.slideSpeedDampeningFactor = 0.6;
		
		self.isAccessibilityElement = YES;
		self.actionButton.isAccessibilityElement = YES;
		
		progress = kMvrIndeterminateProgress;
		
		self.pressAndHoldDelay = 0.7;
		
		self.highQualityMark.hidden = YES;
	}
	
    return self;
}

- (void) setAccessibilityLabel:(NSString *)label;
{
	[super setAccessibilityLabel:label];
	[self.actionButton setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"Actions for %@", @"Template for accessibility label of action button"), label]];
}

- (void) sizeToFit;
{
	CGRect frame = self.frame;
	frame.size = CGSizeMake(179, 179); // TODO variable size
	self.frame = frame;
	
	self.contentView.frame = self.bounds;
}

- (void) dealloc;
{
	self.contentView = nil;
	self.highlightView = nil;
	[super dealloc];
}

@synthesize actionButton;

- (void) setActionButtonTarget:(id) target selector:(SEL) action;
{
	actionButtonTarget = target;
	actionButtonSelector = action;
}

- (IBAction) performDelete;
{
	if (actionButtonTarget && actionButtonSelector)
		[actionButtonTarget performSelector:actionButtonSelector withObject:self];
}

- (void) setEditing:(BOOL) newEditing animated:(BOOL) animated;
{
	if (newEditing == editing)
		return;
	
	editing = newEditing;
	
	if (!self.transferring)
		[self showOrHideEditingUI:animated];
}

- (void) showOrHideEditingUI:(BOOL) animated;
{
	self.pressAndHoldDelay = editing? 0.1 : 0.7;
	L0Log(@"press and hold delay of %@ now %f", self, self.pressAndHoldDelay);

	if (editing) {
		
		actionButton.userInteractionEnabled = YES;
		contentView.userInteractionEnabled = YES;
		
		if (animated) {
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.4];
		}
		
		imageView.alpha = 0.4;
		actionButton.alpha = 1.0;
		
		if (animated)
			[UIView commitAnimations];
		
	} else {
		
		actionButton.userInteractionEnabled = NO;
		contentView.userInteractionEnabled = NO;
		
		if (animated) {
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.4];
		}
		
		imageView.alpha = 1.0;
		actionButton.alpha = 0.0;
		
		if (animated)
			[UIView commitAnimations];
		
	}
	
	self.isAccessibilityElement = !editing;
}

- (void) setHighlighted:(BOOL) h animated:(BOOL) animated animationDuration:(NSTimeInterval) duration;
{
	L0Log(@"%d, %d, %f", h, animated, duration);
	highlighted = h;
	if (h && !self.highlightView.superview) {
		L0Log(@"Readding highlight view to hierarchy");
		self.highlightView.alpha = 0;
		[self.contentView insertSubview:self.highlightView aboveSubview:self.backdropView];
	}
	
	[UIView beginAnimations:nil context:NULL];
	if (animated) {
		[UIView setAnimationDuration:duration];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(highlightAnimation:didEndByFinishing:context:)];
	} else
		[UIView setAnimationDuration:0.0];
	
	highlightView.alpha = h? 1.0 : 0.0;
	titleLabel.highlighted = h;
	
	[UIView commitAnimations];
	
	if (!animated)
		[self removeHighlightViewIfPossible];
}

- (void) highlightAnimation:(NSString*) ani didEndByFinishing:(BOOL) finished context:(void*) context;
{
	[self removeHighlightViewIfPossible];
}

- (void) removeHighlightViewIfPossible;
{
	if (!self.highlighted && self.highlightView.superview) {
		L0Log(@"Removing highlight view from hierarchy");
		[self.highlightView removeFromSuperview];
	}
}

@synthesize editing;
- (void) setEditing:(BOOL) e;
{
	[self setEditing:e animated:NO];
}

@synthesize highlighted;
- (void) setHighlighted:(BOOL) h;
{
	[self setHighlighted:h animated:NO animationDuration:0.0];
}

@synthesize transferring;
- (void) setTransferring:(BOOL) t;
{
	BOOL wasTransferring = transferring;
	transferring = t;
	
	if (t && !wasTransferring) {
		self.editing = NO;
		self.progressBar.alpha = 0.0;
		self.progressBar.hidden = NO;
		
		[UIView beginAnimations:nil context:NULL];
		
		self.titleLabel.alpha = 0.0;
		self.imageView.alpha = 0.0;
		self.spinner.alpha = 1.0;
		
		[UIView commitAnimations];
		
		[self.spinner startAnimating];
		[self updateProgress];
		
	} else {
		[self stopProgress];
		
		[UIView beginAnimations:nil context:NULL];
		
		self.titleLabel.alpha = 1.0;
		self.imageView.alpha = 1.0;
		self.progressBar.alpha = 0.0;
		self.spinner.alpha = 0.0;
		
		[UIView commitAnimations];
		
		[self showOrHideEditingUI:YES];
	}	
}

@synthesize progress;
- (void) setProgress:(CGFloat) p;
{
	progress = p;
	[self updateProgress];
}

- (void) updateProgress;
{
	L0Log(@"Progress update: %f", progress);
	
	if (self.transferring && (progress == kMvrIndeterminateProgress || progress == 0.0)) {
		[UIView beginAnimations:nil context:NULL];
		self.progressBar.alpha = 0.0;
		[UIView commitAnimations];
		
		[self.spinner startAnimating];
	} else {
		if (self.progressBar.alpha < 1.0) {
			[UIView beginAnimations:nil context:NULL];
			self.progressBar.alpha = 1.0;
			[UIView commitAnimations];
		}
		
		self.progressBar.progress = progress;
	}
}

- (void) stopProgress;
{
	[self.spinner stopAnimating];
}

@end
