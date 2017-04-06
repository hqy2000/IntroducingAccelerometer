//#-hidden-code
import UIKit
//#-end-hidden-code
/*:
 Notice: Run this playground in your iPad with **landscape** mode and **half-screen** mode. **Switch off** the **mute** so you can hear the tone.
 
 # iSpeed

 A simple tool to help you measure the speed without the GPS.
 
 * Start the speedometer by clicking 'Run My Code'.
 * Adjust the variables below until it has a good accuracy.
 * Tip: This is a tool with partial function of inertial navigation.
 */
//#-hidden-code
import UIKit
import CoreMotion
import AudioToolbox
import PlaygroundSupport

class iSpeed: UIViewController,UIAccelerometerDelegate {
    let G = 9.8
    var relativeLabel:UILabel = UILabel()
    var absoluteLabel:UILabel = UILabel()
    var infoLabel:UILabel = UILabel()
    var ipadIcon:UIImageView = UIImageView(image:#imageLiteral(resourceName: "instruction.png"))
    var absoluteSpeed:Double = 0
    var relativeSpeed:Double = 0
    var gravityCount:Int = 0
    var realGravity:Double = 0
    var realtiveError:Int = 0
    var absoluteError:Int = 0
    //#-end-hidden-code
    //Maximum errors allowed (such as unbalance)
    let errorAllowed:Int = /*#-editable-code */3/*#-end-editable-code*/
    //Maximum rotation allowed for unbalance of absolute mode
    let maxRotationAllowedForAbsolute:Double = /*#-editable-code */0.3/*#-end-editable-code*/
    //Maximum rotation allowed for unbalance of relative mode
    let maxRotationAllowedForRelative:Double = /*#-editable-code */0.1/*#-end-editable-code*/
    //Interval for fetching the data from the accelerometer
    let sampleInterval:TimeInterval = /*#-editable-code */3/*#-end-editable-code*/
    //Sample number for calculating the initial gravity
    let sampleNumber:Int = /*#-editable-code */9/*#-end-editable-code*/
    //#-hidden-code
    let motionManager = CMMotionManager()
    var noticeSound = SystemSoundID()
    
    let beforeAdjustingText = "Please place your device horizontally and stably. You are not horizontal enough now."
    let adjustingInProcessText = "Adjusting... Do not move your device until this message disappears. It takes about 3 seconds."
    let guideText = "Tips:\n1.If your data is shown in red, it means the accuracy of that data can't be guaranteed.\n2.Do not measure very small or rapid changing speed. It can't give you the correct reading.\n3.The graph below gives you instructions about how to use this tool."
    
    struct Acceleration{
        var x:Double
        var y:Double
        var z:Double
    }
    
    enum buttonAction:Int{
        case zeroCleaning = 1
        case startMeasuring = 2
        case pauseMeasuring = 3
    }
    
    override func viewDidLoad() {
        //Initialize all things
        super.viewDidLoad()
        title = "iSpeed"
        self.view.backgroundColor = UIColor.white
        self.motionManager.accelerometerUpdateInterval = 1/self.sampleInterval
        self.noticeSound = returnSoundDetail()
        if(self.orientationCheck()){
            self.initUI()
            self.startMeasuring()
        }
        
    }
    
    //Initialize all the UI components
    func initUI() {
        var resolution = self.calculateHalfScreenResolution()
        let x = resolution[0]
        let y = resolution[1]
        self.relativeLabel = UILabel(frame: CGRect(x:x*0.1, y:50+y*0, width:x*0.8, height:y*0.1))
        self.absoluteLabel = UILabel(frame: CGRect(x:x*0.1, y:40+y*0.1, width:x*0.8, height:y*0.1))
        self.infoLabel = UILabel(frame: CGRect(x:x*0.1, y:40+y*0.1, width:x*0.8, height:y*0.1))
        self.infoLabel.alpha = 0;
        self.absoluteLabel.numberOfLines = 0
        self.absoluteLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.absoluteLabel.textAlignment = NSTextAlignment.center
        self.relativeLabel.numberOfLines = 0
        self.relativeLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.relativeLabel.textAlignment = NSTextAlignment.center
        self.infoLabel.numberOfLines = 0
        self.infoLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        //self.infoLabel.textAlignment = NSTextAlignment.
        self.view.addSubview(self.absoluteLabel)
        self.view.addSubview(self.relativeLabel)
        self.view.addSubview(infoLabel)
        self.fadeInOrOut(object: self.infoLabel,duration:1.5)
    }
    
    //Initialize the UI components after adjusting
    func afterAdjusting(){
        self.fadeInOrOut(object: self.infoLabel)
        self.infoLabel.textColor = UIColor.black
        var resolution = self.calculateHalfScreenResolution()
        let x = resolution[0]
        let y = resolution[1]
        self.infoLabel.frame = CGRect(x:x*0.1, y:-10 + y*0.3, width:x*0.8, height:y*0.3)
        self.infoLabel.numberOfLines = 0
        self.infoLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        addButton(view: view, text: "Start", x: x*0.2, y: -25 + y*0.3, height: y*0.05, width: x*0.19, action: buttonAction.startMeasuring, isHidden: true)
        addButton(view: view, text: "Pause", x: x*0.4, y: -25 + y*0.3, height: y*0.05, width: x*0.19, action: buttonAction.pauseMeasuring)
        addButton(view: view, text: "Reset", x: x*0.6, y: -25 + y*0.3, height: y*0.05, width: x*0.2, action: buttonAction.zeroCleaning)
        self.ipadIcon.frame = CGRect(x:x*0.1, y:-30 + y*0.6, width:x*0.8, height:y*0.2)
        self.infoLabel.text = self.guideText
        self.ipadIcon.alpha = 0
        self.relativeLabel.alpha = 0
        self.absoluteLabel.alpha = 0
        self.view.addSubview(self.infoLabel)
        self.view.addSubview(self.ipadIcon)
        self.fadeInOrOut(object: self.infoLabel)
        self.fadeInOrOut(object: self.ipadIcon)
        self.fadeInOrOut(object: self.relativeLabel)
        self.fadeInOrOut(object: self.absoluteLabel)
    }
    
    //Adjusting the device and calculate the gravity
    func initializeGravity(velocity:Acceleration) -> Bool{
        if(abs(velocity.x)>0.05 || abs(velocity.y)>0.05 || abs(velocity.z)<0.95){
            self.infoLabel.text = self.beforeAdjustingText
            self.infoLabel.textColor = UIColor.red
            self.warning()
            return false
        }
        else{
            self.infoLabel.text = self.adjustingInProcessText
            self.infoLabel.textColor = UIColor.green
            self.realGravity += self.threeForces(f1: velocity.x, f2: velocity.y, f3: velocity.z)
            self.realGravity /= 2
        }
        if(self.gravityCount == self.sampleNumber){
            afterAdjusting()
        }
        return true
    }
    
    //Handle the acceleration data
    func startMeasuring(){
        //Handle the acceleration data by 0.33s
        if motionManager.isAccelerometerAvailable {
            let queue = OperationQueue.current
            motionManager.startAccelerometerUpdates(to: queue!, withHandler: {
                (accelerometerData, error) in
                let velocity = Acceleration(x: accelerometerData!.acceleration.x,y:accelerometerData!.acceleration.y,z:accelerometerData!.acceleration.z)
                if(self.gravityCount <= self.sampleNumber){
                    if(self.initializeGravity(velocity: velocity) == true){
                        self.gravityCount += 1
                    }
                    else{
                        self.gravityCount = 0
                    }
                }
                else{
                    self.handleAbsoluteAcceleration(velocity: velocity)
                    self.handleRelativeAcceleration(velocity: velocity)
                    self.updateSpeedLabel()
                }
            })
        }
    }
    
    //Update the label for the speed
    func updateSpeedLabel() {
        if(self.absoluteError > self.errorAllowed){
            self.absoluteLabel.textColor = UIColor.red
        }
        if(self.realtiveError > self.errorAllowed){
            self.relativeLabel.textColor = UIColor.red
        }
        self.absoluteLabel.text = "Absolute Mode\n(Speed acumulated by absolute value)\n" + String(format: "%.3f", self.absoluteSpeed) + " km/h"
        self.relativeLabel.text = "Relative Mode\n(Speed accumulated by y-axis acceleration)\n" + String(format: "%.3f", self.relativeSpeed) + " km/h"
    }
    
    //Calculate the acceleration added together (absolute value)
    func handleAbsoluteAcceleration(velocity:Acceleration) {
        let ground = self.threeForces(f1:velocity.x, f2:velocity.y, f3:velocity.z)
        let nowSpeed = self.solveAnotherForce(total: ground, known: self.realGravity)
        if(abs(nowSpeed) > 0.15){
            self.absoluteSpeed += (nowSpeed / self.sampleInterval) * self.G
        }
        if(self.absoluteSpeed < 0){
            self.absoluteSpeed = 0
        }
        if(abs(velocity.x) > self.maxRotationAllowedForAbsolute || abs(abs(velocity.z)-self.realGravity) > self.maxRotationAllowedForAbsolute){
            self.warning()
            self.absoluteError += 1
        }
    }
    
    //Calculate the acceleration by acceleration of y-axis
    func handleRelativeAcceleration(velocity:Acceleration) {
        if(abs(velocity.y)>0.15){
            self.relativeSpeed += velocity.y / self.sampleInterval * G
        }
        if(self.relativeSpeed <= 0){
            self.relativeSpeed = 0
        }
        if(abs(velocity.x) > self.maxRotationAllowedForRelative || abs(abs(velocity.z)-self.realGravity) > self.maxRotationAllowedForRelative){
            self.warning()
            self.realtiveError += 1
        }
    }
    //Due to mass is constant all the time in this case, we can use formula of force to calculate the acceleration
    //Return the resultant forces of two different forces
    func combiningForces(f1:Double,f2:Double) -> Double {
        let f1_t = pow(f1,2.0)
        let f2_t = pow(f2,2.0)
        let f_t = 2*f1*f2*cos(90)
        let f_temp = sqrt(f1_t + f2_t + f_t)
        return f_temp
    }
    
    //Return the resultant forces of three different forces
    func threeForces(f1:Double,f2:Double,f3:Double) -> Double{
        let f_temp = self.combiningForces(f1: f1, f2: f2)
        let f_final = self.combiningForces(f1: f_temp, f2: f3)
        return f_final
    }
    
    //Slove unknown forces with known angle and resultant force
    func solveAnotherForce(total:Double,known:Double) -> Double{
        //f(resultant)=f1^2+f2^2[angle=90]
        let f_temp = pow(total,2.0)
        let f2 = pow(known,2.0)
        var f1 = sqrt(abs(f_temp-f2))
        if(f_temp-f2<0){
            f1 = -f1
        }
        return f1
    }
    
    //Return the available screen size in array. (For manual auto-resize use)
    func calculateHalfScreenResolution() -> Array<Double>{
        //Only allow in landscape mode
        var viewWidth = Double(UIScreen.main.bounds.width)
        var viewHeight = Double(UIScreen.main.bounds.height)
        if (viewWidth > 768){
            viewWidth /= 2
        }
        else{
            viewHeight -= 152
            viewHeight -= 40
        }
        viewWidth -= 80
        return [viewWidth, viewHeight]
        //2 - 80
        //Subtract the blank area which cannot be used
    }
    
    //Handle the button event
    func buttonPressed(button:UIButton){
        switch(button.tag){
        case buttonAction.pauseMeasuring.rawValue:
            motionManager.stopAccelerometerUpdates()
            let targetButton = self.view.viewWithTag(buttonAction.startMeasuring.rawValue) as! UIButton
            self.fadeInOrOut(object: targetButton)
            self.fadeInOrOut(object: button)
            break;
        case buttonAction.startMeasuring.rawValue:
            let targetButton = self.view.viewWithTag(buttonAction.pauseMeasuring.rawValue) as! UIButton
            self.fadeInOrOut(object: targetButton)
            self.fadeInOrOut(object: button)
            self.startMeasuring()
            break;
        case buttonAction.zeroCleaning.rawValue:
            self.relativeSpeed = 0
            self.absoluteSpeed = 0
            self.absoluteError = 0
            self.realtiveError = 0
            self.relativeLabel.textColor = UIColor.black
            self.absoluteLabel.textColor = UIColor.black
            self.updateSpeedLabel()
            break
        default:
            break
        }
    }
    
    //Add a button.
    func addButton(view:UIView,text:String,x:Double,y:Double,height:Double,width:Double,action:buttonAction,isHidden:Bool = false, backgroundColour:UIColor = UIColor.darkGray ,TextColour:UIColor = UIColor.white) {
        let button = UIButton(frame: CGRect(x:x, y:y, width:width, height:height))
        button.backgroundColor = backgroundColour
        button.setTitleColor(TextColour, for: UIControlState.focused)
        button.setTitle(text, for: UIControlState.normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(buttonPressed(button:)), for: .touchUpInside)
        button.tag = action.rawValue
        //Button.translatesAutoresizingMaskIntoConstraints = false
        //Button.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        //Always make errors....
        button.alpha = 0
        view.addSubview(button)
        if(!isHidden){
            self.fadeInOrOut(object: button)
        }
    }
    //Animations!
    func fadeInOrOut(object:UIView,duration:Double = 1){
        if (object.alpha == 0){
            UIView.animate(withDuration: duration, animations: {
                object.alpha = 1
            })
        }
        else{
            UIView.animate(withDuration: duration, animations: {
                object.alpha = 0
            })
        }
    }
    //Use system sound and vibrations to notice the user
    func warning(){
        AudioServicesPlaySystemSound(self.noticeSound)
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        //iPad does not have any vibrations...
    }
    
    //Return the notice tone id
    func returnSoundDetail() -> SystemSoundID {
        var soundID:SystemSoundID = 0
        let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "tone" as CFString, "m4a" as CFString, nil)
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        return soundID
    }
    
    //Check the device's orientation
    func orientationCheck() -> Bool {
        if(self.view.bounds.width < 1024){
            let noticeLabel = UILabel(frame: CGRect(x: 35,y :20, width: 700, height:100))
            noticeLabel.numberOfLines = 0
            noticeLabel.text = "Please switch to lanscape mode with the device heading to the left and try again."
            noticeLabel.textColor = UIColor.red
            noticeLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            self.view.addSubview(noticeLabel)
            return false
        }
        return true
    }

}

func startMyPlayground(_ view:UIViewController){
    PlaygroundPage.current.liveView = UINavigationController(rootViewController: view)
}
//#-end-hidden-code
startMyPlayground(iSpeed())


