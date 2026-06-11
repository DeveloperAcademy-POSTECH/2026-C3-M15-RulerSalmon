# SwiftUI

## 개요
SwiftUI는 Apple의 선언형 UI 프레임워크. 상태 변화에 따라 화면이 다시 계산되는 구조와 MVP 단계에서의 빠른 화면 조립 및 흐름 수정에 적합한 방식

## 이 프로젝트에서의 역할
- 온보딩, 메인 탭, 회고 채팅, 오늘의 회고 리포트까지 전체 화면 계층 구성
- `NavigationStack`, `TabView`, `sheet`, `alert` 같은 시스템 UI를 통한 주요 플로우 연결
- Preview를 활용한 컴포넌트 단위 검증 가능 구조

## 실제 사용 위치
- `Views/OnboardingTab`
- `Views/MainTab`
- `Views/TodayReportView`
- `Views/AnalysisTab`

## 이 프로젝트에서 중요하게 보는 포인트
- 컴포넌트 단위 분리
- View와 ViewModel 역할 분리
- 시스템 UI와 커스텀 UI의 균형
- Preview 기반 확인 가능성
