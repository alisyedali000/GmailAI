//
//  SelfSizingTextEditor.swift
//  AIReply
//
//  A text editor whose height grows and shrinks with its content.
//

import SwiftUI
import UIKit

struct SelfSizingTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    var font: Font = .regular(size: 15.3)
    var minHeight: CGFloat = 44
    var maxHeight: CGFloat = 400

    @State private var contentHeight: CGFloat = 44

    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            ZStack(alignment: .topLeading) {
                RepresentableSelfSizingTextEditor(
                    text: $text,
                    contentHeight: $contentHeight,
                    font: font,
                    minHeight: minHeight,
                    maxHeight: maxHeight,
                    containerWidth: width
                )
                .frame(width: width, height: contentHeight)

                if text.isEmpty, !placeholder.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .font(font)
                        .padding(.top, 8)
                        .padding(.leading, 9)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(minHeight: contentHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3))
        )
    }
}

// MARK: - Wrapper view to enforce width for text wrapping

private final class TextEditorWrapper: UIView {
    let textView: UITextView = {
        let v = UITextView()
        v.font = UIFont.systemFont(ofSize: 15.3)
        v.backgroundColor = .clear
        v.isScrollEnabled = false
        v.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 8)
        v.textContainer.lineFragmentPadding = 0
        v.textContainer.widthTracksTextView = false
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width
        guard w > 0 else { return }
        textView.textContainer.size = CGSize(width: w, height: .greatestFiniteMagnitude)
        textView.frame = CGRect(x: 0, y: 0, width: w, height: bounds.height)
    }
}

// MARK: - UIViewRepresentable

private struct RepresentableSelfSizingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var contentHeight: CGFloat
    var font: Font
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var containerWidth: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, contentHeight: $contentHeight, minHeight: minHeight, maxHeight: maxHeight, containerWidth: containerWidth)
    }

    func makeUIView(context: Context) -> TextEditorWrapper {
        let wrapper = TextEditorWrapper()
        let view = wrapper.textView
        view.delegate = context.coordinator
        view.textContainer.size = CGSize(width: max(containerWidth, 1), height: .greatestFiniteMagnitude)
        return wrapper
    }

    func updateUIView(_ wrapper: TextEditorWrapper, context: Context) {
        let view = wrapper.textView
        if view.text != text {
            view.text = text
        }
        context.coordinator.containerWidth = containerWidth
        wrapper.setNeedsLayout()
        wrapper.layoutIfNeeded()
        updateHeight(wrapper)
    }

    private func updateHeight(_ wrapper: TextEditorWrapper) {
        let view = wrapper.textView
        let width = containerWidth > 0 ? containerWidth : wrapper.bounds.width
        guard width > 0 else { return }
        let size = view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = min(max(size.height, minHeight), maxHeight)
        if abs(contentHeight - height) > 1 {
            DispatchQueue.main.async {
                contentHeight = height
            }
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var textBinding: Binding<String>
        var contentHeightBinding: Binding<CGFloat>
        let minHeight: CGFloat
        let maxHeight: CGFloat
        var containerWidth: CGFloat

        init(text: Binding<String>, contentHeight: Binding<CGFloat>, minHeight: CGFloat, maxHeight: CGFloat, containerWidth: CGFloat) {
            self.textBinding = text
            self.contentHeightBinding = contentHeight
            self.minHeight = minHeight
            self.maxHeight = maxHeight
            self.containerWidth = containerWidth
        }

        func textViewDidChange(_ textView: UITextView) {
            textBinding.wrappedValue = textView.text ?? ""
            guard let wrapper = textView.superview as? TextEditorWrapper else { return }
            let width = containerWidth > 0 ? containerWidth : wrapper.bounds.width
            guard width > 0 else { return }
            let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            let height = min(max(size.height, minHeight), maxHeight)
            if abs(contentHeightBinding.wrappedValue - height) > 1 {
                DispatchQueue.main.async {
                    self.contentHeightBinding.wrappedValue = height
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "Hello, this is some sample text that will wrap to multiple lines."
        var body: some View {
            SelfSizingTextEditor(text: $text, placeholder: "Type here…")
                .padding()
        }
    }
    return PreviewWrapper()
}
