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

#import "QAmortizationController.h"

const NSString* kDate = @"payment";
const NSString* kBalance = @"balance";
const NSString* kInterest = @"interest";
const NSString* kPrincipal = @"principal";
const NSString* kInterestPaid = @"iTotal";
const NSString* kPrincipalPaid = @"pTotal";


@implementation QAmortizationController

#pragma mark compoundingPeriodsForPeriodType
//------------------------------------------------------------------------------
- (NSDecimalNumber *) compoundingPeriodsForPeriodType: (QAmortizationCompoundPeriod_e)inCompoundingPeriod
{
	NSUInteger numPeriods;

	switch( inCompoundingPeriod )
	{
		case eAmortizationCompound_Daily:
			numPeriods = 365;
			break;

		case eAmortizationCompound_Monthly:
			numPeriods = 12;
			break;

		case eAmortizationCompound_SemiAnnually:
			numPeriods = 2;
			break;

		default:
			NSLog(@"Unknown compounding period type: %lu", inCompoundingPeriod);

		case eAmortizationCompound_Annually:
            numPeriods = 1;
			break;
	}

	return [NSDecimalNumber decimalNumberWithMantissa: numPeriods exponent: 0 isNegative: NO];
}

#pragma mark paymentPeriodsForPaymentType
//------------------------------------------------------------------------------
- (NSDecimalNumber *) paymentPeriodsForPaymentType: (QAmortizationPaymentPeriod_e)inPaymentPeriod
{
	NSUInteger numPayments;

	switch( inPaymentPeriod )
	{
		default:
			NSLog(@"Unknown payment period type: %lu", inPaymentPeriod);

		case eAmortizationPayment_Annually:
            numPayments = 1;
			break;

		case eAmortizationPayment_TwicePerYear:
			numPayments = 2;
			break;

		case eAmortizationPayment_Quarterly:
			numPayments = 4;
			break;

		case eAmortizationPayment_EveryOtherMonth:
			numPayments = 6;
			break;

		case eAmortizationPayment_Monthly:
			numPayments = 12;
			break;

		case eAmortizationPayment_TwicePerMonth:
			numPayments = 24;
			break;

		case eAmortizationPayment_EverOtherWeek:
			numPayments = 26;
			break;

		case eAmortizationPayment_Weekly:
			numPayments = 52;
			break;
	}

	return [NSDecimalNumber decimalNumberWithMantissa: numPayments exponent: 0 isNegative: NO];
}

#pragma mark numYearsInLoan
//------------------------------------------------------------------------------
- (NSDecimalNumber *) numYearsInLoan
{
	NSDecimalNumber* numYears;

	switch( self.durationType )
	{
		default:
			NSLog(@"Unknown loan duration type: %lu", self.durationType);

		case eAmortizationDuration_Years:
		{
			numYears = self.loanTerm;
			break;
		}

		case eAmortizationDuration_Months:
		{
			NSDecimalNumber* twelve = [NSDecimalNumber decimalNumberWithMantissa: 12 exponent: 0 isNegative: NO];
			numYears = [self.loanTerm decimalNumberByDividingBy: twelve];
			break;
		}

		case eAmortizationDuration_Weeks:
		{
			NSDecimalNumber* fiftytwo = [NSDecimalNumber decimalNumberWithMantissa: 52 exponent: 0 isNegative: NO];
			numYears = [self.loanTerm decimalNumberByDividingBy: fiftytwo];
			break;
		}

		case eAmortizationDuration_Payments:
		{
			NSDecimalNumber* paymentPeriods = [self paymentPeriodsForPaymentType: self.paymentPeriod];
			numYears = [self.loanTerm decimalNumberByDividingBy: paymentPeriods];
			break;
		}
	}

	return numYears;
}

