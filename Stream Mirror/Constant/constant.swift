//
//  constant.swift
//  SmartRemote
//
//  Created by Sumit zalavadiya on 10/03/26.
//

import Foundation
import SwiftUI

let AppId = 6761158672
let REVIEW_LINK = "https://apps.apple.com/app/id\(AppId)?action=write-review"
let APPURL = "https://apps.apple.com/app/id\(AppId)"
let PRIVACYPOLICY = "https://zynkio12.blogspot.com/2026/04/privacy-policy.html"
let TEARMS = "https://zynkio12.blogspot.com/2026/04/terms-conditions.html"
let EULA = "https://zynkio12.blogspot.com/2026/04/eula.html"

let hastageAPI = "https://d2is1ss4hhk4uk.cloudfront.net/videodownload_hashtag.json"
let weatherAPI = "https://api.openweathermap.org/data/2.5/forecast"
let translateAPI = "https://translate.googleapis.com/translate_a/single?"
let wallpaperAPI = "https://api-pexels.7seasol.in/api/images/by-category?category="

var iapLifetime = ""
var iapYearlyPlan = ""
var iapMonthlyPlan = ""
var isShowPremium = ""
var second_native = ""
var second_appopen = ""
var small_native = ""
var pro_close_inter = ""

var bannerId = ""
var nativeId = ""
var interstialId = ""
var rewardId = ""
var appopenId = ""
var addButtonColor = ""
var adsCount = 4
var adsPlus = 1
var smallNativeBannerId = ""
var NewsAPI = "https://api-story.7seasol.in/api/"

#if DEBUG
//Test URL
let getJSON : String = "https://7seasol-application.s3.amazonaws.com/admin_prod/pbz-grfgvat-arj.json"
#else
//Live URL
let getJSON : String = "https://7seasol-application.s3.amazonaws.com/admin_prod/pbz-ivrj-zveebe-ceb.json"
#endif

let prefixUrl = "https://api-livevideocall.7seasol.in/proxy?url="
let BearerToken = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJmZmNlOWE0MGFmNTU5MDM5N2JiYjZjMWIwMGZjOGUxYyIsIm5iZiI6MTc0NjU5Njk0MC41NDIsInN1YiI6IjY4MWFmNDRjYWNkYTE2YzMyNjg1MDhhYyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.p-W6BpCTbQXniMiNOYcKHbuOYjsLoBHy7BdcKvrkbiI"


public let ACCESS = "AKIA2FCATE7MLGSZBHML"
public let SECRET = "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"

var androidBannerUrl = "https://7seasol-application.s3.ap-south-1.amazonaws.com/Smart+View/TV%20Banner1.png"
