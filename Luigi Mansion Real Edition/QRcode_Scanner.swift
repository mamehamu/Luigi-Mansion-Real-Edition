//
//  QRcode_Scanner.swift
//  Luigi Mansion Real Edition
//
//  Created by ryu on 2024/10/04.
//

import AVFoundation
import UIKit


class QRcode_Scanner: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // セッションの初期化
        captureSession = AVCaptureSession()

        // カメラの取得
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("カメラが利用できません")
            return
        }

        // 入力の設定
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("カメラの設定に失敗しました")
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            print("カメラ入力を追加できません")
            return
        }

        // メタデータ出力の設定
        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]  // QRコードのみ検出
        } else {
            print("メタデータ出力を追加できません")
            return
        }

        // プレビューの設定
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // セッションの開始
        captureSession.startRunning()
    }

    // QRコードを検出した際に呼ばれるデリゲートメソッド
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))  // バイブレーション
            found(code: stringValue)
        }
    }

    func found(code: String) {
        print("QRコードが見つかりました: \(code)")
        captureSession.stopRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
