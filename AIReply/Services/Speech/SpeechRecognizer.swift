//
//  SpeechRecognizer.swift
//  AIReply
//

import Foundation
import AVFoundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {

    @Published var isRecording = false

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer()
    private var silenceWorkItem: DispatchWorkItem?

    /// Starts or stops recording. When recording, recognized text chunks are delivered via `onText`.
    func toggleRecording(onText: @escaping (String) -> Void) {
        if isRecording {
            stop()
        } else {
            start(onText: onText)
        }
    }

    private func start(onText: @escaping (String) -> Void) {
        requestAuthorizationIfNeeded { [weak self] authorized in
            guard let self = self, authorized else { return }
            self.beginSession(onText: onText)
        }
    }

    private func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            completion(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status == .authorized)
                }
            }
        default:
            completion(false)
        }
    }

    private func beginSession(onText: @escaping (String) -> Void) {
        guard !audioEngine.isRunning else { return }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        guard let inputNode = audioEngine.inputNode as AVAudioInputNode? else { return }

        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                let text = result.bestTranscription.formattedString
                onText(text)
                self.scheduleSilenceTimer()
                if result.isFinal {
                    self.stop()
                }
            } else if error != nil {
                self.stop()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            stop()
        }
    }

    func stop() {
        silenceWorkItem?.cancel()
        silenceWorkItem = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Stops recording automatically if there is no new speech for `timeout` seconds.
    private func scheduleSilenceTimer(timeout: TimeInterval = 2.5) {
        silenceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.isRecording else { return }
            self.stop()
        }
        silenceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
    }
}

