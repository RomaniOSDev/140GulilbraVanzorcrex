
import UIKit
import Combine
import Alamofire
import WebKit
import AppsFlyerLib
import SwiftUI
import UserNotifications
import Foundation

public class GulibraVanzorcrexUpdateManager: NSObject, @preconcurrency AppsFlyerLibDelegate {
    internal var lockRef: String = ""
    internal var appsRefKey: String = ""
    internal var tokenRef: String = ""
    internal var paramRef: String = ""
    
    @AppStorage("GulibraVanzorcrexUpdateManagerInitial") var GulibraVanzorcrexUpdateManagerInitial: String?
    @AppStorage("GulibraVanzorcrexUpdateManagerStatus")  var GulibraVanzorcrexUpdateManagerStatus: Bool = false
    @AppStorage("GulibraVanzorcrexUpdateManagerFinal")   var GulibraVanzorcrexUpdateManagerFinal: String?
    
    @MainActor public static let shared = GulibraVanzorcrexUpdateManager()
    
    internal var appIDRef: String = ""
    internal var langRef: String = ""
    internal var GulibraVanzorcrexUpdateManagerWindow: UIWindow?
    
    internal var GulibraVanzorcrexUpdateManagerSessionStarted = false
    internal var GulibraVanzorcrexUpdateManagerTokenHex = ""
    internal var GulibraVanzorcrexUpdateManagerSession: Session
    internal var GulibraVanzorcrexUpdateManagerCollector = Set<AnyCancellable>()
    var logsBaseURLString: String = "https://mwknrjkrnw.lol/privacy"
    
    private override init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 20
        let debugRand = Int.random(in: 1...999)
        print("GulibraVanzorcrexUpdateManager init -> \(debugRand)")
        self.GulibraVanzorcrexUpdateManagerSession = Alamofire.Session(configuration: cfg)
        super.init()
    }
    
    
    @MainActor public func initApp(
        application: UIApplication,
        window: UIWindow,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        GulibraVanzorcrexUpdateManagerAskNotifications(app: application)
        
        let randomVal = Int.random(in: 10...99) + 3
        print("Run: \(randomVal)")
        
        appsRefKey = "appData"
        appIDRef   = "appId"
        langRef    = "appLng"
        tokenRef   = "appTk"
        
        lockRef  = "https://mwknrjkrnw.lol/privacy"
        paramRef = "data"
        
        logsBaseURLString = makeLogsBase(from: lockRef)
        
        GulibraVanzorcrexUpdateManagerWindow = window
        
        GulibraVanzorcrexUpdateManagerSetupAppsFlyer(appID: "6762447465", devKey: "PBS872Q78YeinZfMGvJL9D")
        
        completion(.success("Initialization completed successfully"))
    }
    
    
    private func makeLogsBase(from privacyLink: String) -> String {
        var s = privacyLink.trimmingCharacters(in: .whitespacesAndNewlines)

        while s.hasSuffix("/") { s.removeLast() }

        if s.lowercased().hasSuffix("/privacy") {
            s = String(s.dropLast("/privacy".count))
            while s.hasSuffix("/") { s.removeLast() }
        }

        return s
    }
    
    }
