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

## Git Branch Convention
기본 브랜치 운영은 `main`, `dev`, `issue`를 기준으로 한다.

- `main`
  - 배포/안정 브랜치로 사용한다.
  - 직접 작업하지 않는다.
  - `dev` 또는 `issue` 브랜치에서 PR로만 반영한다.
- `dev`
  - 기능 개발을 통합하는 기본 개발 브랜치다.
  - 일반적인 신규 작업은 `dev`에서 분기한다.
- `issue`
  - 버그 수정, 긴급 보완, 개별 이슈 대응용 브랜치다.
  - 이슈 단위 작업은 `issue`에서 분기하거나 `issue` 계열 브랜치로 관리한다.

### Branch Naming
- 기본 형식은 `feat/<work-name>/<dev-nickname>` 또는 `issue/<work-name>/<dev-nickname>`를 사용한다.
- 브랜치 이름은 소문자와 하이픈을 우선 사용한다.
- 예시: `feat/login-screen`, `issue/fix-empty-state`, `feat/profile-edit`

### Pull Request Rules
- PR 제목은 브랜치 성격을 앞에 붙인다.
- 형식 예시: `[dev] 로그인 화면 추가`, `[issue] 빈 상태 표시 수정`
- 본문에는 변경 요약, 핵심 파일, 테스트 결과를 간단히 적는다.
- PR은 가능한 한 작은 단위로 유지한다.
- `main`으로 바로 머지하지 않는다.

## Common Git Rules
- 커밋 메시지는 짧고 명확하게 작성한다.
- 가능하면 한 커밋에는 한 가지 의도만 담는다.
- `main`은 항상 안정 상태를 유지한다.
- 브랜치 이름, PR 제목, 커밋 메시지의 용어를 일관되게 맞춘다.
