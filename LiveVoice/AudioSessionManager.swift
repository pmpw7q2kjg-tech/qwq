import Foundation
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    let audioEngine = AVAudioEngine()
    
    private init() {}
    
    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // .playAndRecord ile hem mikrofon hem hoparlör kullanımını açarız
        // .voiceChat modu donanımsal Echo Cancellation (Eko Engelleme) sağlar
        // .defaultToSpeaker ile sesin ahize yerine hoparlörden çıkmasını sağlarız
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func startEngine(bufferHandler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Buffer Yönetimi: 100ms (0.1s) gibi çok küçük parçalar (1024 frame ~ 23ms @ 44.1kHz veya 4096 frame ~ 90ms)
        // Böylece bekleme süresi hissi yok edilir. VoiceProcessingIO node otomatik takılır.
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, time in
            bufferHandler(buffer, time)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func stopEngine() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
    }
}
