# MVVM

## 개요
MVVM은 View, ViewModel, Model의 책임을 나누는 구조. SwiftUI와의 높은 궁합과 UI 상태 및 비즈니스 로직 분리에 적합한 패턴

## 이 프로젝트에서의 역할
- View의 화면 렌더링과 사용자 이벤트 전달 담당
- ViewModel의 화면 상태, 네비게이션 상태, 저장 호출, 비동기 처리 흐름 담당
- Model의 사용자, 멘토, 리포트, 회고 세션 같은 도메인 데이터 표현

## 실제 사용 위치
- `ViewModels/OnboardingTab`
- `ViewModels/MainTab`
- `ViewModels/TodayReportView`
- `ViewModels/AnalysisTab`

## 이 프로젝트에서 중요하게 보는 포인트
- View는 가능한 한 표시 전용으로 유지
- ViewModel은 화면용 가공 데이터 제공
- 저장소와 모델 호출은 ViewModel 또는 Service 계층에서 처리
