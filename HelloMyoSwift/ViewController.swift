import UIKit

class ViewController: UIViewController, OEEventsObserverDelegate{

    @IBOutlet weak var accelerationProgressBar: UIProgressView!
    @IBOutlet weak var helloLabel: UILabel!
    @IBOutlet weak var accelerationLabel: UILabel!
    @IBOutlet weak var armLabel: UILabel!
    @IBOutlet weak var gyroscopeLabel: UILabel!
    
    @IBOutlet weak var button1: UIButton!
    
    @IBOutlet weak var pushText: UITextField!

    @IBOutlet var stateText: UITextField!
    @IBOutlet weak var yawText: UITextField!
    @IBOutlet weak var rowText: UITextField!
    @IBOutlet weak var num: UITextField!
    @IBOutlet weak var pitchText: UITextField!
    var pushUpsDone = 0 // pushup counters
    var currentPose: TLMPose!
    var pushUpState = 0 // finite state machine (0=top of pushup, 1=bottom of pushup)
    var startPosition: (pitch: CGFloat, yaw: CGFloat, roll: CGFloat)? // Euler angles
    var currentPosition: (pitch: CGFloat, yaw: CGFloat, roll: CGFloat)? // Euler angles
    var quaternionCounter = 0 // counter to limit the amount of times that app receives orientation events
    var openEarsEventsObserver = OEEventsObserver() //start listening to audios 
    var timer = NSTimer()
    
    
    var lmPath: String! //path to the English packet
    var dicPath: String! //path to dictionary
    var words: Array<String> = ["START PUSHUP" , "STOP PUSHUP"]
    var currentWord: String!
    
    var stop = 0
    var start = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifier = NSNotificationCenter.defaultCenter()
        loadOpenEars()
        pushText.hidden = true
        stateText.text = "up"
        
        startListening()
        // Data notifications are received through NSNotificationCenter.
        notifier.addObserver(self, selector: "didConnectDevice:", name: TLMHubDidConnectDeviceNotification, object: nil)
        notifier.addObserver(self, selector: "didDisconnectDevice:", name: TLMHubDidDisconnectDeviceNotification, object: nil)
        
        // Notifications for orientation event are posted at a rate of 50 Hz.
        notifier.addObserver(self, selector: "didRecieveOrientationEvent:", name: TLMMyoDidReceiveOrientationEventNotification, object: nil)
        // Notifications accelerometer event are posted at a rate of 50 Hz.
        notifier.addObserver(self, selector: "didRecieveAccelerationEvent:", name: TLMMyoDidReceiveAccelerometerEventNotification, object: nil)
        // Posted when one of the pre-configued geatures is recognized (e.g. Fist, Wave In, Wave Out, etc)
        notifier.addObserver(self, selector: "didChangePose:", name: TLMMyoDidReceivePoseChangedNotification, object: nil)
        notifier.addObserver(self, selector: "didRecieveGyroScopeEvent:", name: TLMMyoDidReceiveGyroscopeEventNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        pocketsphinxDidDetectSpeech() //detect if the user starts talking
//        if(start == 0){
//            pocketsphinxDidReceiveHypothesis("START", recognitionScore: "20", utteranceID: "")
//        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
//        stopListening()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapSettings(sender: AnyObject) {
        // Settings view must be in a navigation controller when presented
        let controller = TLMSettingsViewController.settingsInNavigationController()
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func getCurrentPosition(sender: AnyObject) { //initilaize the height
        startPosition = currentPosition
    }
    
    //band is connected
    func didConnectDevice(notification: NSNotification) {
        button1.hidden = true
        pushText.hidden = false
        
        //    helloLabel.center = self.view.center
        //        armLabel.text = "Perform the Sync Gesture"
        //    helloLabel.text = "Hello Myo"
        //
        //    accelerationProgressBar.hidden = false
        //    accelerationLabel.hidden = false
    }
    
    func didDisconnectDevice(notification: NSNotification) {
        helloLabel.text = ""
        armLabel.text = ""
        accelerationProgressBar.hidden = true
        accelerationLabel.hidden = true
    }
    
    func didRecieveOrientationEvent(notification: NSNotification) {
        quaternionCounter++ // counter to limit calls to ReceiveOrientationEvent
        if (quaternionCounter < 7) {
            return
        }
        
        let eventData = notification.userInfo as! Dictionary<NSString, TLMOrientationEvent>
        let orientationEvent = eventData[kTLMKeyOrientationEvent]!
        
        let angles = GLKitPolyfill.getOrientation(orientationEvent)
        let pitch = CGFloat(angles.pitch.radians)
        let yaw = CGFloat(angles.yaw.radians)
        let roll = CGFloat(angles.roll.radians)
        let rotationAndPerspectiveTransform:CATransform3D = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, pitch, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, yaw, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, roll, 0.0, 0.0, -1.0))
        yawText.text = "Yaw: " + (NSString(format: "%.2f", yaw) as String) as String
        rowText.text = "Roll: " + (NSString(format: "%.2f", roll) as String) as String
        pitchText.text = "Pitch: " + (NSString(format: "%.2f", pitch) as String) as String
        // Apply the rotation and perspective transform to helloLabel.
        helloLabel.layer.transform = rotationAndPerspectiveTransform
        
