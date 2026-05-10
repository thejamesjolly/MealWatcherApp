//
//  CLLocationManager.swift
//  Watch2Track
//
//  Created by Brycen Havens on 8/11/25.
//
/**
Setup:
        1. Add a Swift file named BGLocationManager.swift to the iPhone app target.
        2. Paste the code below into that file.
        3. For iPhone, remove this line if Xcode errors: import WatchKit
        4. In Signing & Capabilities, add Background Modes, then check Location updates.
        5. In Info.plist, add:
           - Privacy - Location When In Use Usage Description
           - UIBackgroundModes with item: location
        6. If the phone app must keep running after background/lock, also add:
           - Privacy - Location Always and When In Use Usage Description
           - Change requestWhenInUseAuthorization() to requestAlwaysAuthorization()
        7. Start it when motion/recording starts:
           BGLocationManager.shared.start()
        8. Stop it when motion/recording stops:
           BGLocationManager.shared.stop()

        Watch2Track usage:
        - MotionData.swift starts it in startMotionUpdates().
        - MotionData.swift stops it in stopRecording().
        - ExtendedViews.swift starts/stops it around cleanup work.
 */


import CoreLocation
import WatchKit

/// 100-line replacement for the old workout session.
/// The goal is **not** to obtain GPS data; it's simply to keep the
/// run-loop awake so motion sampling carry on.
final class BGLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {

    // MARK: - Singleton
    static let shared = BGLocationManager()
    private let manager = CLLocationManager()

    private override init() {
        super.init()
        manager.delegate = self
        //DLog("BGLocationManager - init")

        // -- Ultra-low-power settings -----------------------------
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers   // coarsest
        manager.distanceFilter  = 10_000                               // ignore moves
        manager.activityType    = .other                               // neutral hint
        manager.allowsBackgroundLocationUpdates = true                 // keeps CPU
        // showsBackgroundLocationIndicator = false  // default-off on watchOS
        // pause flag is unavailable on watchOS
    }

    // MARK: - Public API
    func start() {
        // One-time permission prompt, if user hasn't granted yet
        if manager.authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
        //DLog("BGLocationManager - start()")
        manager.startUpdatingLocation()        // holds the wake lock
    }

    func stop() {
        //DLog("BGLocationManager - stop()")
        manager.stopUpdatingLocation()
    }

    // MARK: - Delegates (intentionally no-op)
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) { /* ignored */
        //DLog("Location tick @ \(locations.last!.timestamp)")
    }

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("BGLocationManager -> \(error.localizedDescription)")
    }
}
