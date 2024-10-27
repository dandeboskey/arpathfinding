//
//  MainViewController.swift
//  shortestPathV2
//
//  Created by Aditya Narsinghpura on 11/10/24.
//
import UIKit

class MainViewController: UIViewController {
    
    var startPoint: SIMD3<Float>?
       var endPoint: SIMD3<Float>?
       var ballPositions: [SIMD3<Float>] = []
    
    override func viewDidLoad() {
           super.viewDidLoad()
           setupUI()
       }
       
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AR Path Finder"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Explore AR and find the shortest path"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .lightGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let button1: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Place AR Markers", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

  
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(button1)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            button1.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            button1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            button1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            button1.heightAnchor.constraint(equalToConstant: 50),
            
        ])
        
//        button1.addTarget(self, action: #selector(openScreen1), for: .touchUpInside)
//              button2.addTarget(self, action: #selector(openScreen2), for: .touchUpInside)
//              button3.addTarget(self, action: #selector(openScreen3), for: .touchUpInside)
        button1.setTitle("Start AR Experience", for: .normal)
        button1.addTarget(self, action: #selector(openARExperience), for: .touchUpInside)
    }
    
    @objc func openARExperience() {
         let arViewController = CombinedARViewController()
         navigationController?.pushViewController(arViewController, animated: true)
     }
}
