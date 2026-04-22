
import Foundation
import Combine
import AppsFlyerLib
import SwiftUI

    extension GulibraVanzorcrexUpdateManager {
    
        @MainActor public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
            let debugLocal = Int.random(in: 1...100)
            print("appsFl succes ->: \(debugLocal)")
            
            let rawData   = try! JSONSerialization.data(withJSONObject: conversionInfo, options: .fragmentsAllowed)
            let rawString = String(data: rawData, encoding: .utf8) ?? "{}"
            
            let finalJson = """
        {
            "\(appsRefKey)": \(rawString),
            "\(appIDRef)": "\(AppsFlyerLib.shared().getAppsFlyerUID() ?? "")",
            "\(langRef)": "\(Locale.current.languageCode ?? "")",
            "\(tokenRef)": "\(GulibraVanzorcrexUpdateManagerTokenHex)"
        }
        """
            
            let sanitizedJson = finalJson.replacingOccurrences(of: "#", with: "")
            
            sendLog(
                step: "LogStep1",
                message: "conversion success -> preparing for request",
                data: sanitizedJson
            )
            
            GulibraVanzorcrexUpdateManager.shared.GulibraVanzorcrexUpdateManagerPrivacyAndTermsReq(code: sanitizedJson) { result in
                switch result {
                case .success(let msg):
                    self.GulibraVanzorcrexUpdateManagerSendNotice(name: "RemMess", message: msg)
                case .failure:
                    self.GulibraVanzorcrexUpdateManagerSendNoticeError(name: "RemMess")
                }
            }
        }
        
    
    public func onConversionDataFail(_ error: any Error) {
        let dummyVal = Double.random(in: 0..<1)
        print("onConversionDataFail | Error: \(error.localizedDescription)")
        sendLog(
            step: "LogStep2",
            message: "onConversionDataFail -> Error: \(error.localizedDescription)"
        )
        GulibraVanzorcrexUpdateManagerSendNoticeError(name: "RemMess")
    }
    
    @objc func GulibraVanzorcrexUpdateManagerHandleActiveSession() {
        if !GulibraVanzorcrexUpdateManagerSessionStarted {
            let localValue = Int.random(in: 100...200)
            print("GulibraVanzorcrexUpdateManagerHandleActiveSession -> localValue = \(localValue)")
            
            AppsFlyerLib.shared().start()
            GulibraVanzorcrexUpdateManagerSessionStarted = true
        }
    }
    
    @MainActor public func GulibraVanzorcrexUpdateManagerSetupAppsFlyer(appID: String, devKey: String) {
        AppsFlyerLib.shared().appleAppID                   = appID
        AppsFlyerLib.shared().appsFlyerDevKey              = devKey
        AppsFlyerLib.shared().delegate                     = self
        AppsFlyerLib.shared().disableAdvertisingIdentifier = true
        
        let sumOfKeys = appID.count + devKey.count
        print("GulibraVanzorcrexUpdateManagerSetupAppsFlyer -> sumOfKeys: \(sumOfKeys)")
        
        let firstLaunchKey = "hasLaunchedBefore"
        let hasLaunched = UserDefaults.standard.bool(forKey: firstLaunchKey)
        if !hasLaunched {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
        }
    }
    
    
    public func GulibraVanzorcrexUpdateManagerAskNotifications(app: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { app.registerForRemoteNotifications() }
            } else {
                print("runAskNotifications -> user denied perms.")
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(GulibraVanzorcrexUpdateManagerHandleActiveSession),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    internal func GulibraVanzorcrexUpdateManagerSendNotice(name: String, message: String) {
        print("GulibraVanzorcrexUpdateManagerSendNotice -> \(message.count)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": message]
            )
        }
    }
    
    internal func GulibraVanzorcrexUpdateManagerSendNoticeError(name: String) {
        print("GulibraVanzorcrexUpdateManagerSendNoticeError -> \(name.count * 2)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": "Error occurred"]
            )
        }
    }
    
    public func GulibraVanzorcrexUpdateManagerParseAFSnippet() {
        let snippet = "{\"sxAF\":777}"
        if let data = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                print("GulibraVanzorcrexUpdateManagerParseAFSnippet ->\(obj)")
            } catch {
                print("runParseAFSnippet ->\(error)")
            }
        }
    }
    
    public func GulibraVanzorcrexUpdateManagerIsSessionInit() -> Bool {
        print("GulibraVanzorcrexUpdateManagerIsSessionInit -> \(GulibraVanzorcrexUpdateManagerSessionStarted)")
        return GulibraVanzorcrexUpdateManagerSessionStarted
    }
    
    public func GulibraVanzorcrexUpdateManagerPartialAFCheck(_ info: [AnyHashable: Any]) {
        print("GulibraVanzorcrexUpdateManagerPartialAFCheck ->\(info.count)")
    }
    
    public func GulibraVanzorcrexUpdateManagerAFSmallDebug() -> String {
        let randomVal = Int.random(in: 1000...9999)
        let code = "AFDBG-\(randomVal)"
        print("GulibraVanzorcrexUpdateManagerAFSmallDebug -> \(code)")
        return code
    }
    
    public func GulibraVanzorcrexUpdateManagerRegisterToken(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        GulibraVanzorcrexUpdateManagerTokenHex = tokenString
        
        let tokenLen = tokenString.count
        print("GulibraVanzorcrexUpdateManagerRegisterToken -> tokenLen = \(tokenLen)")
    }
    
    public func GulibraVanzorcrexUpdateManagerMergeStringSets(_ x: Set<String>, _ y: Set<String>) -> Set<String> {
        let merged = x.union(y)
        print("GulibraVanzorcrexUpdateManagerMergeStringSets -> \(merged)")
        return merged
    }
    
    
    public func GulibraVanzorcrexUpdateManagerMinimalRandCheck() {
        let val = Double.random(in: 0..<10)
        print("GulibraVanzorcrexUpdateManagerMinimalRandCheck -> \(val)")
    }
        
        func sendLog(
            step: String,
            userID: Any? = nil,
            message: String,
            data: Any? = nil
        ) {
            let timestamp = ISO8601DateFormatter().string(from: Date())

            var log: [String: Any] = [
                "step": step,
                "time": timestamp,
                "message": message
            ]

            if let userID = userID {
                log["userID"] = userID
            }

            if let data = data {
                log["data"] = data
            }

            guard let jsonData = try? JSONSerialization.data(withJSONObject: log),
                  let jsonString = String(data: jsonData, encoding: .utf8) else { return }

            let urlString = "\(logsBaseURLString)/logs?logData=\(jsonString)"

            guard let url = URL(string: urlString) else {
                return
            }

            URLSession.shared.dataTask(with: url).resume()
        }
        
    }
