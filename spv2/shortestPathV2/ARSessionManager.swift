//
//  ARSessionManager.swift
//  shortestPathV2
//
//  Created by Aditya Narsinghpura on 11/10/24.
//
import ARKit
import RealityKit

class ARSessionManager {
    static let shared = ARSessionManager()
    
    var session: ARSession
    var worldMap: ARWorldMap?
    
    private init() {
        session = ARSession()
    }
    
    func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            print("Loaded saved world map")
        } else {
            print("Starting new AR session without saved world map")
        }
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func saveWorldMap(completion: @escaping (Bool) -> Void) {
        session.getCurrentWorldMap { worldMap, error in
            if let error = error {
                print("Error getting current world map: \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let map = worldMap else {
                print("No world map available")
                completion(false)
                return
            }
            self.worldMap = map
            print("World map saved successfully")
            completion(true)
        }
    }
}
