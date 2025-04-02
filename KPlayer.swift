if playbackEngine == "KSPlayer" {
    KSPlayerView(url: currentChannel.streamurl, title: currentChannel.tvgname, isLive: true)
        .frame(height: playerHeight)
        .id(reloadID)
        .onAppear {
            Task {
                if currentChannel.streamurl.contains("localhost") {
                    do {
                        let realURL = try await retriveRealVideoURLFromStalkerPortal()
                        currentChannel.streamurl = realURL ?? ""
                        reloadID = UUID() // ✅ 切换频道时也触发重新加载
                    } catch {
                        
                    }
                }
            }
            if cellularWarningEnabled{
                checkNetworkType() // ✅ 页面出现时检查网络类型
            }
        }
}
