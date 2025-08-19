//
//  Application.swift
//  sqlite-cloud-sync
//
//  Created by Nell on 8/19/25.
//

import CloudKit
import SwiftUI

@main
struct Application: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      TodoView()
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? =
      nil
  ) -> Bool {
    /// Synchronize on startup
    _ = CloudKitChangesetDataStorage.shared
    CloudKitChangesetNotification.initialize.request()

    /// For receive cloudKit push silence push notification
    UIApplication.shared.registerForRemoteNotifications()
    return true
  }

  func application(
    _: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (
      UIBackgroundFetchResult
    ) -> Void
  ) {
    /// Cloudkit push notification received
    if CKQueryNotification(
      fromRemoteNotificationDictionary: userInfo
    ) != nil {
      Logger.d("☁️ Cloudkit push received")
      CloudKitChangesetNotification.pull.request()
      completionHandler(.newData)
    } else {
      completionHandler(.noData)
    }
  }
}
