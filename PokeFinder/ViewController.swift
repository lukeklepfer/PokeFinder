//
//  ViewController.swift
//  PokeFinder
//
//  Created by Luke Klepfer on 11/21/16.
//  Copyright © 2016 Luke. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let location = CLLocationManager()
    var mapHasCentered = false
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        geoFireRef = FIRDatabase.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locaAuthStatus()
    }
    
    @IBAction func spotRandPokemon(_ sender: Any) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let rand = arc4random_uniform(151) + 1 //pokemon image names and key
        createSighting(loc: loc, pokeID: Int(rand))
    }
    
    func createSighting(loc:CLLocation, pokeID: Int){
        geoFire.setLocation(loc, forKey: "\(pokeID)")
    }
    
    func showSightings(loc: CLLocation){
        let circleQuery = geoFire.query(at: loc, withRadius: 2.5)//kilometers
        
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            //called for every pokemon in the area and when one is added to the map
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNum: Int(key)!)
                self.mapView.addAnnotation(anno)
            }
            
        })
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //called whenever mapView.addAnnotation is called
        
        var annoView: MKAnnotationView?
        let annoID = "Pokemon"
        
        if annotation.isKind(of: MKUserLocation.self){
            annoView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annoView?.image = UIImage(named: "ash")
        } else if let dequedAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoID){
            annoView = dequedAnno
            annoView?.annotation = annotation
            //this reuses annotations if needed
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoID)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annoView = av
            //default cell
        }
        if let annoView = annoView, let anno = annotation as? PokeAnnotation {
            //customize cell
            annoView.canShowCallout = true //requires a title in view layer or it will crash
            annoView.image = UIImage(named: "\(anno.pokemonNumber)")
            let button = UIButton()
            button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button.setImage(UIImage(named: "map"), for: .normal)
            annoView.rightCalloutAccessoryView = button
        }
    
        return annoView
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightings(loc: loc)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //apple maps
        
        if let anno = view.annotation as? PokeAnnotation {
            var place: MKPlacemark!
            
            if #available(iOS 10.0, *) {
                place = MKPlacemark(coordinate: anno.coordinate)
            } else {
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            let destination = MKMapItem(placemark: place!)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            MKMapItem.openMaps(with: [destination], launchOptions: options)
            
        }
    }
    
    func locaAuthStatus(){
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            
            mapView.showsUserLocation = true
        }else{
            location.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        
    }
    
    func centerMapOnLoc(loc: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(loc.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location{
            if !mapHasCentered {
                centerMapOnLoc(loc: loc)
                mapHasCentered = true
            }
        }
    }

}

