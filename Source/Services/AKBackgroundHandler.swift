//
//  AKBackgroundHandler.swift
//  AKPlayer
//
//  Created by Bright Roots 2019 on 17/04/21.
//

import Foundation
// https://github.com/delannoyk/AudioPlayer

/// A `BackgroundTaskCreator` serves the purpose of creating background tasks.

protocol BackgroundTaskCreator: class {
    /// Marks the beginning of a new long-running background task.
    ///
    /// - Parameter handler: A handler to be called shortly before the app’s remaining background time reaches 0.
    ///     You should use this handler to clean up and mark the end of the background task. Failure to end the task
    ///     explicitly will result in the termination of the app. The handler is called synchronously on the main
    ///     thread, blocking the app’s suspension momentarily while the app is notified.
    /// - Returns: A unique identifier for the new background task. You must pass this value to the
    ///     `endBackgroundTask:` method to mark the end of this task. This method returns `UIBackgroundTaskInvalid`
    ///     if running in the background is not possible.
    func beginBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier

    /// Marks the end of a specific long-running background task.
    ///
    /// You must call this method to end a task that was started using the `beginBackgroundTask(expirationHandler:)`
    /// method. If you do not, the system may kill your app.
    ///
    /// This method can be safely called on a non-main thread.
    ///
    /// - Parameter identifier: An identifier returned by the `beginBackgroundTask(expirationHandler:)` method.
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskCreator {}

/// A `BackgroundHandler` handles background.
class BackgroundHandler: NSObject {

    /// The background task creator
    var backgroundTaskCreator: BackgroundTaskCreator = UIApplication.shared
    /// The backround task identifier if a background task started. Nil if not.
    private var taskIdentifier: UIBackgroundTaskIdentifier?

    /// The number of background request received. When this counter hits 0, the background task, if any, will be
    /// terminated.
    private var counter = 0

    /// Ends background task if any on deinitialization.
    deinit {
        endBackgroundTask()
    }

    /// Starts a background task if there isn't already one.
    ///
    /// - Returns: A boolean value indicating whether a background task was created or not.
    @discardableResult
    func beginBackgroundTask() -> Bool {
        counter += 1

        guard taskIdentifier == nil else {
            return false
        }

        taskIdentifier = backgroundTaskCreator.beginBackgroundTask { [weak self] in
            if let taskIdentifier = self?.taskIdentifier {
                self?.backgroundTaskCreator.endBackgroundTask(taskIdentifier)
            }
            self?.taskIdentifier = nil
        }
        return true
    }

    /// Ends the background task if there is one.
    ///
    /// - Returns: A boolean value indicating whether a background task was ended or not.
    @discardableResult
    func endBackgroundTask() -> Bool {
        guard let taskIdentifier = taskIdentifier else {
            return false
        }

        counter -= 1

        guard counter == 0 else {
            return false
        }

        if taskIdentifier != UIBackgroundTaskIdentifier.invalid {
            backgroundTaskCreator.endBackgroundTask(taskIdentifier)
        }
        self.taskIdentifier = nil
        return true
    }
}
