import Foundation
import CoreLocation

struct BingMapsResponse: Codable {
    let authenticationResultCode: String
    let brandLogoUri: String
    let copyright: String
    let resourceSets: [ResourceSet]
    let statusCode: Int
    let statusDescription: String
    let traceId: String

    enum CodingKeys: String, CodingKey {
        case authenticationResultCode = "authenticationResultCode"
        case brandLogoUri = "brandLogoUri"
        case copyright = "copyright"
        case resourceSets = "resourceSets"
        case statusCode = "statusCode"
        case statusDescription = "statusDescription"
        case traceId = "traceId"
    }
}

struct ResourceSet: Codable {
    let estimatedTotal: Int
    let resources: [Resource]

    enum CodingKeys: String, CodingKey {
        case estimatedTotal = "estimatedTotal"
        case resources = "resources"
    }
}

struct Resource: Codable {
    let __type: String
    let bbox: [Double]
    let name: String
    let point: Point
    let address: Address
    let confidence: String
    let entityType: String
    let geocodePoints: [GeocodePoint]
    let matchCodes: [String]

    enum CodingKeys: String, CodingKey {
        case __type = "__type"
        case bbox = "bbox"
        case name = "name"
        case point = "point"
        case address = "address"
        case confidence = "confidence"
        case entityType = "entityType"
        case geocodePoints = "geocodePoints"
        case matchCodes = "matchCodes"
    }
}

struct Point: Codable {
    let type: String
    let coordinates: [Double]

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case coordinates = "coordinates"
    }
}

struct Address: Codable {
    let addressLine: String?
    let adminDistrict: String?
    let adminDistrict2: String?
    let countryRegion: String?
    let countryRegionIso2: String?
    let formattedAddress: String?
    let intersection: Intersection?
    let locality: String?
    let neighborhood: String?
    let postalCode: String?
    
    enum CodingKeys : String, CodingKey {
        case addressLine = "addressLine"
        case adminDistrict = "adminDistrict"
        case adminDistrict2 = "adminDistrict2"
        case countryRegionIso2 = "countryRegionIso2"
        case formattedAddress = "formattedAddress"
        case intersection = "intersection"
        case locality = "locality"
        case neighborhood = "neighborhood"
        case postalCode = "postalCode"
        case countryRegion = "countryRegion"
        
     }
}

struct Intersection : Codable {
    
     var baseStreet :String?
     var secondaryStreet1 :String?
     var intersectionType :String?
     var displayName :String?

     enum CodingKeys : String, CodingKey {
         case baseStreet="baseStreet", secondaryStreet1="secondaryStreet1", intersectionType="intersectionType", displayName="displayName"

     }
}

struct GeocodePoint : Codable {
    
     var type :String?
     var coordinates :[Double]?
     var calculationMethod :String?
     var usageTypes :[String]?

     enum CodingKeys : String, CodingKey {
         case type="type", coordinates="coordinates", calculationMethod="calculationMethod", usageTypes="usageTypes"

     }
}
struct Weather: Codable {
    let name: String
    let temp: String
    let temp_F: String
    let icon: String
    let description: String
    
    var temperature: String {
        let units: String = Preferences[.units]
        switch units {
        case "celsius":
            return "\(String(temp))°"
        default:
            return "\(String(temp_F))°"
        }
    }
}

struct WeatherData: Codable {
    struct Metadata: Codable {
        let error: String?
        let code: Int
    }
    let metadata: Metadata
    let weather: Weather
    
    private enum CodingKeys: String, CodingKey {
        case weather = "data", metadata
    }
}
struct WeatherResponse: Codable {
        let conditionsshort : Conditionsshort?
        let fcsthourly24short : Fcsthourly24short?
        let fcstdaily10short : Fcstdaily10short?
        let monthlyalmanac : Monthlyalmanac?
        let nowlinks : Nowlinks?
        let metadata : Metadata?

