//
//  CombinedARViewController.swift
//  shortestPathV2
//
//  Created by Aditya Narsinghpura on 11/10/24.
//
import UIKit
import ARKit
import RealityKit

class CombinedARViewController: UIViewController, ARSessionDelegate {
    
    var arView: ARView!
    var ballPositions: [SIMD3<Float>] = []
    var startPoint: SIMD3<Float>?
    var endPoint: SIMD3<Float>?
    var nodes: [Node] = []
    var neighbors: [Int: [Node]] = [:]
    var isPlacingBalls = false
    var timer: Timer?
    var areBallsHidden = false
    var pathNodes: [Int] = []
    private var showPathButton: UIButton!
    private var createGraphButton: UIButton!
    private var toggleBallsButton: UIButton!
    private var toggleBallVisibilityButton: UIButton!



    struct Node: Hashable {
        let id: Int
        let position: SIMD3<Float>
        
        func distance(to node: Node) -> Float {
            return simd_distance(self.position, node.position)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupButtons()
        showPathButton.isHidden = true
    }

    private func setupARView() {
        arView = ARView(frame: view.bounds)
        view.addSubview(arView)
        
        arView.session = ARSessionManager.shared.session
        arView.session.delegate = self
        
        ARSessionManager.shared.startSession()
    }
    
    private func setupButtons() {
        let buttonHeight: CGFloat = 50
                let buttonSpacing: CGFloat = 10
                let bottomPadding: CGFloat = 20
                let sideSpacing: CGFloat = 20
                
                
                toggleBallsButton = createButton(title: "Start Balls", action: #selector(toggleBallPlacement), color: .systemBlue)
                let setStartButton = createButton(title: "Set Start", action: #selector(setStartPoint), color: .systemGreen)
                let setEndButton = createButton(title: "Set End", action: #selector(setEndPoint), color: .systemRed)
                let clearPointsButton = createButton(title: "Clear Points", action: #selector(clearPoints), color: .systemBlue)
                createGraphButton = createButton(title: "Create Graph", action: #selector(createGraph), color: .systemBlue)
                showPathButton = createButton(title: "Show Path", action: #selector(showShortestPath), color: .systemBlue)
                toggleBallVisibilityButton = createButton(title: "Hide Balls", action: #selector(toggleBallVisibility), color: .systemBlue)
                
                showPathButton.isHidden = true
           
           let topStackView = UIStackView(arrangedSubviews: [toggleBallsButton, setStartButton, setEndButton])
           let bottomStackView = UIStackView(arrangedSubviews: [clearPointsButton, createGraphButton, showPathButton])
           let mainStackView = UIStackView(arrangedSubviews: [topStackView, bottomStackView, toggleBallVisibilityButton])
           
           [topStackView, bottomStackView].forEach { stackView in
               stackView.axis = .horizontal
               stackView.distribution = .fillEqually
               stackView.spacing = buttonSpacing
           }
           
           mainStackView.axis = .vertical
           mainStackView.spacing = buttonSpacing
           
           view.addSubview(mainStackView)
           mainStackView.translatesAutoresizingMaskIntoConstraints = false
           
           NSLayoutConstraint.activate([
               mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -bottomPadding),
               mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideSpacing),
               mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideSpacing),
               
               topStackView.heightAnchor.constraint(equalToConstant: buttonHeight),
               bottomStackView.heightAnchor.constraint(equalToConstant: buttonHeight),
               toggleBallVisibilityButton.heightAnchor.constraint(equalToConstant: buttonHeight)
           ])
       }
       
    @objc private func toggleBallPlacement() {
        isPlacingBalls.toggle()
        if isPlacingBalls {
            startAutoPlacement()
            toggleBallsButton.setTitle("Stop Balls", for: .normal)
        } else {
            stopAutoPlacement()
            toggleBallsButton.setTitle("Start Balls", for: .normal)
        }
        print("Ball placement toggled. Now \(isPlacingBalls ? "placing" : "not placing") balls.")
    }
    
    private func createButton(title: String, action: Selector, color: UIColor) -> UIButton {
           let button = UIButton(type: .system)
           button.setTitle(title, for: .normal)
           button.addTarget(self, action: action, for: .touchUpInside)
           button.backgroundColor = color.withAlphaComponent(0.8)
           button.setTitleColor(.white, for: .normal)
           button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
           button.layer.cornerRadius = 10
           button.clipsToBounds = true
           return button
       }
    
    @objc private func createGraph() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupGraph()
            DispatchQueue.main.async {
                self.showPathButton.isHidden = false
                self.createGraphButton.isHidden = true
                print("Graph setup complete, Show Path button visible")
            }
        }
    }

    private func startAutoPlacement() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.addCenteredSphere()
        }
    }

    private func stopAutoPlacement() {
        timer?.invalidate()
        timer = nil
    }
    
    private func addCenteredSphere() {
        guard let frame = arView.session.currentFrame else { return }
        
        let centerPoint = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let results = arView.raycast(from: centerPoint, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResult = results.first {
            let position = firstResult.worldTransform.columns.3
            let spherePosition = SIMD3<Float>(position.x, position.y, position.z)
            
            addSphere(at: spherePosition, color: .blue)
            ballPositions.append(spherePosition)
        } else {
            let cameraTransform = frame.camera.transform
            let spherePosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                              cameraTransform.columns.3.y,
                                              cameraTransform.columns.3.z) + (cameraForward(transform: cameraTransform) * 2.0)
            
            addSphere(at: spherePosition, color: .blue)
            ballPositions.append(spherePosition)
        }
    }
    
