//
//  DetectManager.swift
//  SwiftUI_RectanglesDetectExample
//
//  Created by cano on 2023/12/31.
//
// https://itecnote.com/tecnote/ios-11-using-vision-framework-vndetectrectanglesrequest-to-do-object-detection-not-precisely/
//

import Foundation
import AVFoundation
import Observation
import UIKit
import Vision

@Observable
class DetectManager: NSObject {
    private let session = AVCaptureSession()
    
    var previewImage: UIImage?

    private let rectanglesDetectionRequest = VNDetectRectanglesRequest()

    override init() {
        super.init()
        self.setupCameraInput()
        self.setupVideoOutput()
    }
    
    func startCaptureSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopCaptureSession() {
        self.session.stopRunning()
    }
    
    // カメラ入力準備
    private func setupCameraInput() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        //session.sessionPreset = .photo
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    
    // カメラ出力準備
    private func setupVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // アウトプットの画像を縦向きに変更 90度回転 セッション追加の後に行う
        for connection in videoOutput.connections {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }
    
    // 矩形認識処理を行うメソッド
    private func performRectanglesDetection(on image: CIImage) -> [VNRectangleObservation] {
        let rectanglesDetectionHandler = VNImageRequestHandler(ciImage: image, options: [:])
        try? rectanglesDetectionHandler.perform([rectanglesDetectionRequest])
        
        return rectanglesDetectionRequest.results ?? []
    }
    
}

extension DetectManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // サンプルバッファから画像データを取得
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
    
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        //let correctedImage = ciImage.oriented(.right) // 回転と方向の補正
        
        let context = CIContext()
        // CIImageをCGImageに変換する
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        // CGImageからUIImageを作成
        let uiImage = UIImage(cgImage: cgImage)
        
        // 矩形認識処理を実行
        let rectanglesDetections = performRectanglesDetection(on: ciImage)
        
        // 顔を矩形で認識
        guard let image = self.drawRectangles(on: uiImage, with: rectanglesDetections) else { return }
        
        // 画像の更新をメインスレッドで行う
        DispatchQueue.main.async { [weak self] in
            // プロパティに画像を設定
            self?.previewImage = image
        }
    }
    
    func drawRectangles(on image: UIImage, with observations: [VNRectangleObservation]) -> UIImage? {
        if observations.count == 0 {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
        image.draw(at: CGPoint.zero)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        // 座標系の変換
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1, y: -1)

        let imageSize = image.size

        for observation in observations {
            let boundingBox = observation.boundingBox

            // 矩形の描画
            let rect = CGRect(x: boundingBox.origin.x * imageSize.width,
                              y: boundingBox.origin.y * imageSize.height,
                              width: boundingBox.size.width * imageSize.width,
                              height: boundingBox.size.height * imageSize.height)
            context.setStrokeColor(UIColor.red.cgColor)
            context.setLineWidth(2.0)
            context.addRect(rect)
            context.drawPath(using: .stroke)
        }

        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return drawnImage
    }
}
