//
//  ViewController.swift
//  JustMap
//
//  Created by Gleb Glushok on 16.06.2022.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var justMap: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var location: CLLocation?
    
    var coreLocation = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        justMap.delegate = self
        searchBar.delegate = self
        coreLocation.delegate = self
        
        coreLocation.requestWhenInUseAuthorization()
        coreLocation.requestLocation()
        coreLocation.desiredAccuracy = kCLLocationAccuracyBest
        coreLocation.startUpdatingLocation()
        
        searchBar.setSearchFieldBackgroundImage(UIImage(), for: .highlighted)
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
    }
    
    @IBAction func findLocation(_ sender: UIButton) {
        print("lat: - \(location?.coordinate.latitude ?? 0) - Long : \(location?.coordinate.longitude ?? 0)")
        
        let map = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location!.coordinate, span: map)
        
        justMap.setRegion(region, animated: true)
        justMap.showsUserLocation = true
        
        let alert = UIAlertController(title: "Your location", message: "Latitude: \(location?.coordinate.latitude ?? 0) - Longitude: \(location?.coordinate.longitude ?? 0) - Altitude: \(String(format: "%0.2f", location?.altitude ?? 0)) m", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error - \(error.localizedDescription)")
    }
}

extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        
        if let direction = searchBar.text {
            geocoder.geocodeAddressString(direction) { (places: [CLPlacemark]?, error: Error?) in
                
                guard let destionation = places?.first?.location else { return }
                
                if error == nil {
                    let place = places?.first
                    let annotation = MKPointAnnotation()
                    
                    annotation.coordinate = (place?.location?.coordinate)!
                    annotation.title = direction
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
                    
                    self.justMap.setRegion(region, animated: true)
                    self.justMap.addAnnotation(annotation)
                    self.justMap.selectAnnotation(annotation, animated: true)
                    
                    self.route(way: destionation.coordinate)
                } else {
                    print("Error - \(error?.localizedDescription)")
                }
            }
        }
    }
}

extension ViewController: MKMapViewDelegate {
    
    func route(way: CLLocationCoordinate2D) {
        guard let origin = coreLocation.location?.coordinate else { return }
        
        let originPlaceMark = MKPlacemark(coordinate: origin)
        let destinationPlaceMark = MKPlacemark(coordinate: way)
        
        let originItem = MKMapItem(placemark: originPlaceMark)
        let destinationItem = MKMapItem(placemark: destinationPlaceMark)
        
        let destinationQuery = MKDirections.Request()
        destinationQuery.source = originItem
        destinationQuery.destination = destinationItem
        
        destinationQuery.transportType = .automobile
        destinationQuery.requestsAlternateRoutes = true
        
        let address = MKDirections(request: destinationQuery)
        address.calculate { (respond: MKDirections.Response?, error: Error?) in
            
            guard let safeRespond = respond else {
                if let error = error {
                    print("Error occured: \(error.localizedDescription)")
                }
                return
            }
            
            let route = safeRespond.routes[0]
            
            let routeAnnotation = MKPointAnnotation()
            let middlePoint = route.polyline.points()[route.polyline.pointCount/2].coordinate
            
            routeAnnotation.coordinate = middlePoint
            routeAnnotation.title = "Distance"
            routeAnnotation.subtitle = "\(route.distance/1000) km"
            
            self.justMap.addAnnotation(routeAnnotation)
            
            self.justMap.addOverlay(route.polyline)
            self.justMap.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        
        renderer.strokeColor = .systemBlue
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.title == "Distance" {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            
            view.pinTintColor = UIColor.red
            view.animatesDrop = true
            view.canShowCallout = true
            
            view.isSelected = true
            
            return view
        } else {
            return nil
        }
    }
}
