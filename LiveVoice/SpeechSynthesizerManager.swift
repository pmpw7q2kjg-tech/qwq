import Foundation
import AVFoundation

class SpeechSynthesizerManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    
    // CoreML Optimizasyonu (Neural Voices): iOS 17 ile gelen yüksek kaliteli ve düşük gecikmeli sesler
    private let voice = AVSpeechSynthesisVoice(language: "tr-TR") // Türkçe seslendirme
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // Pipelining: Cümle gelir gelmez kuyruğa (queue) eklenir ve okumaya başlar
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        // Seslendirme motoruna gönder (Eğer şu an konuşuyorsa, kuyruğa alır)
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
