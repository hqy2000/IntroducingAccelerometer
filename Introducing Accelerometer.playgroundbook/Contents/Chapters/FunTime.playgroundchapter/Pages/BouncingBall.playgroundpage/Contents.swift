//#-hidden-code
import UIKit
//#-end-hidden-code
/*:
 Notice: Run this playground in your iPad in **landscape** mode with your device **heading to the left** and switch **on** the **orientation lock** of your device. **Switch off** the **mute** so you can hear the sound effect.

 
 # BouncingBall
 
 A small game controlled by the position of the device.
 
 * Start the game by clicking 'Run My Code'.
 * Change the preference by editing the variables below.
 * Tip: Many famous games like Asphalt are also based on the accelerometer.
 */
//#-hidden-code
import UIKit
import CoreMotion
import PlaygroundSupport
import AudioToolbox

class BouncingBall: UIViewController,UIAccelerometerDelegate {
    
    var ball = UIImageView(image:#imageLiteral(resourceName: "ball.png"))
    //#-end-hidden-code
    //The percentage of the speed of the ball left after bouncing
    let bouncingSpeed:Double = /*#-editable-code */0.6/*#-end-editable-code*/
    //Update the speed of the ball according to the acceleration how many times per second
    let interval:Double = /*#-editable-code */60/*#-end-editable-code*/
    //#-hidden-code
    var motionManager = CMMotionManager()
    var speed = Speed(x:0,y:0)
    var noticeSound = SystemSoundID()
    var collideY:Bool = false
    var collideX:Bool = false
    
    struct Speed {
        var x:UIAccelerationValue
        var y:UIAccelerationValue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        title = "BouncingBall"
        if(self.orientationCheck()){
            self.noticeSound = self.returnSoundDetail()
            self.startGame()
        }
    }
    
    //Start the game!
    func startGame() {
        ball.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        ball.center = self.view.center
        self.view.addSubview(ball)
        self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "background.jpg"))
        motionManager.accelerometerUpdateInterval = 1/self.interval
        if(motionManager.isAccelerometerAvailable)
        {
            let queue = OperationQueue.current
            motionManager.startAccelerometerUpdates(to: queue!, withHandler: {
                (accelerometerData, error) in
                self.speed.y += accelerometerData!.acceleration.x
                self.speed.x -=  accelerometerData!.acceleration.y
                var x = self.ball.center.x + CGFloat(self.speed.x)
                var y = self.ball.center.y - CGFloat(self.speed.y)
                if (y < 60) {
                    //Hit the roof
                    if(!self.collideY){
                        self.soundEffect()
                        self.collideY = true
                    }
                    y = 60
                    self.speed.y *= -self.bouncingSpeed
                    
                }
                else if (y > (self.view.bounds.size.height - 15)){
                    //Hit the floor
                    if(!self.collideY){
                        self.soundEffect()
                        self.collideY = true
                    }
                    y = self.view.bounds.size.height - 15
                    self.speed.y *= -self.bouncingSpeed
                }
                else{
                    self.collideY = false
                }
                if (x < 15) {
                    //Hit the left wall
                    if(!self.collideX){
                        self.soundEffect()
                        self.collideX = true
                    }
                    x = 15
                    self.speed.x *= -self.bouncingSpeed
                }
                else if (x > (self.view.bounds.size.width - 15)) {
                    //Hit the right wall
                    if(!self.collideX){
                        self.soundEffect()
                        self.collideX = true
                    }
                    x = self.view.bounds.size.width - 15
                    self.speed.x *= -self.bouncingSpeed
                }
                else {
                    self.collideX = false
                }
                self.ball.center=CGPoint(x:x, y:y)
            } )
        }
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
    //Sound Effect!
    func soundEffect(){
        AudioServicesPlaySystemSound(self.noticeSound)
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        //iPad does not have any vibrations...
    }
    
    //Return the sound id
    func returnSoundDetail() -> SystemSoundID {
        var soundID:SystemSoundID = 0
        let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "bounce" as CFString, "m4a" as CFString, nil)
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        return soundID
    }

}

func startMyPlayground(_ view:UIViewController){
    PlaygroundPage.current.liveView = UINavigationController(rootViewController: view)
}
//#-end-hidden-code
startMyPlayground(BouncingBall())