        enum CodingKeys: String, CodingKey {

            case conditionsshort = "conditionsshort"
            case fcsthourly24short = "fcsthourly24short"
            case fcstdaily10short = "fcstdaily10short"
            case monthlyalmanac = "monthlyalmanac"
            case nowlinks = "nowlinks"
            case metadata = "metadata"
        }

    }
struct Almanac_summaries : Codable {
    let avg_hi : Int?
    let avg_lo : Int?
    let record_hi : String?
    let record_hi_yr : String?
    let record_lo : String?
    let record_lo_yr : String?

    enum CodingKeys: String, CodingKey {

        case avg_hi = "avg_hi"
        case avg_lo = "avg_lo"
        case record_hi = "record_hi"
        case record_hi_yr = "record_hi_yr"
        case record_lo = "record_lo"
        case record_lo_yr = "record_lo_yr"
    }

}

struct Conditionsshort : Codable {
    let metadata : Metadata?
    let observation : Observation?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case observation = "observation"
    }
}

struct Fcstdaily10short : Codable {
    let metadata : Metadata?
    let forecasts : [Forecasts]?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case forecasts = "forecasts"
    }

}

struct Fcsthourly24short : Codable {
    let metadata : Metadata?
    let forecasts : [Forecasts]?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case forecasts = "forecasts"
    }

}
struct Forecasts : Codable {
    let classa : String?
    let dow : String?
    let fcst_valid : Int?
    let fcst_valid_local : String?
    let imperial : Imperial?
    let metric : Metric?
    let moonrise : String?
    let moonset : String?
    let moon_phase : String?
    let moon_phase_code : String?
    let num : Int?
    let sunrise : String?
    let sunset : String?
    let night : Night?
    let day : DayTime?
    let iconName: String?

    enum CodingKeys: String, CodingKey {

        case classa = "class"
        case dow = "dow"
        case fcst_valid = "fcst_valid"
        case fcst_valid_local = "fcst_valid_local"
        case imperial = "imperial"
        case metric = "metric"
        case moonrise = "moonrise"
        case moonset = "moonset"
        case moon_phase = "moon_phase"
        case moon_phase_code = "moon_phase_code"
        case num = "num"
        case sunrise = "sunrise"
        case sunset = "sunset"
        case night = "night"
        case day = "day"
        case iconName = "phrase_32char"
    }

}

struct Imperial : Codable {
    let wspd : Int?
    let maxTemp : Int?
    let minTemp : Int?
    let temp : Int?

    enum CodingKeys: String, CodingKey {

        case wspd = "wspd"
        case maxTemp = "max_temp"
        case minTemp = "min_temp"
        case temp
    }

}

struct Links : Codable {
    let ios : String?
    let mobile : String?
    let web : String?

    enum CodingKeys: String, CodingKey {

        case ios = "ios"
        case mobile = "mobile"
        case web = "web"
    }

}
struct Metadata : Codable {
    let language : String?
    let transaction_id : String?
    let version : String?
    let latitude : Double?
    let longitude : Double?
    let expire_time_gmt : Int?
    let status_code : Int?

    enum CodingKeys: String, CodingKey {

        case language = "language"
        case transaction_id = "transaction_id"
        case version = "version"
        case latitude = "latitude"
        case longitude = "longitude"
        case expire_time_gmt = "expire_time_gmt"
        case status_code = "status_code"
    }
}

struct Metric : Codable {
    let wspd : Int?
    let maxTemp : Int?
    let minTemp : Int?
    let temp : Int?

    enum CodingKeys: String, CodingKey {