#pragma mark effectiveInterestRate
//------------------------------------------------------------------------------
- (NSDecimalNumber *) effectiveInterestRate
{
	NSDecimalNumber* paymentPeriods = [self paymentPeriodsForPaymentType: self.paymentPeriod];
//    NSDecimalNumberHandler* exponentDecimal = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundPlain
//                                                                                                 scale:10
//                                                                                      raiseOnExactness:NO
//                                                                                       raiseOnOverflow:NO
//                                                                                      raiseOnUnderflow:NO
//                                                                                   raiseOnDivideByZero:NO];
	// Covert interest rate from percentage to decimal value
//	NSDecimalNumber* oneHundred = [NSDecimalNumber decimalNumberWithMantissa: 100 exponent: 0 isNegative: NO];
//	NSDecimalNumber* interestRate = [self.interestRate decimalNumberByDividingBy: oneHundred];
    NSDecimalNumber* interestRate = [self.interestRate decimalNumberByDividingBy: [NSDecimalNumber decimalNumberWithMantissa:100
                                                                                                                    exponent:0
                                                                                                                  isNegative:NO]];

	BOOL zeroPaymentPeriods = [paymentPeriods isEqualToNumber: @0];

#ifdef INTL_FR	// everwhere but france allows num periods to be zero?
	if( zeroPaymentPeriods )
	{
		paymentPeriods = [NSDecimalNumber one];
		zeroPaymentPeriods = NO;
	}
#endif

	NSDecimalNumber* exponent;

	if( self.isSimple )
	{
		NSDecimalNumber* compoundingPeriods = [self compoundingPeriodsForPeriodType: self.compoundingPeriod];

		if( zeroPaymentPeriods )
		{
			exponent = [NSDecimalNumber zero];	// can't calculate it
		}
		else
		{
			exponent = [compoundingPeriods decimalNumberByDividingBy: paymentPeriods];
		}
        
		interestRate = [interestRate decimalNumberByDividingBy: compoundingPeriods];

		interestRate = [[NSDecimalNumber one] decimalNumberByAdding: interestRate];

        // below is where interestRate is becoming 1
//        interestRate = [interestRate decimalNumberByRaisingToPower: [exponent unsignedIntValue]  withBehavior: exponentDecimal];
//        use of decimalNumberByRaisingToPower is inept for this application. Exponent is 'int'
//        work-around below
        double rate;
        rate = pow([interestRate doubleValue], [exponent doubleValue]);
        NSDecimalNumber* temp = [[NSDecimalNumber alloc] initWithDouble: rate];
        interestRate = temp;
	}
	else
	{
		interestRate = [[NSDecimalNumber one] decimalNumberByAdding: interestRate];
		if( zeroPaymentPeriods )
		{
			exponent = [NSDecimalNumber zero];	// can't calculate it
		}
		else
		{
			exponent = [[NSDecimalNumber one] decimalNumberByDividingBy: paymentPeriods];
		}
		interestRate = [interestRate decimalNumberByRaisingToPower: [exponent unsignedIntegerValue]];
	}
//    NSLog(@"interestRate: %@",interestRate);
	interestRate = [interestRate decimalNumberBySubtracting: [NSDecimalNumber one]];
    
	return interestRate;
}

