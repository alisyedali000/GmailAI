//
//  HTMLWebView.swift
//  AIReply
//

import SwiftUI
import WebKit

/// Renders HTML content in a WKWebView, Gmail-style (responsive, readable).
struct HTMLWebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.link, .phoneNumber]
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let color = UITraitCollection.current.userInterfaceStyle == .dark ? "#f5f5f5" : "#1c1c1e"
        let wrapped = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 15px;
                    line-height: 1.5;
                    color: \(color);
                    margin: 0;
                    padding: 0;
                    max-width: 100%;
                    word-wrap: break-word;
                }
                img { max-width: 100%; height: auto; }
                a { color: #007AFF; text-decoration: none; }
                blockquote {
                    border-left: 3px solid #ccc;
                    margin: 8px 0;
                    padding-left: 12px;
                    color: #666;
                }
                pre, code { font-family: monospace; white-space: pre-wrap; }
            </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(wrapped, baseURL: nil)
    }
}
