//
//  ViewController.swift
//  WhatFlower
//
//  Created by Brandon Mahoney on 2/27/19.
//  Copyright © 2019 Brandon Mahoney. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: - Properties
    let wikipediaURl: String = "https://en.wikipedia.org/w/api.php"
    let imagePicker: UIImagePickerController = UIImagePickerController()

    
    //MARK: - outlets
    @IBOutlet weak var camera: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    
    //MARK: - Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
//            imageView.image = userPickedImage
            guard let ciImage = CIImage(image: userPickedImage) else { fatalError("Could not convert UIImage into CIImage.") }
          
            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Loading CoreML Model failed.") }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else { fatalError("Model failed to process image.") }

                self.navigationItem.title = classification.identifier.capitalized
                self.requestData(flowerName: classification.identifier)
        }

        let handler = VNImageRequestHandler(ciImage: image)

        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    
    //MARK: - Networking
    func requestData(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                let flowerData: JSON = JSON(response.result.value!)
                self.parseFlowerData(json: flowerData)
            } else {
                print("Error: \(String(describing: response.result.error))")
            }
        }
    }
    
    //MARK: - JSON Parsing
    func parseFlowerData(json : JSON) {
        let pageid = json["query"]["pageids"][0].stringValue
        let flowerDescription = json["query"]["pages"][pageid]["extract"].stringValue
        
        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
        
        self.label.text = flowerDescription
    }

    
    //MARK: - Actions
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        if sender.tag == 1 {
            imagePicker.sourceType = .photoLibrary
        } else {
            imagePicker.sourceType = .camera
            imagePicker.showsCameraControls = true
        }
        present(imagePicker, animated: true, completion: nil)
    }
    
}

