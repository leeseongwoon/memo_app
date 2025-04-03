# 메모 앱 (Memo App)

아기자기한 UI를 가진 Flutter 기반 메모 앱입니다. 메모를 폴더별로 관리하고, 색상 변경과 검색 기능을 제공합니다.

## 주요 기능

- 메모 생성, 수정, 삭제
- 폴더 생성 및 관리
- 메모 폴더 간 이동
- 메모 색상 변경
- 메모 검색
- 자동 저장

## 프로젝트 구조

### 모델

- **lib/models/memo.dart**: 메모 데이터 모델
  - 메모의 제목, 내용, 생성일자, 수정일자, 색상 및 폴더 ID 관리

- **lib/models/folder.dart**: 폴더 데이터 모델
  - 폴더 이름 및 생성일자 관리

### 데이터 관리

- **lib/database/database_helper.dart**: SQLite 데이터베이스 관리
  - 메모 및 폴더 데이터 CRUD 연산 처리
  - 테이블 생성 및 업그레이드 관리

### 상태 관리

- **lib/providers/memo_provider.dart**: 메모 상태 관리
  - 메모 생성, 수정, 삭제 및 조회 기능
  - 메모 색상 정보 및 폴더 간 이동 기능

- **lib/providers/folder_provider.dart**: 폴더 상태 관리
  - 폴더 생성, 수정, 삭제 및 조회 기능
  - 현재 선택된 폴더 정보 관리

### 화면 구성

- **lib/screens/memo_list_screen.dart**: 메모 목록 화면
  - 전체 또는 특정 폴더의 메모 표시
  - 메모 검색 기능
  - 폴더 드로어 제공

- **lib/screens/memo_detail_screen.dart**: 메모 상세 화면
  - 메모 입력 및 편집 인터페이스
  - 색상 변경 기능
  - 자동 저장 기능

### 위젯

- **lib/widgets/memo_card.dart**: 메모 카드 위젯
  - 메모 정보 표시
  - 폴더 태그 표시 (전체 목록에서만)

- **lib/widgets/folder_list.dart**: 폴더 목록 위젯
  - 폴더 목록 표시
  - 폴더 관리 기능 (추가, 수정, 삭제)

### 유틸리티

- **lib/utils/date_formatter.dart**: 날짜 포맷 유틸리티
  - 상대적 시간 표시 (오늘, 어제, n일 전 등)

## 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 개발 환경

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- SQLite 데이터베이스

## 사용된 주요 패키지

- sqflite: 로컬 데이터베이스 관리
- provider: 상태 관리
- intl: 국제화 및 날짜 포맷팅
- flutter_staggered_grid_view: 격자 레이아웃
- uuid: 고유 ID 생성
