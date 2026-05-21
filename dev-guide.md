# Dev Guide

## Naming Convention (Apple Style)
- Type names (`class`, `struct`, `enum`, `protocol`): `UpperCamelCase`
- Variables, constants, functions, properties, parameters: `lowerCamelCase`
- Enum cases: `lowerCamelCase`
- File names: match the main type in the file (for example, `HomeView.swift`, `HomeViewModel.swift`)
- Protocol names: noun/adjective focused, optionally with capability suffix when meaningful (for example, `RetrospectiveRepository`, `Loadable`)
- Avoid unclear abbreviations. Prefer explicit, readable names.
- Boolean names should read naturally: `isLoading`, `hasError`, `canSubmit`

## MVVM Structure
기본 앱 구조는 아래 레이어를 기준으로 분리한다.

- `Views/`
  - SwiftUI View 계층
  - 화면 렌더링과 사용자 입력 전달에 집중
  - 비즈니스 로직은 넣지 않음
- `ViewModels/`
  - 화면 상태(`@Published`)와 액션 처리
  - View에서 발생한 이벤트를 받아 UseCase/Service 호출
  - 필요 시 입력/출력 모델 매핑
- `Models/`
  - 도메인 모델, DTO, 공용 데이터 타입
- `Services/` (또는 `Repositories/`)
  - 네트워크, 로컬 저장소, 외부 의존성 처리
  - 테스트를 위해 프로토콜 기반 추상화 권장
- `Resources/`
  - Asset, Localizable, 설정 파일

## MVVM Working Rules
- View는 가능한 한 "상태 표시"에만 집중한다.
- ViewModel은 UI 독립적으로 테스트 가능해야 한다.
- 의존성 주입(초기화 주입)을 기본으로 사용한다.
- 공통 로직은 View가 아니라 ViewModel/Service 계층으로 이동한다.
- 단일 책임 원칙(SRP)을 우선한다.
