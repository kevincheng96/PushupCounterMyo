import UIKit

class ViewController: UIViewController, OEEventsObserverDelegate{

    @IBOutlet weak var armBand: UIImageView!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var pushText: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var reset: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var num: UILabel!
    var pushUpsDone = 0 // pushup counters
    var currentPose: TLMPose!
    var pushUpState = 0 // finite state machine (0=top of pushup, 1=bottom of pushup)
    var startPosition: (pitch: CGFloat, yaw: CGFloat, roll: CGFloat)? // Euler angles
    var currentPosition: (pitch: CGFloat, yaw: CGFloat, roll: CGFloat)? // Euler angles
    var quaternionCounter = 0 // counter to limit the amount of times that app receives orientation events
    var openEarsEventsObserver = OEEventsObserver() //start listening to audios 
    var timer = NSTimer()
    let defaults = NSUserDefaults.standardUserDefaults()
    var highscore:Int = 0
    
    var lmPath: String! //path to the English packet
    var dicPath: String! //path to dictionary
    var words: Array<String> = ["START" , "STOP"]
    var currentWord: String!
    var tempCount = 0
    
    var stop = 0
    var start = 0
    
    var counter = 0 //countdown counter
    var sum = 3
    var quarternionCounter = 0 //lolol quarternion
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let notifier = NSNotificationCenter.defaultCenter()
        loadOpenEars()
        pushText.hidden = true
    
        num.hidden = true
        reset.hidden = true
        startButton.hidden = true
        stopButton.hidden = true
        highscoreLabel.hidden = true
        armBand.hidden = true
        
        
        
//        startListening()
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
        if (defaults.objectForKey("highscore") == nil) {
            defaults.setInteger(0, forKey: "highscore")
            defaults.synchronize()
        }
        highscoreLabel.text = "High Score: " + String(highscore)
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
    
    //band is connected
    func didConnectDevice(notification: NSNotification) {
        self.connectButton.hidden = true
        pushText.text = "Say 'Start' to start"
        pushText.hidden = false
        startButton.hidden = false
        highscoreLabel.hidden = false
        backgroundImage.hidden = true
        armBand.hidden = false
        startListening()
        
        
        //    helloLabel.center = self.view.center
        //        armLabel.text = "Perform the Sync Gesture"
        //    helloLabel.text = "Hello Myo"
        //
        //    accelerationProgressBar.hidden = false
        //    accelerationLabel.hidden = false
    }
    
    func didDisconnectDevice(notification: NSNotification) {
        
    }
    
    @IBAction func getCurrentPosition(sender: AnyObject) {
        print("i am at current position")
        counter = 0
        startPosition = currentPosition
        //stopButton.hidden = false
        startButton.hidden = true
        pushText.text = ""
        //pushText.text = "Say 'Stop' to Stop"
        num.text = ""
        num.hidden = false
        stopButton.hidden = false
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
    }
    
    @IBAction func resetButton(sender: AnyObject) { //reset
        start = 0
        stop = 0
        num.text = "0"
        counter = 0
        startButton.hidden = false
        reset.hidden = true
        pushText.text = "Say 'Start' to Start"
    }
    

    @IBAction func stopPushUps(sender: AnyObject) {
        stop = 1
        stopButton.hidden = true
        reset.hidden = false
        pushText.text = "Hit Reset to Start Over"
    }
    
    func didRecieveOrientationEvent(notification: NSNotification) {
        quaternionCounter++ // counter to limit calls to ReceiveOrientationEvent
        if (quaternionCounter < 7) {
            return
        }
        
        if (num.text == "START" && tempCount == 6) { // loop to change "start" to "0" smoothly
            num.text = "0"
        } else if (num.text == "START") {
            tempCount++
        }
        
        let eventData = notification.userInfo as! Dictionary<NSString, TLMOrientationEvent>
        let orientationEvent = eventData[kTLMKeyOrientationEvent]!
        
        let angles = GLKitPolyfill.getOrientation(orientationEvent)
        let pitch = CGFloat(angles.pitch.radians)
        let yaw = CGFloat(angles.yaw.radians)
        let roll = CGFloat(angles.roll.radians)
        let rotationAndPerspectiveTransform:CATransform3D = CATransform3DConcat(CATransform3DConcat(CATransform3DRotate (CATransform3DIdentity, pitch, -1.0, 0.0, 0.0), CATransform3DRotate(CATransform3DIdentity, yaw, 0.0, 1.0, 0.0)), CATransform3DRotate(CATransform3DIdentity, roll, 0.0, 0.0, -1.0))
       
        // Apply the rotation and perspective transform to helloLabel.
       
        
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
                       
                    }
                }
            }
        }
        quaternionCounter = 0
        
        if (stop == 1) {
            if (pushUpsDone > highscore) {
                defaults.setInteger(pushUpsDone, forKey: "highscore")
                defaults.synchronize()
            }
        }
        highscore = defaults.integerForKey("highscore")
        highscoreLabel.text = "High Score: " + String(highscore)
    }
    
    func didRecieveAccelerationEvent(notification: NSNotification) {
        let eventData = notification.userInfo as! Dictionary<NSString, TLMAccelerometerEvent>
        let accelerometerEvent = eventData[kTLMKeyAccelerometerEvent]!
        
        let acceleration = GLKitPolyfill.getAcceleration(accelerometerEvent);
       

    }
   
    /*func didChangePose(notification: NSNotification) {
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
    }*/
    
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
        if (hypothesis == "START" && start == 0) { // start recognized the first time
            startButton.hidden = true
            pushText.text = ""
            start = 1
            print("start is : " + String(start))
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
            
            //schedule the timer on the view run loop
        }
        
        if hypothesis == "STOP" {
            stop = 1
            startPosition = nil
            start = 0
            stopButton.hidden = true
            reset.hidden = false
            pushText.text = "Hit Reset to Start Over"
            print("stop is : " + String(stop))
            //unschedule the timer on the view run loop
        }
    }


    func pocketsphinxDidStartListening() {
        print("Pocketsphinx is now listening.")
    }
    
    func startListening() {
        do {
            try OEPocketsphinxController.sharedInstance().setActive(true)
            OEPocketsphinxController.sharedInstance().secondsOfSilenceToDetect = 0.001
            OEPocketsphinxController.sharedInstance().vadThreshold = 4
            OEPocketsphinxController.sharedInstance().startListeningWithLanguageModelAtPath(lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"), languageModelIsJSGF: false)
            
        } catch {
            print("doesn't start listening")
        }
    }
    
    func pocketsphinxDidDetectSpeech() {
        print("Pocketsphinx has detected speech.")
    }
    
    
    func update() { //update Time
        print("goes into update")
        if(counter < 3)
        {
            if(counter == 1) {//register initial state at the 2nd second
                startPosition = currentPosition
            }
            num.hidden = false
            num.text = String(sum - counter)
            counter += 1
        } else if (counter == 3){
            num.text = "START"
            counter++
            timer.invalidate()
            stopButton.hidden = false
            pushText.text = "Say 'Stop' to Stop"
        }
    }
    
}

