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

internal class RoleSelectionViewController: UIViewController {

    // MARK: Properties

    private let offset = CGFloat(20)
    private let buttonColor = Colors.darkBlue
    private let centralButton = UIButton(type: UIButton.ButtonType.custom)
    private let peripheralButton = UIButton(type: UIButton.ButtonType.custom)
    // 存储单选按钮
    var radioButtons: [UIButton] = []

    // MARK: UIViewController Life Cycle

    internal override func viewDidLoad() {

        // 获取resources文件夹中的txt文件数量
        let txtFiles = getTxtFiles()
        // 动态创建单选按钮
        for (index, file) in txtFiles.enumerated() {
            let radioButton = UIButton(type: .custom)
            configureRadioButton(radioButton, title: file)
            radioButton.tag = index
            radioButtons.append(radioButton)
            view.addSubview(radioButton)
        }
        // 设置单选按钮的布局
//        applyRadioButtonsConstraints()
        if radioButtons.count > 0 {
            radioButtons[0].isSelected = true
        }

        navigationItem.title = "Select Role"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.red]
        view.backgroundColor = UIColor.white
        centralButton.setTitle("Central", for: UIControl.State())
        peripheralButton.setTitle("Peripheral", for: UIControl.State())
        preparedButtons([ centralButton, peripheralButton ], andAddThemToView: view)
        applyConstraints()
        #if os(tvOS)
        peripheralButton.isEnabled = false
        #endif
    }
    
    private func configureRadioButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.setImage(UIImage(systemName: "circle.fill"), for: .selected)
        button.addTarget(self, action: #selector(radioButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func getTxtFiles() -> [String] {
        let fileManager = FileManager.default
        let resourcePath = Bundle.main.resourcePath ?? ""
        do {
            let files = try fileManager.contentsOfDirectory(atPath: resourcePath)
            return files.filter { $0.hasSuffix(".txt") }
        } catch {
            print("Error reading contents of resource directory: \(error)")
            return []
        }
    }
    
    @objc private func radioButtonTapped(_ sender: UIButton) {
        // 取消所有单选按钮的选中状态
        for button in radioButtons {
            button.isSelected = false
        }
        
        // 设置当前点击的按钮为选中状态
        sender.isSelected = true
    }

    // MARK: Functions

    private func preparedButtons(_ buttons: [UIButton], andAddThemToView view: UIView) {
        for button in buttons {
            button.setBackgroundImage(UIImage.imageWithColor(buttonColor), for: UIControl.State())
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
            #if os(iOS)
            button.addTarget(self, action: #selector(RoleSelectionViewController.buttonTapped(_:)), for: UIControl.Event.touchUpInside)
            #elseif os(tvOS)
            button.addTarget(self, action: #selector(RoleSelectionViewController.buttonTapped(_:)), for: UIControl.Event.primaryActionTriggered)
            #endif
            button.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(button)
        }
    }

    private func applyConstraints() {
//        centralButton.snp.makeConstraints { make in
//            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(offset)
//            make.leading.equalTo(view).offset(offset)
//            make.trailing.equalTo(view).offset(-offset)
//            make.height.equalTo(peripheralButton)
//        }
//        peripheralButton.snp.makeConstraints { make in
//            if radioButtons.count == 0 {
//                make.top.equalTo(centralButton.snp.bottom).offset(offset)
//            } else {
//                make.top.equalTo(radioButtons[radioButtons.count - 1].snp.bottom).offset(offset)
//            }
//            make.leading.trailing.equalTo(centralButton)
//            make.bottom.equalTo(view).offset(-offset)
//        }
        var constrains = [
            centralButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centralButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: offset),
            centralButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offset),
            centralButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -offset),
            centralButton.heightAnchor.constraint(equalTo: peripheralButton.heightAnchor)
        ]
        
        for (index, button) in radioButtons.enumerated() {
            constrains.append(
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor))
            constrains.append(
                button.topAnchor.constraint(equalTo: index == 0 ? centralButton.bottomAnchor : radioButtons[index - 1].bottomAnchor, constant: 20))
        }
        if radioButtons.count == 0 {
            constrains.append(peripheralButton.topAnchor.constraint(equalTo: centralButton.bottomAnchor, constant: offset))
        } else {
            constrains.append(peripheralButton.topAnchor.constraint(equalTo: radioButtons[radioButtons.count - 1].bottomAnchor, constant: offset))
        }
        constrains.append(peripheralButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offset))
        constrains.append(peripheralButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -offset))
        constrains.append(peripheralButton.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constrains.append(peripheralButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -offset))
        
        NSLayoutConstraint.activate(constrains)
    }

    // MARK: Target Actions

    @objc private func buttonTapped(_ button: UIButton) {
        if button == centralButton {
            navigationController?.pushViewController(CentralViewController(), animated: true)
        } else if button == peripheralButton {
#if os(iOS)
            // 创建 PeripheralViewController 实例
            let peripheralVC = PeripheralViewController()
            var title: String?
            for button in radioButtons {
                if button.isSelected {
                    title = button.titleLabel?.text
                    break
                }
            }
            
            // 将选中的 radioButton 的标题传递给 PeripheralViewController
            peripheralVC.selectedRadioButtonTitle = title
            navigationController?.pushViewController(peripheralVC, animated: true)
#endif
        }
    }

}
