---
layout: post
title: "ios 安全区域适配和调试"
date: 2022-02-22 16:51
categories: ios css
tag: ios safe area css mobile
---

## 调试ios安全距离

- 第一步在xcode创建一个新的项目

<img src="/assets/images/xcode-create-new-project.jpg" alt="">

<img src="/assets/images/xcode-create-new-project-1.png" alt="">

- 创建一个无导航栏的webview app


<img src="/assets/images/ContentView.png" alt="">

修改 `ContentView.swift` 文件, 将下面的代码替换 `ContentView.swift` 文件中的代码

```swift
import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        Webview(url: URL(string: "http://localhost:3000")!).navigationBarTitle("",displayMode: .inline)
            .edgesIgnoringSafeArea(Edge.Set.all)
    }
}

struct Webview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: UIViewRepresentableContext<Webview>) -> WKWebView {
        let webview = WKWebView()

        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)

        return webview
    }

    func updateUIView(_ webview: WKWebView, context: UIViewRepresentableContext<Webview>) {
        let request = URLRequest(url: self.url, cachePolicy: .returnCacheDataElseLoad)
        webview.load(request)
    }
}

```
