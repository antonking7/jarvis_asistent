import AVFoundation

class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка настройки аудио сессии: \(error)")
        }
    }
    
    func speak(_ text: String) {
        print("SpeechSynthesizer: Начинаю озвучивание")
        
        // Проверяем и активируем аудио сессию
        if !audioSession.isOtherAudioPlaying {
            do {
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Ошибка активации аудио сессии: \(error)")
            }
        }
        
        // Останавливаем предыдущее озвучивание, если оно есть
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        print("SpeechSynthesizer: Останавливаю озвучивание")
        synthesizer.stopSpeaking(at: .immediate)
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка деактивации аудио сессии: \(error)")
        }
    }
    
    // Делегат для отслеживания состояния
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("SpeechSynthesizer: Озвучивание началось")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("SpeechSynthesizer: Озвучивание завершено")
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка деактивации аудио сессии: \(error)")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("SpeechSynthesizer: Озвучивание приостановлено")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("SpeechSynthesizer: Озвучивание отменено")
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Ошибка деактивации аудио сессии: \(error)")
        }
    }
} 