        case wspd = "wspd"
        case maxTemp = "max_temp"
        case minTemp = "min_temp"
        case temp
    }
}
struct Monthlyalmanac : Codable {
    let metadata : Metadata?
    let almanac_summaries : [Almanac_summaries]?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case almanac_summaries = "almanac_summaries"
    }

}
struct Night : Codable {
    let alt_daypart_name : String?
    let daypart_name : String?
    let fcst_valid : Int?
    let fcst_valid_local : String?
    let icon_cd : Int?
    let icon_extd : Int?
    let long_daypart_name : String?
    let num : Int?
    let phrase_12char : String?
    let phrase_22char : String?
    let phrase_32char : String?
    let pop : Int?
    let precip_type : String?
    let rh : Int?
    let uv_desc : String?
    let uv_index : Int?
    let wdir : Int?
    let wdir_cardinal : String?
    let metric : Metric?
    let imperial : Imperial?

    enum CodingKeys: String, CodingKey {

        case alt_daypart_name = "alt_daypart_name"
        case daypart_name = "daypart_name"
        case fcst_valid = "fcst_valid"
        case fcst_valid_local = "fcst_valid_local"
        case icon_cd = "icon_cd"
        case icon_extd = "icon_extd"
        case long_daypart_name = "long_daypart_name"
        case num = "num"
        case phrase_12char = "phrase_12char"
        case phrase_22char = "phrase_22char"
        case phrase_32char = "phrase_32char"
        case pop = "pop"
        case precip_type = "precip_type"
        case rh = "rh"
        case uv_desc = "uv_desc"
        case uv_index = "uv_index"
        case wdir = "wdir"
        case wdir_cardinal = "wdir_cardinal"
        case metric = "metric"
        case imperial = "imperial"
    }
}
struct DayTime : Codable {
    let alt_daypart_name : String?
    let daypart_name : String?
    let fcst_valid : Int?
    let fcst_valid_local : String?
    let icon_cd : Int?
    let icon_extd : Int?
    let long_daypart_name : String?
    let num : Int?
    let phrase_12char : String?
    let phrase_22char : String?
    let phrase_32char : String?
    let pop : Int?
    let precip_type : String?
    let rh : Int?
    let uv_desc : String?
    let uv_index : Int?
    let wdir : Int?
    let wdir_cardinal : String?
    let metric : Metric?
    let imperial : Imperial?

    enum CodingKeys: String, CodingKey {

        case alt_daypart_name = "alt_daypart_name"
        case daypart_name = "daypart_name"
        case fcst_valid = "fcst_valid"
        case fcst_valid_local = "fcst_valid_local"
        case icon_cd = "icon_cd"
        case icon_extd = "icon_extd"
        case long_daypart_name = "long_daypart_name"
        case num = "num"
        case phrase_12char = "phrase_12char"
        case phrase_22char = "phrase_22char"
        case phrase_32char = "phrase_32char"
        case pop = "pop"
        case precip_type = "precip_type"
        case rh = "rh"
        case uv_desc = "uv_desc"
        case uv_index = "uv_index"
        case wdir = "wdir"
        case wdir_cardinal = "wdir_cardinal"
        case metric = "metric"
        case imperial = "imperial"
    }
}

struct Nowlinks : Codable {
    let metadata : Metadata?
    let links : Links?

    enum CodingKeys: String, CodingKey {

        case metadata = "metadata"
        case links = "links"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        metadata = try values.decodeIfPresent(Metadata.self, forKey: .metadata)
        links = try values.decodeIfPresent(Links.self, forKey: .links)
    }

}
struct Observation : Codable {
    let classa : String?
    let valid_time_gmt : Int?
    let imperial : Imperial?
    let metric : Metric?
    let obs_id : String?
    let obs_name : String?
    let pressure_desc : String?
    let pressure_tend : Int?
    let qualifier : String?
    let rh : Int?
    let uv_desc : String?
    let uv_index : Int?
    let wdir : Int?
    let wdir_cardinal : String?
    let wx_icon : Int?
    let wx_phrase : String?
    let icon_extd : Int?

    enum CodingKeys: String, CodingKey {

