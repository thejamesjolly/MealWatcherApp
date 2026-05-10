//
//  CLLocationManager.swift
//  Watch2Track
//
//  Created by Brycen Havens on 8/11/25.
//

import CoreLocation

/// Replacement for the old workout session.
/// The goal is **not** to obtain GPS data; it's simply to keep the
/// run-loop awake so motion sampling carry on.
final class BGLocationManagerPhone: NSObject, CLLocationManagerDelegate, ObservableObject {

    // MARK: - Singleton
    static let shared = BGLocationManagerPhone()
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
