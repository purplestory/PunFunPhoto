import SwiftUI

/// 뷰의 프레임 정보를 전달하기 위한 PreferenceKey들을 모아둔 파일입니다.
enum ViewPreferenceKeys {
    /// 캔버스 프레임 정보를 전달하기 위한 PreferenceKey
    struct CanvasFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
    
    /// 포토박스 프레임 정보를 전달하기 위한 PreferenceKey
    struct PhotoBoxFrameKey: PreferenceKey {
        static var defaultValue: [Int: CGRect] = [:]
        
        static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
            value.merge(nextValue()) { current, _ in current }
        }
    }
    
    /// 탑로더 프레임 정보를 전달하기 위한 PreferenceKey
    struct TopLoaderFrameKey: PreferenceKey {
        static var defaultValue: [Int: CGRect] = [:]
        
        static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
            value.merge(nextValue()) { current, _ in current }
        }
    }
    
    /// 툴바 프레임 정보를 전달하기 위한 PreferenceKey
    struct ToolbarFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
    
    /// 루트 프레임 정보를 전달하기 위한 PreferenceKey
    struct RootFrameKey: PreferenceKey {
        static var defaultValue: CGRect = .zero
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
            value = nextValue()
        }
    }
} 