    private func cameraForward(transform: simd_float4x4) -> SIMD3<Float> {
        return -SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
    }
    
    @objc private func setStartPoint() {
        if let raycastResult = arView.raycast(from: view.center, allowing: .estimatedPlane, alignment: .any).first {
            startPoint = SIMD3<Float>(raycastResult.worldTransform.columns.3.x,
                                      raycastResult.worldTransform.columns.3.y,
                                      raycastResult.worldTransform.columns.3.z)
            if let startPoint = startPoint {
                addSphere(at: startPoint, color: .green)
            }
        }
    }

    @objc private func setEndPoint() {
        if let raycastResult = arView.raycast(from: view.center, allowing: .estimatedPlane, alignment: .any).first {
            endPoint = SIMD3<Float>(raycastResult.worldTransform.columns.3.x,
                                    raycastResult.worldTransform.columns.3.y,
                                    raycastResult.worldTransform.columns.3.z)
            if let endPoint = endPoint {
                addSphere(at: endPoint, color: .red)
            }
        }
    }

    @objc private func clearPoints() {
        startPoint = nil
        endPoint = nil
        pathNodes.removeAll()
        showPathButton.isHidden = true
        createGraphButton.isHidden = false
        refreshARView()
        print("Points cleared, Show Path button hidden")
    }
    
    private func refreshARView() {
        arView.scene.anchors.removeAll()
        
        for (index, position) in ballPositions.enumerated() {
            if !areBallsHidden || pathNodes.contains(index) {
                addSphere(at: position, color: pathNodes.contains(index) ? .orange : .blue)
            }
        }
        
        if let startPoint = startPoint {
            addSphere(at: startPoint, color: .green)
        }
        
        if let endPoint = endPoint {
            addSphere(at: endPoint, color: .red)
        }
    }
    
    @objc private func showShortestPath() {
        findAndHighlightShortestPath()
    }
    
    @objc private func toggleBallVisibility() {
        areBallsHidden.toggle()
        refreshARView()
        
        let newTitle = areBallsHidden ? "Show Balls" : "Hide Balls"
            toggleBallVisibilityButton.setTitle(newTitle, for: .normal)
    }
    
    private func addSphere(at position: SIMD3<Float>, color: UIColor) {
        let sphere = MeshResource.generateSphere(radius: 0.05)
        let material = SimpleMaterial(color: color, roughness: 0, isMetallic: true)
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        
        let anchorEntity = AnchorEntity(world: position)
        anchorEntity.addChild(sphereEntity)
        
        arView.scene.addAnchor(anchorEntity)
    }
    
    private func setupGraph() {
        nodes.removeAll()
        neighbors.removeAll()
        
        var allPoints = ballPositions
        if let start = startPoint { allPoints.append(start) }
        if let end = endPoint { allPoints.append(end) }
        
        for (index, position) in allPoints.enumerated() {
            let node = Node(id: index, position: position)
            nodes.append(node)
        }
        
        for node in nodes {
            neighbors[node.id] = findClosestNeighbors(for: node, in: nodes, maxNeighbors: 5)
        }
    }
    
    private func findClosestNeighbors(for node: Node, in nodes: [Node], maxNeighbors: Int = 2) -> [Node] {
        let distances = nodes.filter { $0.id != node.id }.map { ($0, node.distance(to: $0)) }
        let sortedDistances = distances.sorted { $0.1 < $1.1 }
        return Array(sortedDistances.prefix(maxNeighbors).map { $0.0 })
    }
    
    private func findAndHighlightShortestPath() {
        guard let startIndex = nodes.firstIndex(where: { $0.position == startPoint }),
              let endIndex = nodes.firstIndex(where: { $0.position == endPoint }) else {
            print("Start or end point not found in nodes")
            return
        }
        
        let (path, _) = dijkstra(start: startIndex, end: endIndex)
        
        if path.isEmpty {
            print("No path found between start and end nodes")
        } else {
            pathNodes = path
            highlightPath(path)
        }
    }
    
    private func dijkstra(start: Int, end: Int) -> ([Int], [Float]) {
        var distances = [Float](repeating: Float.infinity, count: nodes.count)
        var previous = [Int?](repeating: nil, count: nodes.count)
        var queue = Set(0..<nodes.count)
        
        distances[start] = 0
        
        while !queue.isEmpty {
            let u = queue.min { distances[$0] < distances[$1] }!
            queue.remove(u)
            
            if u == end {
                break
            }
            
            for v in neighbors[u]! where queue.contains(v.id) {
                let alt = distances[u] + distance(from: nodes[u], to: v)
                if alt < distances[v.id] {
                    distances[v.id] = alt
                    previous[v.id] = u
                }
            }
        }
        
        var path = [Int]()
        var u: Int? = end
        while let node = u {
            path.append(node)
            u = previous[node]
        }
        
        return (path.reversed(), distances)
    }
    
    private func distance(from node1: Node, to node2: Node) -> Float {
        return simd_distance(node1.position, node2.position)
    }
    
    private func highlightPath(_ path: [Int]) {
        refreshARView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ARSessionManager.shared.saveWorldMap { success in
            if success {
                print("World map saved successfully")
            } else {
                print("Failed to save world map")
            }
        }
    }
}