#pragma mark updateCalculations
//------------------------------------------------------------------------------
- (void) updateCalculations
{
	self.ratePerPeriod = [self effectiveInterestRate];
	NSDecimalNumber* numPaymentsPerYear = [self paymentPeriodsForPaymentType: self.paymentPeriod];
	NSDecimalNumber* numYears = [self numYearsInLoan];

	// Need to round the # of payments up to next whole number!
	NSDecimalNumberHandler* roundUpBehavior = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode: NSRoundUp
																									 scale: 0
																						  raiseOnExactness: NO
																						   raiseOnOverflow: NO
																						  raiseOnUnderflow: NO
																					   raiseOnDivideByZero: NO];
	self.totalPayments = [numPaymentsPerYear decimalNumberByMultiplyingBy: numYears withBehavior: roundUpBehavior];

	// Calculation is based on the formula found at this site:
	// http://www.vertex42.com/ExcelArticles/amortization-calculation.html
	//
	//	payment = ((effectiveRate * openingBalance) * pow( 1 + effectiveRate, totalPayments )) / (pow( 1 + effectiveRate, totalPayments) - 1);

    // interestPercentage = (1+r)^n
	NSDecimalNumber* interestMultiplier = [[NSDecimalNumber one] decimalNumberByAdding: self.ratePerPeriod];

	NSDecimalNumber* interestPercentage = [interestMultiplier decimalNumberByRaisingToPower: self.totalPayments.unsignedIntegerValue];
    // openingInterest = P*r
	NSDecimalNumber* openingInterest = [self.ratePerPeriod decimalNumberByMultiplyingBy: self.openingBalance];

	NSDecimalNumber* numerator = [openingInterest decimalNumberByMultiplyingBy: interestPercentage];
    NSDecimalNumber* denominator = [interestPercentage decimalNumberBySubtracting: [NSDecimalNumber one]];

    if ([interestPercentage isEqualTo: [NSDecimalNumber one]])
        NSLog(@"WELL THAT DIDN'T WORK");
    if([denominator isEqualTo: [NSDecimalNumber zero]])
        NSLog(@"error: 'denominator' is zero!!!!");

  
    if ([interestPercentage isNotEqualTo: [NSDecimalNumber one]])
    self.monthlyPIPayment = [numerator decimalNumberByDividingBy:denominator];

	// calc total payment by adding in any additional escrow/principal adjustments

	self.totalMonthlyPayment = [self.monthlyPIPayment copy];

	if( [self.propertyTaxes isGreaterThan: [NSDecimalNumber zero]] )
		self.totalMonthlyPayment = [self.totalMonthlyPayment decimalNumberByAdding: self.propertyTaxes];

	if( [self.hazardInsurance isGreaterThan: [NSDecimalNumber zero]] )
		self.totalMonthlyPayment = [self.totalMonthlyPayment decimalNumberByAdding: self.hazardInsurance];

	if( [self.mortgageInsurance isGreaterThan: [NSDecimalNumber zero]] )
		self.totalMonthlyPayment = [self.totalMonthlyPayment decimalNumberByAdding: self.mortgageInsurance];

	if( [self.additionalPrincipal isGreaterThan: [NSDecimalNumber zero]] )
		self.totalMonthlyPayment = [self.totalMonthlyPayment decimalNumberByAdding: self.additionalPrincipal];
}

#pragma mark amortizationSchedule
//------------------------------------------------------------------------------
- (NSArray<NSDictionary *> *) amortizationSchedule
{
	NSUInteger numPayments = self.totalPayments.unsignedIntegerValue;

	NSMutableArray<NSDictionary *> *schedule = [NSMutableArray arrayWithCapacity: numPayments];

	NSDecimalNumber* interestPaid = [NSDecimalNumber zero];
	NSDecimalNumber* principalPaid = [NSDecimalNumber zero];

	NSDecimalNumber* balance = [self.openingBalance copy];

	NSDecimalNumber* oneHundrededth = [NSDecimalNumber decimalNumberWithMantissa: 1 exponent: -2 isNegative: NO];

	NSUInteger paymentNum = 0;

	while( [balance isGreaterThan: oneHundrededth] )
	{
		NSDecimalNumber* interestPayment = [balance decimalNumberByMultiplyingBy: self.ratePerPeriod];
		NSDecimalNumber* principalPayment = [self.monthlyPIPayment decimalNumberBySubtracting: interestPayment];

		if( [self.additionalPrincipal isGreaterThan: [NSDecimalNumber zero]] )
			principalPayment = [principalPayment decimalNumberByAdding: self.additionalPrincipal];

		if( [principalPayment isGreaterThan: balance] )
			principalPayment = [balance copy];

		balance = [balance decimalNumberBySubtracting: principalPayment];

		interestPaid = [interestPaid decimalNumberByAdding: interestPayment];
		principalPaid = [principalPaid decimalNumberByAdding: principalPayment];

		NSDictionary* tableRow = @{ kDate: @(++paymentNum),
									kInterest: [[self currencyFormatter] stringFromNumber: interestPayment],
									kPrincipal: [[self currencyFormatter] stringFromNumber: principalPayment],
									kInterestPaid: [[self currencyFormatter] stringFromNumber: interestPaid],
									kPrincipalPaid: [[self currencyFormatter] stringFromNumber: principalPaid],
									kBalance: [[self currencyFormatter] stringFromNumber: balance],
									};

		[schedule addObject: tableRow];
	}

	return schedule;
}

@end
