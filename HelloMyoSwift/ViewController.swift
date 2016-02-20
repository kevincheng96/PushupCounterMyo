import UIKit

class ViewController: UIViewController {

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
    var pushUpsDone = 0
    var currentPose: TLMPose!
    var pushUpState = 0
    var startPosition: (pitch: CGFloat, yaw: CGFloat, roll: CGFloat)?
    var currentPosition: (pitch: CGFloat, yaw: CGFloat, roll: CGFloat)?
    var quaternionCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let notifier = NSNotificationCenter.defaultCenter()
        pushText.hidden = true
        stateText.text = "up"
        // Data notifications are received through NSNotificationCenter.
        notifier.addObserver(self, selector: "didConnectDevice:", name: TLMHubDidConnectDeviceNotification, object: nil)
        notifier.addObserver(self, selector: "didDisconnectDevice:", name: TLMHubDidDisconnectDeviceNotification, object: nil)
        // Posted whenever the user does a Sync Gesture, and the Myo is calibrated
        //notifier.addObserver(self, selector: "didRecognizeArm:", name: TLMMyoDidReceiveArmRecognizedEventNotification, object: nil)
        // Posted whenever Myo loses its calibration (when Myo is taken off, or moved enough on the user's arm)
        //notifier.addObserver(self, selector: "didLoseArm:", name: TLMMyoDidReceiveArmLostEventNotification, object: nil)
        
        // Notifications for orientation event are posted at a rate of 50 Hz.
        notifier.addObserver(self, selector: "didRecieveOrientationEvent:", name: TLMMyoDidReceiveOrientationEventNotification, object: nil)
        // Notifications accelerometer event are posted at a rate of 50 Hz.
        notifier.addObserver(self, selector: "didRecieveAccelerationEvent:", name: TLMMyoDidReceiveAccelerometerEventNotification, object: nil)
        // Posted when one of the pre-configued geatures is recognized (e.g. Fist, Wave In, Wave Out, etc)
        notifier.addObserver(self, selector: "didChangePose:", name: TLMMyoDidReceivePoseChangedNotification, object: nil)
        notifier.addObserver(self, selector: "didRecieveGyroScopeEvent:", name: TLMMyoDidReceiveGyroscopeEventNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapSettings(sender: AnyObject) {
        // Settings view must be in a navigation controller when presented
        let controller = TLMSettingsViewController.settingsInNavigationController()
        presentViewController(controller, animated: true, completion: nil)
    }
    
    @IBAction func getCurrentPosition(sender: AnyObject) {
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
    
    /*func didRecognizeArm(notification: NSNotification) {
    let eventData = notification.userInfo as! Dictionary<NSString, TLMArmRecognizedEvent>
    let armEvent = eventData[kTLMKeyArmRecognizedEvent]!
    
    var arm = armEvent.arm == .Right ? "Right" : "Left"
    var direction = armEvent.xDirection == .TowardWrist ? "Towards Wrist" : "Toward Elbow"
    armLabel.text = "Arm: \(arm) X-Direction: \(direction)"
    helloLabel.textColor = UIColor.blueColor()
    
    armEvent.myo!.vibrateWithLength(.Short)
    }
    */
    /* func didLoseArm(notification: NSNotification) {
    armLabel.text = "Perform the Sync Gesture"
    helloLabel.text = "Hello Myo"
    helloLabel.textColor = UIColor.blackColor()
    
    let eventData = notification.userInfo as! Dictionary<NSString, TLMArmLostEvent>
    let armEvent = eventData[kTLMKeyArmLostEvent]!
    armEvent.myo!.vibrateWithLength(.Short)
    }*/
    
    func didRecieveOrientationEvent(notification: NSNotification) {
        quaternionCounter++
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
        if (startPosition != nil) {
            if (pushUpState == 0) {
                //if position is within some given range, change pushUpState=1
                //let yawDiff = currentPosition!.yaw - startPosition!.yaw //use abs value / 2 for EMERGENCY SIUTATION
                //if (yawDiff > 1.3) { //1.3
                let pitchDiff = currentPosition!.pitch - startPosition!.pitch
                if (pitchDiff > 0) {
                    let rollDiff = currentPosition!.roll - startPosition!.roll
                    if (rollDiff < -1.1) { //-1.1
                        pushUpState = 1
                        startPosition = currentPosition
                        stateText.text = "down"
                    }
                }
            } else if (pushUpState == 1) {
                //let yawDiff = currentPosition!.yaw - startPosition!.yaw
                //if (yawDiff < -1.2) {
                let pitchDiff = currentPosition!.pitch - startPosition!.pitch
                if (pitchDiff < 0) {
                    let rollDiff = currentPosition!.roll - startPosition!.roll
                    if (rollDiff > 1.1) {
                        pushUpState = 0
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
}

