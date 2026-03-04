import Foundation
import os

private let logger = Logger(subsystem: "com.claude.MeetingReminder", category: "MediaController")

private typealias MRNowPlayingInfoCallback = @convention(c) (DispatchQueue, @escaping (CFDictionary) -> Void) -> Void
private typealias MRSendCommandCallback = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool

final class MediaController {
    private var didPauseMedia = false
    private let sendCommand: MRSendCommandCallback?
    private let getNowPlayingInfo: MRNowPlayingInfoCallback?

    init() {
        let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_NOW
        )
        if let handle {
            self.sendCommand = unsafeBitCast(
                dlsym(handle, "MRMediaRemoteSendCommand"),
                to: MRSendCommandCallback?.self
            )
            self.getNowPlayingInfo = unsafeBitCast(
                dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"),
                to: MRNowPlayingInfoCallback?.self
            )
        } else {
            logger.warning("Failed to load MediaRemote framework")
            self.sendCommand = nil
            self.getNowPlayingInfo = nil
        }
    }

    func pauseIfPlaying() {
        guard let getNowPlayingInfo, let sendCommand else { return }
        getNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self else { return }
            let dict = info as NSDictionary
            if let rate = dict["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double, rate > 0 {
                logger.info("Media is playing, pausing")
                _ = sendCommand(2, nil)
                self.didPauseMedia = true
            } else {
                self.didPauseMedia = false
            }
        }
    }

    func resumeIfNeeded() {
        guard didPauseMedia, let sendCommand else { return }
        logger.info("Resuming previously paused media")
        _ = sendCommand(0, nil)
        didPauseMedia = false
    }
}
