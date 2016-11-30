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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, QAmortizationCompoundPeriod_e)
{
	// Only Monthly is currently supported!
	eAmortizationCompound_Daily = 1,
	eAmortizationCompound_Monthly,
	eAmortizationCompound_SemiAnnually,
	eAmortizationCompound_Annually,

	eAmortizationCompound_Count
};

typedef NS_ENUM(NSUInteger, QAmortizationPaymentPeriod_e)
{
	eAmortizationPayment_Annually = 1,
	eAmortizationPayment_TwicePerYear,
	eAmortizationPayment_Quarterly,
	eAmortizationPayment_EveryOtherMonth,
	eAmortizationPayment_Monthly,

	// Not currently Supported
	eAmortizationPayment_TwicePerMonth,
	eAmortizationPayment_EverOtherWeek,
	eAmortizationPayment_Weekly,

	eAmortizationPayment_Count
};


typedef NS_ENUM(NSUInteger, QAmortizationDurationType_e)
{
	eAmortizationDuration_Years = 1,
	eAmortizationDuration_Months,
	eAmortizationDuration_Weeks,
	eAmortizationDuration_Payments,

	eAmortizationDuration_Count
};

typedef NS_ENUM(NSUInteger, QLoanType_e)
{
	eLoanType_GenericLoan = 1,
	eLoanType_Mortgage,
	eLoanType_Auto,
	eLoanType_Student,

	eLoanType_Count
};

// Keys Used in Amortization Schedule dictionary

extern const NSString* kDate;
extern const NSString* kBalance;
extern const NSString* kInterest;
extern const NSString* kPrincipal;
extern const NSString* kInterestPaid;
extern const NSString* kPrincipalPaid;


#pragma mark -

@interface QAmortizationController : NSObject

#pragma mark - Loan Information

@property (nonatomic, strong) NSDecimalNumber* openingBalance;
@property (nonatomic, strong) NSDecimalNumber* interestRate;
@property (nonatomic, strong) NSDecimalNumber* loanTerm;

@property (nonatomic) QAmortizationCompoundPeriod_e compoundingPeriod;
@property (nonatomic) QAmortizationPaymentPeriod_e paymentPeriod;
@property (nonatomic) QAmortizationDurationType_e durationType;

@property (nonatomic) BOOL isSimple;	// whether or not the loan is a simple interest rate loan or not

#pragma mark - Optional Payment Details

@property (nonatomic, strong) NSDecimalNumber* propertyTaxes;
@property (nonatomic, strong) NSDecimalNumber* hazardInsurance;
@property (nonatomic, strong) NSDecimalNumber* mortgageInsurance;
@property (nonatomic, strong) NSDecimalNumber* additionalPrincipal;

#pragma mark - Calculated Values

@property (nonatomic, strong) NSDecimalNumber* ratePerPeriod;
@property (nonatomic, strong) NSDecimalNumber* totalPayments;
@property (nonatomic, strong) NSDecimalNumber* monthlyPIPayment;
@property (nonatomic, strong) NSDecimalNumber* totalMonthlyPayment;

#pragma mark - Output Control

@property (nonatomic, strong) NSNumberFormatter* currencyFormatter;


#pragma mark - Public Methods

- (NSDecimalNumber *) compoundingPeriodsForPeriodType: (QAmortizationCompoundPeriod_e)inCompoundingPeriod;

- (NSDecimalNumber *) paymentPeriodsForPaymentType: (QAmortizationPaymentPeriod_e)inPaymentPeriod;

- (NSDecimalNumber *) numYearsInLoan;

- (NSDecimalNumber *) effectiveInterestRate;

- (void) updateCalculations;

- (NSArray<NSDictionary *> *) amortizationSchedule;

@end
