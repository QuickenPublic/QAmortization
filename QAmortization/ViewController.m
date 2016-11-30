/*
 MIT License

 Copyright (c) 2016 Quicken, Inc.

 Created by Lane Roathe on 11/7/16

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "ViewController.h"

#import "QAmortizationController.h"

// The view implemenation details
@implementation ViewController
{
	// allocated controller
	QAmortizationController* _amortizationController;
}

#pragma mark - Private Instance Methods

//------------------------------------------------------------------------------
- (NSNumberFormatter *) currencyFormatter
{
	NSNumberFormatter *theFormatter = [[NSNumberFormatter alloc] init];
	[theFormatter setGeneratesDecimalNumbers: YES];

	[theFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];

	return theFormatter;
}

//------------------------------------------------------------------------------
// Returns YES if all the user entered data is valid for use in calculations
- (BOOL) dataIsValid
{
	if( [self.openingBalanceField doubleValue] < 1.0 )
		return NO;

	if( [self.interestRateField doubleValue] <= 0.0 )
		return NO;

	if( [self.lengthField integerValue] <= 0 )
		return NO;

	return YES;
}

//------------------------------------------------------------------------------
- (void) updateControllerData
{
	// Set Loan Details
	_amortizationController.openingBalance = [NSDecimalNumber decimalNumberWithString: self.openingBalanceField.stringValue];
	_amortizationController.interestRate = [NSDecimalNumber decimalNumberWithString: self.interestRateField.stringValue];
	_amortizationController.loanTerm = [NSDecimalNumber decimalNumberWithString: self.lengthField.stringValue];

	_amortizationController.durationType = (QAmortizationDurationType_e)self.lengthTypePopup.selectedTag;
	_amortizationController.paymentPeriod = (QAmortizationPaymentPeriod_e)self.paymentSchedulePopUp.selectedTag;
	_amortizationController.compoundingPeriod = (QAmortizationCompoundPeriod_e)self.compoundingPeriodPopup.selectedTag;

	// Set Optional Payment Details
	_amortizationController.propertyTaxes = [NSDecimalNumber decimalNumberWithString: self.propertyTaxesField.stringValue];
	_amortizationController.hazardInsurance = [NSDecimalNumber decimalNumberWithString: self.hazardInsuranceField.stringValue];
	_amortizationController.mortgageInsurance = [NSDecimalNumber decimalNumberWithString: self.mortgageInsuranceField.stringValue];
	_amortizationController.additionalPrincipal = [NSDecimalNumber decimalNumberWithString: self.additionalPrincipalField.stringValue];

	[_amortizationController updateCalculations];

	self.monthyPaymentField.stringValue = [_amortizationController.currencyFormatter stringFromNumber: _amortizationController.monthlyPIPayment];
	self.totalPaymentField.stringValue = [_amortizationController.currencyFormatter stringFromNumber: _amortizationController.totalMonthlyPayment];
}

//------------------------------------------------------------------------------
- (void ) updateAmortizationControllerTable
{
	[self.arrayController removeObjects: self.arrayController.arrangedObjects];

	NSArray* schedule = [_amortizationController amortizationSchedule];

	[self.arrayController addObjects: schedule];
	[self.arrayController setSelectedObjects: @[]];
}

//------------------------------------------------------------------------------
- (void) updateDisplay
{
	BOOL dataIsValid = [self dataIsValid];

	self.invalidDataView.hidden = dataIsValid;

	if( dataIsValid )
	{
		[self updateControllerData];
		[self updateAmortizationControllerTable];
	}
	else
	{
		self.monthyPaymentField.stringValue = @"";
		self.totalPaymentField.stringValue = @"";
	}
}


#pragma mark - Base Class Overrides

//------------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];

	// Set some default values
	self.openingBalanceField.stringValue = @"200000";
	self.lengthField.stringValue = @"30";
	self.interestRateField.stringValue = @"5";
	[self.paymentSchedulePopUp selectItemWithTitle: @"Monthly"];
	[self.compoundingPeriodPopup selectItemWithTitle: @"Monthly"];

	// Allocate our controller object
	// Data parameters are set in our updateControllerData logic
	_amortizationController = [[QAmortizationController alloc] init];
	_amortizationController.currencyFormatter = [self currencyFormatter];
	_amortizationController.isSimple = YES;

	[self updateDisplay];

	[self.window makeFirstResponder: self.openingBalanceField];
}

//------------------------------------------------------------------------------
- (void) setRepresentedObject: (id)representedObject
{
	[super setRepresentedObject: representedObject];

	// Update the view, if already loaded.
}


#pragma mark - IBAction Methods

//------------------------------------------------------------------------------
- (IBAction) lengthTypeChanged: (id) sender
{
	[self updateDisplay];
}

//------------------------------------------------------------------------------
- (IBAction) periodChanged: (id) sender
{
	[self updateDisplay];
}

//------------------------------------------------------------------------------
- (IBAction) scheduleChanged: (id) sender
{
	[self updateDisplay];
}

//------------------------------------------------------------------------------
- (IBAction) openingDateChanged: (id) sender
{
	[self updateDisplay];
}


#pragma mark - Delegate Methods

//------------------------------------------------------------------------------
// Any keyDown or paste which changes the contents causes this
- (void) controlTextDidChange: (NSNotification *)obj;
{
	[self updateDisplay];
}

@end
