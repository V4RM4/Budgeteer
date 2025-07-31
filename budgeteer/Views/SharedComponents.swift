//
//  SharedComponents.swift
//  budgeteer
//
//  Created by Vaisakh Suresh on 2025-07-29.
//

import SwiftUI
import PhotosUI
import CoreLocation

// MARK: - Location Manager

// A location manager for requesting user's current location with authorization handling.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationString: String? = nil
    @Published var isLoading = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Requests location permission and current location.
    func requestLocation() {
        // Check authorization status first
        let status = locationManager.authorizationStatus
        print("Location authorization status: \(status.rawValue)")
        
        // Only check if location services are enabled after we have proper authorization
        switch status {
        case .notDetermined:
            print("Requesting location authorization")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // Directly request location - any location service issues will be handled in error callback
            print("Starting location request")
            isLoading = true
            locationManager.requestLocation()
        case .denied, .restricted:
            print("Location not authorized: \(status)")
        @unknown default:
            print("Unknown location authorization status: \(status)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let placemark = placemarks?.first {
                    var components: [String] = []
                    
                    if let name = placemark.name {
                        components.append(name)
                    }
                    if let locality = placemark.locality {
                        components.append(locality)
                    }
                    if let state = placemark.administrativeArea {
                        components.append(state)
                    }
                    
                    let locationString = components.joined(separator: ", ")
                    print("Location found: \(locationString)")
                    self?.locationString = locationString
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            print("Location failed: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization changed to: \(manager.authorizationStatus.rawValue)")
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Directly request location - any location service issues will be handled in error callback
            isLoading = true
            locationManager.requestLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Location access denied or restricted")
        case .notDetermined:
            print("Location authorization not determined")
        @unknown default:
            print("Unknown location authorization status")
        }
    }
}

// MARK: - Image Picker

/// A SwiftUI wrapper for UIImagePickerController to handle photo selection.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

/// A custom text field style with rounded corners and consistent styling.
struct CustomTextFieldStyle: TextFieldStyle {
    var hasTrailingButton: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.trailing, hasTrailingButton ? -40 : 0)
    }
}

// Other shared UI components can be added here in the future
