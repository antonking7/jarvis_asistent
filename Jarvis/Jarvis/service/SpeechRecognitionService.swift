import Foundation
import Speech

class SpeechRecognitionService: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    
    @Published var isRecording = false
    var onRecognizedText: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
        super.init()
        speechRecognizer?.delegate = self
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    func startRecording() throws {
        // Остановим предыдущую запись если она была
        if isRecording {
            stopRecording()
            return
        }
        
        // Настраиваем аудио сессию
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognitionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Настраиваем аудио движок
        inputNode = audioEngine.inputNode
        
        guard let inputNode = inputNode else {
            throw NSError(domain: "SpeechRecognitionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio engine has no input node"])
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.onRecognizedText?(result.bestTranscription.formattedString)
                }
            }
            if error != nil {
                DispatchQueue.main.async {
                    self?.stopRecording()
                    self?.onError?(error!)
                }
            }
        }
        
        // Настраиваем формат аудио и начинаем запись
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        // Удаляем tap перед остановкой
        if let inputNode = inputNode {
            inputNode.removeTap(onBus: 0)
        }
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Сбрасываем состояние
        recognitionRequest = nil
        recognitionTask = nil
        inputNode = nil
        
        // Деактивируем аудио сессию
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
} 