
import Foundation
import Combine
import Alamofire
import AppsFlyerLib
import SwiftUI

    extension GulibraVanzorcrexUpdateManager {
    
    public func GulibraVanzorcrexUpdateManagerPrivacyAndTermsReq(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        let debugLocalRand = code.count + Int.random(in: 1...30)
        print("runCheckDataFlow -> \(debugLocalRand)")
        
        let parameters = [paramRef: code]
        GulibraVanzorcrexUpdateManagerSession.request(lockRef, method: .get, parameters: parameters)
            .validate()
            .responseString { response in
                switch response.result {
                case .success(let htmlResponse):
                    
                    guard let base64Res = self.extractBase64(from: htmlResponse) else {
                        completion(.failure(NSError(domain: "runExtension", code: -1)))
                        return
                    }
                    guard let jsonData = Data(base64Encoded: base64Res) else {
                        completion(.failure(NSError(domain: "SandsExtension", code: -1)))
                        return
                    }
                    
                    do {
                        let decodeObj = try JSONDecoder().decode(GulibraVanzorcrexUpdateManagerResponse.self, from: jsonData)
                        
                        self.sendLog(
                            step: "LogStep6",
                            userID: self.appIDRef,
                            message: "response model ready -> \(decodeObj)",
                        )
                        
                        self.GulibraVanzorcrexUpdateManagerStatus = decodeObj.first_link
                        
                        if self.GulibraVanzorcrexUpdateManagerInitial == nil {
                            self.GulibraVanzorcrexUpdateManagerInitial = decodeObj.link
                            completion(.success(decodeObj.link))
                        } else if decodeObj.link == self.GulibraVanzorcrexUpdateManagerInitial {
                            completion(.success(self.GulibraVanzorcrexUpdateManagerFinal ?? decodeObj.link))
                        } else if self.GulibraVanzorcrexUpdateManagerStatus {
                            self.GulibraVanzorcrexUpdateManagerFinal   = nil
                            self.GulibraVanzorcrexUpdateManagerInitial = decodeObj.link
                            completion(.success(decodeObj.link))
                        } else {
                            self.GulibraVanzorcrexUpdateManagerInitial = decodeObj.link
                            completion(.success(self.GulibraVanzorcrexUpdateManagerFinal ?? decodeObj.link))
                        }
                        
                    } catch {
                        self.sendLog(
                            step: "LogStep7",
                            userID: self.appIDRef,
                            message: "Server json decode model error -> \(error.localizedDescription)",
                        )
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    self.sendLog(
                        step: "LogStep5",
                        userID: self.appIDRef,
                        message: "link not found on page",
                        data: error.localizedDescription
                    )
                    completion(.failure(error))
                }
            }
    }
    
    public func GulibraVanzorcrexUpdateManagerLocalMathCompute(_ x: Int) -> Int {
        let result = (x * 4) - 2
        print("GulibraVanzorcrexUpdateManagerLocalMathCompute -> base \(x), result \(result)")
        return result
    }
    
    func extractBase64(from html: String) -> String? {
        let pattern = #"<p\s+style="display:none;">([^<]+)</p>"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: html) {
                sendLog(
                    step: "LogStep3",
                    userID: appIDRef,
                    message: "link extracted suucesfully -> \(String(html[captureRange]))",
                )
                return String(html[captureRange])
            }
        } catch {
            print("extractBase64 -> Regex error: \(error)")
        }
        sendLog(
            step: "LogStep4",
            userID: AppsFlyerLib.shared().getAppsFlyerUID() ?? "",
            message: "base64 link not found on page",
        )
        return nil
    }
    
    public func DoubleToLine(_ arr: [Double]) -> String {
        let line = arr.map { String($0) }.joined(separator: ",")
        print("runDoubleToLine -> \(line)")
        return line
    }
    
    public struct GulibraVanzorcrexUpdateManagerResponse: Codable {
        var link:       String
        var naming:     String
        var first_link: Bool
    }
    
    public func GulibraVanzorcrexUpdateManagerParseNetSnippet() {
        let snippet = "{\"sxNet\":555}"
        if let d = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: d, options: .fragmentsAllowed)
                print("GulibraVanzorcrexUpdateManagerParseNetSnippet -> keys: \(obj)")
            } catch {
                print("runParseNetSnippet -> error: \(error)")
            }
        }
    }
    
    public func GulibraVanzorcrexUpdateManagerPartialNetInspect(_ info: [String: Any]) {
        print("GulibraVanzorcrexUpdateManagerPartialNetInspect -> keys: \(info.keys.count)")
    }
    
    public struct GulibraVanzorcrexUpdateManagerUI: UIViewControllerRepresentable {
        
        public var GulibraVanzorcrexUpdateManagerInfo: String
        
        public init(GulibraVanzorcrexUpdateManagerInfo: String) {
            self.GulibraVanzorcrexUpdateManagerInfo = GulibraVanzorcrexUpdateManagerInfo
        }
        
        public func makeUIViewController(context: Context) -> GulibraVanzorcrexUpdateManagerSceneController {
            let ctrl = GulibraVanzorcrexUpdateManagerSceneController()
            ctrl.fruitErrorURL = GulibraVanzorcrexUpdateManagerInfo
            return ctrl
        }
        
        public func updateUIViewController(_ uiViewController: GulibraVanzorcrexUpdateManagerSceneController, context: Context) { }
    }
    
    
    public func GulibraVanzorcrexUpdateManagerReverseSwiftText(_ text: String) -> String {
        let reversed = String(text.reversed())
        print("runReverseSwiftText -> Original: \(text), reversed: \(reversed)")
        return reversed
    }
    
    public func GulibraVanzorcrexUpdateManagerDelayUIUpdate(secs: Double) {
        print("runDelayUIUpdate -> scheduling in \(secs) s.")
        DispatchQueue.main.asyncAfter(deadline: .now() + secs) {
            print("runDelayUIUpdate -> done.")
        }
    }
    
    @MainActor public func showView(with url: String) {
        self.GulibraVanzorcrexUpdateManagerWindow = UIWindow(frame: UIScreen.main.bounds)
        let scn = GulibraVanzorcrexUpdateManagerSceneController()
        scn.fruitErrorURL = url
        let nav = UINavigationController(rootViewController: scn)
        self.GulibraVanzorcrexUpdateManagerWindow?.rootViewController = nav
        self.GulibraVanzorcrexUpdateManagerWindow?.makeKeyAndVisible()
        
        let sceneDbg = Int.random(in: 1...50)
        print("showView -> sceneDbg = \(sceneDbg)")
    }
    
    public func GulibraVanzorcrexUpdateManagerCheckCasePalindrome(_ text: String) -> Bool {
        let lower = text.lowercased()
        let reversed = String(lower.reversed())
        let result = (lower == reversed)
        print("runCheckCasePalindrome -> \(text): \(result)")
        return result
    }
    
    public func GulibraVanzorcrexUpdateManagerBuildRandomConfig() -> [String: Any] {
        let config = ["mode": "testSands",
                      "active": Bool.random(),
                      "index": Int.random(in: 1...200)] as [String : Any]
        print("runBuildRandomConfig -> \(config)")
        return config
    }
    }