        currentPosition = (pitch, yaw, roll)
        if (startPosition != nil && stop == 0) { //execute when start is recognized and stop not recognized
            if (pushUpState == 0) {
                //if position is within some given range, change pushUpState=1
                let pitchDiff = currentPosition!.pitch - startPosition!.pitch
                if (pitchDiff > 0) { // pitch difference threshold
                    let rollDiff = currentPosition!.roll - startPosition!.roll
                    if (rollDiff < -1.1) { // roll difference threshold
                        pushUpState = 1 // change state to 1
                        startPosition = currentPosition
                        stateText.text = "down"
                    }
                }
            } else if (pushUpState == 1) {
                let pitchDiff = currentPosition!.pitch - startPosition!.pitch
                if (pitchDiff < 0) { // pitch difference threshold
                    let rollDiff = currentPosition!.roll - startPosition!.roll
                    if (rollDiff > 1.1) { // roll difference threshold
                        pushUpState = 0 // change state to 0
                        pushUpsDone += 1
                        startPosition = currentPosition
                        num.text = String(pushUpsDone)
                        stateText.text = "up"
                    }
                }
            }
        }
        quaternionCounter = 0
    }
    
    func didRecieveAccelerationEvent(notification: NSNotification) {
        let eventData = notification.userInfo as! Dictionary<NSString, TLMAccelerometerEvent>
        let accelerometerEvent = eventData[kTLMKeyAccelerometerEvent]!
        
        let acceleration = GLKitPolyfill.getAcceleration(accelerometerEvent);
        accelerationProgressBar.progress = acceleration.magnitude / 4.0;
        
        // Uncomment to show direction of acceleration
        //    let x = acceleration.x
        //    let y = acceleration.y
        //    let z = acceleration.z
        //    accelerationLabel.text = "Acceleration (\(x), \(y), \(z))"
    }
   
    func didChangePose(notification: NSNotification) {
        let eventData = notification.userInfo as! Dictionary<NSString, TLMPose>
        currentPose = eventData[kTLMKeyPose]!
        
        switch (currentPose.type) {
        case .Fist:
            helloLabel.text = "Fist"
            helloLabel.font = UIFont(name: "Noteworthy", size: 50)
            helloLabel.textColor = UIColor.greenColor()
        case .WaveIn:
            helloLabel.text = "Wave In"
            helloLabel.font = UIFont(name: "Courier New", size: 50)
            helloLabel.textColor = UIColor.greenColor()
        case .WaveOut:
            helloLabel.text = "Wave Out";
            helloLabel.font = UIFont(name: "Snell Roundhand", size: 50)
            helloLabel.textColor = UIColor.greenColor()
        case .FingersSpread:
            helloLabel.text = "Fingers Spread";
            helloLabel.font = UIFont(name: "Chalkduster", size: 50)
            helloLabel.textColor = UIColor.greenColor()
            //    case .ThumbToPinky:
            //      self.helloLabel.text = "Thumb to Pinky";
            //      self.helloLabel.font = UIFont(name: "Georgia", size: 50)
            //      self.helloLabel.textColor = UIColor.greenColor()
        default: // .Rest or .Unknown
            helloLabel.text = "Hello Myo"
            helloLabel.font = UIFont(name: "Helvetica Neue", size: 50)
            helloLabel.textColor = UIColor.blackColor()
        }
    }
    
    func didRecieveGyroScopeEvent(notification: NSNotification) {
        let eventData = notification.userInfo as! Dictionary<NSString, TLMGyroscopeEvent>
        let gyroEvent = eventData[kTLMKeyGyroscopeEvent]!
        
        let gyroData = GLKitPolyfill.getGyro(gyroEvent)
        // Uncomment to display the gyro values
        //    let x = gyroData.x
        //    let y = gyroData.y
        //    let z = gyroData.z
        //    gyroscopeLabel.text = "Gyro: (\(x), \(y), \(z))"
    }
    
    func loadOpenEars() {
        
        self.openEarsEventsObserver = OEEventsObserver()
        self.openEarsEventsObserver.delegate = self
        
        var lmGenerator: OELanguageModelGenerator = OELanguageModelGenerator()
        
        //addWords()
        var name = "LanguageModelFileStarSaver"
        lmGenerator.generateLanguageModelFromArray(words, withFilesNamed: name, forAcousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"))
        
        lmPath = lmGenerator.pathToSuccessfullyGeneratedLanguageModelWithRequestedName(name)
        dicPath = lmGenerator.pathToSuccessfullyGeneratedDictionaryWithRequestedName(name)
    }
  
    func pocketsphinxDidReceiveHypothesis(hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        if hypothesis == "START PUSHUP" && start == 0 { // start recognized the first time
            //do what you want here when the correct word is recognized
            startPosition = currentPosition
            start = 1
           // countDown() //start countdown
            print("start is : " + String(start))
          
        }
        if hypothesis == "STOP PUSHUP" {
            stop = 1
            startPosition = nil
            print("stop is : " + String(stop))
        }
    }


    func pocketsphinxDidStartListening() {
        print("Pocketsphinx is now listening.")
    }
    
    func startListening() {
        do {
            try OEPocketsphinxController.sharedInstance().setActive(true)
            OEPocketsphinxController.sharedInstance().secondsOfSilenceToDetect = 0.001
            OEPocketsphinxController.sharedInstance().vadThreshold = 1.5
            OEPocketsphinxController.sharedInstance().startListeningWithLanguageModelAtPath(lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"), languageModelIsJSGF: false)
            
        } catch {
            print("doesn't start listening")
        }
    }
    
    func pocketsphinxDidDetectSpeech() {
        print("Pocketsphinx has detected speech.")
    }
    
    func countDown() {
        
    }
    
    
    
}

