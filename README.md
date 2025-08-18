# PunFunPhoto - Universal iOS App 📱📱

아이폰과 아이패드에서 각각 최적화된 포토카드 제작 앱입니다!

## 📱 앱 소개

PunFunPhoto는 iOS 디바이스에 최적화된 포토카드 제작 앱입니다. 아이폰용 분기와 아이패드용 분기의 최적화된 기능들을 통합하여, 각 디바이스에 맞는 완벽한 사용자 경험을 제공합니다.

## ✨ 주요 기능

- 📸 **사진 선택 및 편집**: 갤러리에서 사진을 선택하고 편집
- 🎨 **텍스트 추가**: 다양한 폰트와 색상으로 텍스트 추가
- 🏷️ **스티커 라이브러리**: 다양한 스티커로 포토카드 꾸미기
- 💾 **프로젝트 저장**: 작업 중인 프로젝트를 저장하고 나중에 계속 작업
- 📤 **공유 기능**: 완성된 포토카드를 친구들과 공유
- 🎯 **디바이스별 최적화**: 아이폰과 아이패드에 각각 최적화된 UI

## 🛠️ 기술 스택

- **언어**: Swift
- **UI 프레임워크**: SwiftUI
- **최소 iOS 버전**: iOS 18.0+
- **지원 기기**: iPhone & iPad (iOS 18.0 이상)

## 📋 요구사항

- iOS 18.0 이상
- iPhone 또는 iPad 기기
- 사진 라이브러리 접근 권한

## 🚀 설치 방법

### 개발자용 설치
1. 이 저장소를 클론합니다:
   ```bash
   git clone https://github.com/purplestory/PunFunPhoto.git
   ```

2. Xcode에서 프로젝트를 엽니다:
   ```bash
   cd PunFunPhoto
   open PunFunPhoto.xcodeproj
   ```

3. 개발자 계정으로 서명하고 디바이스에 설치합니다.

### App Store 설치 (준비 중)
- App Store에서 "PunFunPhoto" 검색 후 설치

## 📱 사용법

1. **앱 실행**: iOS 디바이스에서 PunFunPhoto 앱을 실행합니다
2. **사진 선택**: "사진 선택" 버튼을 눌러 갤러리에서 사진을 선택합니다
3. **편집 시작**: 선택한 사진을 드래그하여 원하는 위치에 배치합니다
4. **텍스트 추가**: "텍스트" 버튼을 눌러 원하는 텍스트를 추가합니다
5. **스티커 추가**: "스티커" 버튼을 눌러 다양한 스티커를 추가합니다
6. **저장 및 공유**: 완성된 포토카드를 저장하고 친구들과 공유합니다

## 🎨 디바이스별 최적화

### iPhone 최적화 (아이폰용 분기에서 가져온 최적화)
- **컴팩트한 UI**: 작은 화면에 맞는 간격과 패딩
- **스케일 팩터**: 1.0x 기본값으로 최적화
- **메뉴 간격**: 24pt 메뉴 간격으로 효율적인 공간 활용
- **드롭다운 간격**: 46pt로 적당한 분리

### iPad 최적화 (아이패드용 분기에서 가져온 최적화)
- **넉넉한 UI**: 큰 화면에 맞는 여유로운 간격과 패딩
- **생산성 향상**: 더 큰 터치 영역과 명확한 시각적 분리
- **메뉴 간격**: 40pt 메뉴 간격으로 전문적인 레이아웃
- **드롭다운 간격**: 69pt로 넉넉한 분리

## 🔧 개발 정보

### 프로젝트 구조
```
PunFunPhoto/
├── Views/           # SwiftUI 뷰들
├── Models/          # 데이터 모델
├── Managers/        # 비즈니스 로직 관리자
├── Utils/           # 유틸리티 클래스
├── Extensions/      # Swift 확장
└── Assets.xcassets/ # 앱 리소스
```

### 주요 파일
- `ContentView.swift`: 메인 뷰
- `PhotoEditorView.swift`: 사진 편집 뷰
- `FloatingToolbarView.swift`: 반응형 툴바 (디바이스별 최적화)
- `AppState.swift`: 앱 상태 관리

### 디바이스별 최적화 코드
```swift
// 메뉴 간격 최적화
private var dynamicSpacing: CGFloat {
    if isMobile {
        return 24 // iPhone: 아이폰용 분기에서 최적화
    } else {
        return 40 // iPad: 아이패드용 분기에서 최적화
    }
}

// 드롭다운 메뉴 간격 최적화
private var dropdownSpacing: CGFloat {
    if isMobile {
        return 46 // iPhone: 아이폰용 분기에서 최적화
    } else {
        return 69 // iPad: 아이패드용 분기에서 최적화
    }
}

// 스케일 팩터 (아이폰용 분기에서 가져옴)
let scaleFactor: CGFloat = 1.0
```

## 🤝 기여하기

1. 이 저장소를 포크합니다
2. 새로운 기능 브랜치를 생성합니다 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋합니다 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 푸시합니다 (`git push origin feature/amazing-feature`)
5. Pull Request를 생성합니다

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 문의

- 이메일: support@punfunphoto.com
- GitHub Issues: [이슈 등록](https://github.com/purplestory/PunFunPhoto/issues)

## 🙏 감사의 말

이 앱을 사용해주시는 모든 사용자분들께 감사드립니다!

---

**PunFunPhoto Universal** - 아이폰과 아이패드에서 각각 최적화된 포토카드 제작 경험을 제공합니다! 📸✨
