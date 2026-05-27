////
////  SpeechAnalyzerService.swift
////  Retrospective-Rulersalmon
////
////  Created by dlsundn on 5/27/26.
////
//
//import Foundation
//import Speech
//import AVFoundation
//
//final class SpeechAnalyzerService{
//    private let audioEngine = AVAudioEngine()
//    private let audioSession = AVAudioSession.sharedInstance() // 앱의 오디오 사용 환경을 관리하는 객체
//    
//    func startRecording() throws {
//        try configureAudioSession() //오디오세션 설정
//        
//        let inputNode = audioEngine.inputNode
//        
//    }
//    //configure the audio session for the app
//    
//    func stopRecording() th
//    
//    
//    private func configureAudioSession() throws {
//        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)// 오디오 세션의 용도를 설정
//        //measurement : 원본에 가깝게 입력 받음, .duckOthers : 다른 앱에서 음악이나 소리가 나오고 있으면 소리 줄여줌
//        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)//오디오 세션을 실제로 활성화하는 코드
//    }
//}
