import Foundation
import Speech
import AVFoundation

class SpeechRecognizerManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var recognizedText: String = ""
    @Published var isRecording = false
    
    // CoreML tabanlı VAD veya gürültü filtresi eklentisi için placeholder.
    // iOS 15+ cihazlarda SFSpeechRecognizer kendi içinde Neural Engine destekli VAD yapar.
    private var vadActive = false 
    
    func startRecognition(audioEngine: AVAudioEngine, onPartialResult: @escaping (String) -> Void) throws {
        // Önceden kalan task varsa iptal et
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Cihaz üzerinde (on-device) STT. Buluta git-gel yapmadan sıfır gecikme (CoreML/Neural Engine optimizasyonu)
        recognitionRequest.requiresOnDeviceRecognition = true
        // Metin parçalarının (kısmi sonuçlar) anında gelmesi için
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                // Çok küçük parçalar (chunks) halinde TranslationManager'a göndermek için callback
                onPartialResult(self.recognizedText)
            }
            
            if error != nil || isFinal {
                self.audioEngineStopTap(inputNode: inputNode)
            }
        }
    }
    
    func appendAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // VAD mantığı eklenecekse: Sadece ses (voice) tespit edildiğinde buffer request'e eklenir.
        // Şimdilik VoiceProcessingIO (AudioSessionManager'daki .voiceChat) donanımsal olarak gürültüyü elediği için
        // doğrudan buffer'ı veriyoruz.
        recognitionRequest?.append(buffer)
    }
    
    func stopRecognition() {
        recognitionRequest?.endAudio()
        isRecording = false
    }
    
    private func audioEngineStopTap(inputNode: AVAudioNode) {
        inputNode.removeTap(onBus: 0)
        self.recognitionRequest = nil
        self.recognitionTask = nil
    }
}
