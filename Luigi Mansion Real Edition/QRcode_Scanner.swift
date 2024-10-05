//
//  QRcode_Scanner.swift
//  Luigi Mansion Real Edition
//
//  Created by ryu on 2024/10/04.
//

import AVFoundation
import UIKit

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var isQRCodeDetected = false
    var qrCodeDetectedTime: Date?
    var qrCodeGoneTimer: Timer?
    var isSuctionMode = false // 吸い取りモードかどうかを管理
    
    var exterminatedCount = 0 // 退治数
    let maxExterminationCount = 5 // 退治できる最大数
    var gameTimer: Timer?
    var remainingTime = 180 // 制限時間3分（180秒）

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupSuctionButton()
        startGameTimer()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }

        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch { return }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }
    
    // 吸い取りモードに入るためのボタン
    func setupSuctionButton() {
        let suctionButton = UIButton(frame: CGRect(x: 50, y: 50, width: 200, height: 50))
        suctionButton.setTitle("吸い取り開始", for: .normal)
        suctionButton.backgroundColor = .blue
        suctionButton.addTarget(self, action: #selector(suctionButtonTapped), for: .touchUpInside)
        view.addSubview(suctionButton)
    }
    
    // 吸い取りモードに移行
    @objc func suctionButtonTapped() {
        if isQRCodeDetected && !isSuctionMode {
            isSuctionMode = true
            captureSession.stopRunning() // カメラのQRコード検出を一時停止
            print("吸い取りモードに移行しました！")
            
            // 吸い込みアニメーションや吸い取り処理をここに追加
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // 吸い込み完了後、退治数を1増やす
                self.exterminatedCount += 1
                print("退治完了！現在の退治数: \(self.exterminatedCount)")
                
                // 退治数がMAXかどうかを確認
                if self.exterminatedCount >= self.maxExterminationCount {
                    self.endGame(win: true)
                } else {
                    // QRコード読み込みモードに戻る
                    self.isSuctionMode = false
                    self.captureSession.startRunning()
                    print("QRコード読み込みモードに戻りました")
                }
            }
        }
    }
    
    // ゲーム終了処理
    func endGame(win: Bool) {
        captureSession.stopRunning()
        gameTimer?.invalidate()
        
        if win {
            print("全てのおばけを退治しました！ゲームクリア！")
        } else {
            print("制限時間切れ！ゲームオーバー！")
        }
        
        // ゲーム終了後の画面遷移や再スタートの処理を追加
    }

    // ゲーム開始から3分のタイマー
    func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.remainingTime -= 1
            print("残り時間: \(self.remainingTime)秒")
            
            if self.remainingTime <= 0 {
                self.endGame(win: false) // 時間切れ
            }
        }
    }
    
    // QRコード検出時の処理
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            if !isQRCodeDetected {
                isQRCodeDetected = true
                qrCodeDetectedTime = Date()
                print("QRコードが見つかりました: \(stringValue)")
                
                // タイマーをリセット
                qrCodeGoneTimer?.invalidate()
            }
        } else {
            // QRコードが見えなくなった場合
            if isQRCodeDetected && !isSuctionMode {
                if qrCodeGoneTimer == nil {
                    qrCodeGoneTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                        self?.resetToQRCodeScanningMode()
                    }
                }
            }
        }
    }
    
    // QRコード読み込みモードに戻る処理
    func resetToQRCodeScanningMode() {
        isQRCodeDetected = false
        qrCodeDetectedTime = nil
        print("QRコード読み込みモードに戻りました")
    }
}
