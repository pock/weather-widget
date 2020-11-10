//
//  WMWeatherStore.h
//  Weather
//
//  Created by Pierluigi Galdi on 25/05/2019.
//  Copyright © 2019 Pierluigi Galdi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <CoreLocation/CoreLocation.h>

@interface WMWeatherData : NSObject
{
    float _chanceOfPrecipitation;
    unsigned long long _weatherDataType;
    NSDateComponents *_representedDate;
    unsigned long long _conditionCode;
    NSString *_conditionLocalizedString;
    NSURL *_imageLargeURL;
    NSURL *_imageSmallURL;
    NSDate *_creationDate;
    double _temperatureCelsius;
    double _temperatureLowCelsius;
    double _temperatureHighCelsius;
    NSColor *_temperatureLowColor;
    NSColor *_temperatureHighColor;
    NSDate *_sunriseDate;
    NSDate *_sunsetDate;
    NSString *_naturalLanguageStringCelsius;
    NSString *_naturalLanguageStringFahrenheit;
    struct CLLocationCoordinate2D _coordinate;
}

+ (BOOL)supportsSecureCoding;
+ (id)knownKeys;
+ (id)temperatureUnitsBasedOnLocale;
+ (id)temperatureStringBasedOnLocaleGivenCelsius:(double)arg1 fahrenheit:(double)arg2;
+ (double)temperatureBasedOnLocaleGivenCelsius:(double)arg1 fahrenheit:(double)arg2;
+ (double)temperatureInFahrenheitGivenCelsius:(double)arg1;
@property(copy) NSString *naturalLanguageStringFahrenheit; // @synthesize naturalLanguageStringFahrenheit=_naturalLanguageStringFahrenheit;
@property(copy) NSString *naturalLanguageStringCelsius; // @synthesize naturalLanguageStringCelsius=_naturalLanguageStringCelsius;
@property(copy) NSDate *sunsetDate; // @synthesize sunsetDate=_sunsetDate;
@property(copy) NSDate *sunriseDate; // @synthesize sunriseDate=_sunriseDate;
@property float chanceOfPrecipitation; // @synthesize chanceOfPrecipitation=_chanceOfPrecipitation;
@property(copy) NSColor *temperatureHighColor; // @synthesize temperatureHighColor=_temperatureHighColor;
@property(copy) NSColor *temperatureLowColor; // @synthesize temperatureLowColor=_temperatureLowColor;
@property double temperatureHighCelsius; // @synthesize temperatureHighCelsius=_temperatureHighCelsius;
@property double temperatureLowCelsius; // @synthesize temperatureLowCelsius=_temperatureLowCelsius;
@property double temperatureCelsius; // @synthesize temperatureCelsius=_temperatureCelsius;
@property(copy) NSDate *creationDate; // @synthesize creationDate=_creationDate;
@property(copy) NSURL *imageSmallURL; // @synthesize imageSmallURL=_imageSmallURL;
@property(copy) NSURL *imageLargeURL; // @synthesize imageLargeURL=_imageLargeURL;
@property(copy) NSString *conditionLocalizedString; // @synthesize conditionLocalizedString=_conditionLocalizedString;
@property unsigned long long conditionCode; // @synthesize conditionCode=_conditionCode;
@property struct CLLocationCoordinate2D coordinate; // @synthesize coordinate=_coordinate;
@property(copy) NSDateComponents *representedDate; // @synthesize representedDate=_representedDate;
@property unsigned long long weatherDataType; // @synthesize weatherDataType=_weatherDataType;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
@property(readonly, retain) NSString *temperatureStringHighLowBasedOnLocale;
- (id)naturalLanguageString:(BOOL)arg1;
@property(readonly, retain) NSString *temperatureStringHighBasedOnLocale;
@property(readonly, retain) NSString *temperatureStringLowBasedOnLocale;
@property(readonly, retain) NSString *temperatureStringBasedOnLocale;
@property(readonly) double temperatureHighBasedOnLocale;
@property(readonly) double temperatureLowBasedOnLocale;
@property(readonly) double temperatureBasedOnLocale;
@property(readonly) double temperatureHighFahrenheit;
@property(readonly) double temperatureLowFahrenheit;
@property(readonly) double temperatureFahrenheit;
- (id)init;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end

@interface WMWeatherStore : NSObject
+ (instancetype)sharedWeatherStore;
- (void)currentConditionsForCoordinate:(struct CLLocationCoordinate2D)arg1 result:(void (^)(WMWeatherData *))arg2;
@end
