import Foundation
import Combine
import AVFoundation

class MainViewModel: ObservableObject {
    @Published var isListening = false
    @Published var sourceText = ""
    @Published var translatedText = ""
    
    private let audioSessionManager = AudioSessionManager.shared
    private let speechRecognizer = SpeechRecognizerManager()
    private let translationManager = TranslationManager()
    private let speechSynthesizer = SpeechSynthesizerManager()
    private let vadManager = VADManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // STT'den (İngilizce vb.) gelen anlık (partial) metinler
        speechRecognizer.$recognizedText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.sourceText = text
                // Çok küçük chunk'ları anında Translation'a yolla
                self?.translationManager.translateChunk(text)
            }
            .store(in: &cancellables)
        
        // TranslationManager'dan gelen anlık çeviri akışı
        translationManager.$translatedText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.translatedText = text
            }
            .store(in: &cancellables)
        
        // TranslationManager'da bir "cümle" tamamlandığında TTS'i tetikle
        translationManager.onSentenceTranslated = { [weak self] sentence in
            self?.speechSynthesizer.speak(text: sentence)
        }
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        do {
            try audioSessionManager.configureSession()
            
            try audioSessionManager.startEngine { [weak self] buffer, time in
                guard let self = self else { return }
                // VAD (Gürültü/İnsan sesi) Kontrolü
                if self.vadManager.isHumanVoice(buffer: buffer) {
                    self.speechRecognizer.appendAudioBuffer(buffer)
                }
            }
            
            try speechRecognizer.startRecognition(audioEngine: audioSessionManager.audioEngine) { partialText in
                // STT partial update handler (ViewModel binding'de zaten halledildi)
            }
            
            isListening = true
        } catch {
            print("Ses yakalama başlatılamadı: \(error)")
        }
    }
    
    private func stopListening() {
        audioSessionManager.stopEngine()
        speechRecognizer.stopRecognition()
        isListening = false
    }
}