        case classa = "class"
        case valid_time_gmt = "valid_time_gmt"
        case imperial = "imperial"
        case metric = "metric"
        case obs_id = "obs_id"
        case obs_name = "obs_name"
        case pressure_desc = "pressure_desc"
        case pressure_tend = "pressure_tend"
        case qualifier = "qualifier"
        case rh = "rh"
        case uv_desc = "uv_desc"
        case uv_index = "uv_index"
        case wdir = "wdir"
        case wdir_cardinal = "wdir_cardinal"
        case wx_icon = "wx_icon"
        case wx_phrase = "wx_phrase"
        case icon_extd = ""
    }

}
public var name = "Montrèal"
public var DisplayIcon: Int?
private var Icon: String?

internal class WeatherService: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    override init() {
        super.init()
        locationManager.delegate = self
    }
    func currentConditions(result:@escaping  (WeatherData?) -> Void) {
        let Days_CodeName = ["Yesterday", "Today", "Tommorow"]
        print(Info)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        guard let latitude = locationManager.location?.coordinate.latitude,
              let longitude = locationManager.location?.coordinate.longitude else {
            print("Unable to get location")
            return
        }
        locationManager.stopUpdatingLocation()
        var description = " "
        var temp = "0"
        var temp_F = "0"
        let url_for_maps = URL(string:  "https://dev.virtualearth.net/REST/v1/Locations/\(latitude),\(longitude)?includeNeighborhood=1&include=ciso2&o=json&key=Amn3nivKYow4ej0mliZVLFonh7W6ZBOlQz8FVrH0AJbK6_wViio1P8mrDODAgs6U")!
        let url_for_weaather = URL(string: "https://api.weather.com/v1/geocode/\(latitude)/\(longitude)/aggregate.json?apiKey=e45ff1b7c7bda231216c7ab7c33509b8&products=conditionsshort,fcstdaily10short,fcsthourly24short,nowlinks")!
        let MapRequest = URLRequest(url: url_for_maps, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let GetMaps = URLSession.shared.dataTask(with: MapRequest) { Mapdata, response, error in
            guard let Mapdata = Mapdata else {
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
//           f
            let decoder = JSONDecoder()

            do {
                let bingMapsResponse = try decoder.decode(BingMapsResponse.self, from: Mapdata)
                let resourceSet = bingMapsResponse.resourceSets[0]
                let resource = resourceSet.resources[0]
                let address = resource.address
                let intersection = address.intersection
                let point = resource.point
                var addressLine = address.addressLine
                var adminDistrict = address.adminDistrict
                var adminDistrict2 = address.adminDistrict2
                var countryRegion = address.countryRegion
                var formattedAddress = address.formattedAddress
                var intersection_baseStreet = intersection?.baseStreet
                var intersection_secondaryStreet1 = intersection?.secondaryStreet1
                var intersection_intersectionType = intersection?.intersectionType
                var intersection_displayName = intersection?.displayName
                var city = address.locality
                var neighborhood = address.neighborhood
                var postalCode = address.postalCode
                var countryRegionIso2 = address.countryRegionIso2
                if Day == 0{
                    if Preferences[.Title] == "Address"{
                        name = addressLine!
                    }else if Preferences[.Title] == "Neighborhood"{
                            name = neighborhood!
                    } else {name = city!}
                    
                }
                let data = WeatherData(
                    metadata: .init(error: nil, code: -999),
                    weather: Weather(
                        name: name,
                        temp: temp,
                        temp_F: temp_F,
                        icon:Icon!,
                        description: description
                    )
                )
                result(data)
                return
            } catch {
                print(error.localizedDescription)
            }
        }
        
        let request2 = URLRequest(url: url_for_weaather, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let GetWeather = URLSession.shared.dataTask( with: request2) { Wdata, response, error in
            guard let Wdata = Wdata else {result(nil); return}
//            do {
//                let json = try JSONSerialization.jsonObject(with: Wdata, options: [])
//                print(json)
//            } catch {
//                print("Error: \(error.localizedDescription)")
//            }
            let decoder = JSONDecoder()
            let weather = try? decoder.decode(WeatherResponse.self, from: Wdata)
            let observation = weather?.conditionsshort?.observation
            let FutureForcast = weather?.fcstdaily10short?.forecasts?[Day]
            if !(Day == 0){
                description = ((FutureForcast?.day?.phrase_32char)!)
                let units: String = Preferences[.units]
                if Preferences[.show_description]{
                    switch units {
                    case "celsius":
                            if description.count > 19{
                                name = ((FutureForcast?.day?.daypart_name)! + " High: " + String(Int(Double(FutureForcast?.metric?.maxTemp ?? 0))) + "°" + ("  Low: " + String(Int(Double(FutureForcast?.metric?.minTemp ?? 0)))) + "°" )
                            }else{
                                name = ((FutureForcast?.day?.daypart_name)! + "  " + String(Int(Double(FutureForcast?.metric?.maxTemp ?? 0))) + "°")
                            }
                    default:
                        name = ((FutureForcast?.day?.daypart_name)! + "  " + String(Int(Double(FutureForcast?.imperial?.maxTemp ?? 0))) + "°")
                    }
                    if !(description.count > 19){
                        temp = ("Low: " + String(Int(Double(FutureForcast?.metric?.minTemp ?? 0))))
                        temp_F = ("Low: " + String(Int(Double(FutureForcast?.imperial?.minTemp ?? 0))))
                    }else{
                        temp = ""
                        temp_F = ""
                    }
                }else{
                    name = ((FutureForcast?.day?.daypart_name)!)
                    temp = ("High: " + String(Int(Double(FutureForcast?.metric?.maxTemp ?? 0))) + "°" + ("Low: " + String(Int(Double(FutureForcast?.metric?.minTemp ?? 0)))) + "°" )
                    temp_F = ("High: " + String(Int(Double(FutureForcast?.imperial?.maxTemp ?? 0))) + "°" + ("Low: " + String(Int(Double(FutureForcast?.imperial?.minTemp ?? 0)))) + "°" )
                }
                DisplayIcon = FutureForcast?.day?.icon_cd!

            }else{
                temp = String(Int(Double(observation?.metric?.temp ?? 0)))
                temp_F = String(Int(Double(observation?.imperial?.temp ?? 0)))
                description = (observation?.wx_phrase)!
                DisplayIcon = observation?.wx_icon!
            }
            print(String(DisplayIcon!))
            if Preferences[.IconStyle] == "Outlined"{
                Icon = " -" + String(DisplayIcon!)
            }else if Preferences[.IconStyle] == "Filled"{
                Icon = "2-" + String(DisplayIcon!)
            }else if Preferences[.IconStyle] == "Default"{
                if DisplayIcon == 011 || DisplayIcon == 012 || DisplayIcon == 013 || DisplayIcon == 014 || DisplayIcon == 016 || DisplayIcon == 019 || DisplayIcon == 020 || DisplayIcon == 021 || DisplayIcon == 022 || DisplayIcon == 026 || DisplayIcon == 027 || DisplayIcon == 028 || DisplayIcon == 029 || DisplayIcon == 030 || DisplayIcon == 031 || DisplayIcon == 032 || DisplayIcon == 036 || DisplayIcon == 037 || DisplayIcon == 038 || DisplayIcon == 039 || DisplayIcon == 040 || DisplayIcon == 047{
                    Icon = "0" + String(DisplayIcon!)
                }else{
                    Icon = " -" + String(DisplayIcon!)
                }
            }else{Icon = String(DisplayIcon!)}
            GetMaps.resume()
        }
        GetWeather.resume()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("[WeatherService]: Location updated to \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[WeatherService]: Location update failed with error \(error.localizedDescription)")
    }
}

