//
//  BluetoothKit
//
//  Copyright (c) 2015 Rasmus Taulborg Hummelmose - https://github.com/rasmusth
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import SnapKit
import BluetoothKit
import CryptoSwift

internal class PeripheralViewController: UIViewController, AvailabilityViewController, BKPeripheralDelegate, LoggerDelegate, BKRemotePeerDelegate {
    var selectedRadioButtonTitle: String?

    // MARK: Properties

    internal var availabilityView = AvailabilityView()

    private let peripheral = BKPeripheral()
//    private var points:[(Float, Float)] = [];
    private var lines: [String] = []
    private var current_index = 0
    var timer: Timer?
    private let logTextView = UITextView()
    private lazy var sendDataBarButtonItem: UIBarButtonItem! = { UIBarButtonItem(title: "Send Data", style: UIBarButtonItem.Style.plain, target: self, action: #selector(PeripheralViewController.sendData)) }()

    // MARK: UIViewController Life Cycle

    internal override func viewDidLoad() {
        navigationItem.title = "Peripheral"
        view.backgroundColor = UIColor.white
        Logger.delegate = self
        applyAvailabilityView()
        logTextView.isEditable = false
        logTextView.alwaysBounceVertical = true
        view.addSubview(logTextView)
        applyConstraints()
        startPeripheral()
        sendDataBarButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = sendDataBarButtonItem

        //read file to get point of x and y, each line is :$BGINS,0.220000,-0.000038,-0.000030,0.004035,0.050559,2,2,END$, the third and fourth is x and y
        let path = Bundle.main.path(forResource: removeTxtSuffix(from: selectedRadioButtonTitle!), ofType: "txt")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path!) {
            do {
                let content = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
                let lines = content.components(separatedBy: "\n")
                for line in lines {
                    self.lines.append(line)
                }
            } catch {
                print("Error reading file")
            }
        } else {
            print("File not found")
        }

    }

    deinit {
        _ = try? peripheral.stop()
        stopBroadcasting()
    }
    
    private func removeTxtSuffix(from title: String) -> String {
        if title.hasSuffix(".txt") {
            return String(title.dropLast(4))
        }
        return title
    }

    // MARK: Functions

    private func applyConstraints() {
        logTextView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(availabilityView.snp.top)
        }
    }

    private func startPeripheral() {
        do {
            peripheral.delegate = self
            peripheral.addAvailabilityObserver(self)
            let dataServiceUUID = UUID(uuidString: "000000FF-0000-1000-8000-00805F9B34FB")!
            let dataServiceCharacteristicUUID = UUID(uuidString: "0000FFE1-0000-1000-8000-00805F9B34FB")!
            let localName = Bundle.main.infoDictionary!["CFBundleName"] as? String
            let configuration = BKPeripheralConfiguration(dataServiceUUID: dataServiceUUID, dataServiceCharacteristicUUID: dataServiceCharacteristicUUID, localName: localName)
            try peripheral.startWithConfiguration(configuration)
            startBroadcasting()
            Logger.log("Awaiting connections from remote centrals")
        } catch let error {
            print("Error starting: \(error)")
        }
    }

    private func refreshControls() {
        sendDataBarButtonItem.isEnabled = peripheral.connectedRemoteCentrals.count > 0
    }

    // MARK: Target Actions

    @objc private func sendData() {
        let numberOfBytesToSend: Int = Int(arc4random_uniform(950) + 50)
        let data = Data.dataWithNumberOfBytes(numberOfBytesToSend)
        Logger.log("Prepared \(numberOfBytesToSend) bytes with MD5 hash: \(data.md5().toHexString())")
        for remoteCentral in peripheral.connectedRemoteCentrals {
            Logger.log("Sending to \(remoteCentral)")
            peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
                guard error == nil else {
                    Logger.log("Failed sending to \(remoteCentral)")
                    return
                }
                Logger.log("Sent to \(remoteCentral)")
            }
        }
    }


    func startBroadcasting() {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(sendBroadData), userInfo: nil, repeats: true)
    }

    func stopBroadcasting() {
        timer?.invalidate()
        timer = nil
    }

    @objc func sendBroadData() {
        // let numberOfBytesToSend: Int = Int(arc4random_uniform(950) + 50)
        // let data = Data.dataWithNumberOfBytes(numberOfBytesToSend)
        //data's format is `$BGINS,时间戳,x坐标,y坐标,roll角度,pitch角度,开始测量标志位,数据存储和显示标志位,END$`
//        let current_timestamp = String(Int(Date().timeIntervalSince1970))
//        
//        let x = points[current_index].0 + Float(arc4random_uniform(20) + 1)
//        let y = points[current_index].1 + Float(arc4random_uniform(20) + 1)
//        let draw = current_index==(points.count-1) ? 2 : 1
//        let data = "$BGINS,\(current_timestamp),\(x),\(y),3.0,4.0,1,\(draw),END$".data(using: .utf8)!
//        
//        current_index = (current_index+1) % points.count
        if current_index < lines.count {
            let data = self.lines[current_index].data(using: .utf8)!
            
            let remoteCentrals = peripheral.connectedRemoteCentrals
            for remoteCentral in remoteCentrals {
                Logger.log("Sending broadcast to \(remoteCentral)")
                peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
                    guard error == nil else {
                        Logger.log("Failed sending broadcast to \(remoteCentral)")
                        return
                    }
                    Logger.log("Sent broadcast to \(remoteCentral)")
                }
            }
            current_index = current_index + 1
        }
    }

    // MARK: BKPeripheralDelegate

    internal func peripheral(_ peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral) {
        Logger.log("Remote central did connect: \(remoteCentral)")
        remoteCentral.delegate = self
        refreshControls()
        current_index = 0
    }

    internal func peripheral(_ peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral) {
        Logger.log("Remote central did disconnect: \(remoteCentral)")
        refreshControls()
    }

    // MARK: BKRemotePeerDelegate

    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data) {
        Logger.log("Received data of length: \(data.count) with hash: \(data.md5().toHexString())")
    }

    // MARK: LoggerDelegate

    internal func loggerDidLogString(_ string: String) {
        if logTextView.text.count > 0 {
            logTextView.text = logTextView.text + ("\n" + string)
        } else {
            logTextView.text = string
        }
        logTextView.scrollRangeToVisible(NSRange(location: logTextView.text.count - 1, length: 1))
    }

}
