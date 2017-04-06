//#-hidden-code
import UIKit
//#-end-hidden-code
/*:
 Notice: Run this playground in your iPad with **landscape** mode.
 
 # Introducing Accelerometer
 
 This PlaygroundBook will teach you what is the accelerometer, and provides you with applications including a tool and a game.
 
 - The accelerometer is a device to measure your acceleration in 3 axes.
 - Acceleration can make an object to speed up, slow down or change direction.
 - The acceleration of the earth is called gravity, which is approximately 9.8 m/s².
 - You can see the data collected by the accelerometer inside your iPad and a sketch map on the right part of the screen after clicking 'Run My Code'.
 - You can edit the interval of updating so that you can see the data more clearly, however, making the interval too big will cause overheating or lag.
 - Try to balance your device by making accelerations of x-axis and y-axis equal to zero. Gradiometer is based on the same theory.
 */
//#-hidden-code
import UIKit
import CoreMotion
import PlaygroundSupport

class fetchingData: UIViewController,UIAccelerometerDelegate {
    
    var motionManager = CMMotionManager()
    var accelerationLabel = UILabel(frame: CGRect(x: 65, y: 30, width: 300, height:200))
    var directionImage = UIImageView(image: #imageLiteral(resourceName: "direction.png"))
    let G = 9.8
    //#-end-hidden-code
    //The bigger the number is, the faster the data updates
    let interval:Double = /*#-editable-code */30/*#-end-editable-code*/
    //Approximately to a certain decimal place
    let decimalPlace:Int = /*#-editable-code */1/*#-end-editable-code*/
    //#-hidden-code
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Fetch your Accelerometer's Data"
        motionManager.accelerometerUpdateInterval = 1/self.interval
        self.view.backgroundColor = UIColor.white
        if(orientationCheck()){
            self.initUI()
        }
    }
    
    func initUI(){
        self.directionImage.frame = CGRect(x: 60, y:200, width:290, height:300)
        self.view.addSubview(self.accelerationLabel)
        self.view.addSubview(self.directionImage)
        self.accelerationLabel.numberOfLines = 0
        if motionManager.isAccelerometerAvailable {
            let queue = OperationQueue.current
            motionManager.startAccelerometerUpdates(to: queue!, withHandler: {
                (accelerometerData, error) in
                self.accelerationLabel.text="Acceleration of x-axis:" + String(format: "%." + String(self.decimalPlace) + "f", accelerometerData!.acceleration.x * self.G) + " m/s² \nAcceleration of y-axis:" + String(format: "%." + String(self.decimalPlace) + "f", accelerometerData!.acceleration.y * self.G) + " m/s² \nAcceleration of z-axis:" + String(format: "%." + String(self.decimalPlace) + "f", accelerometerData!.acceleration.z * self.G) + " m/s²"
            })
        }

    }
    //Check the device's orientation
    func orientationCheck() -> Bool {
        if(self.view.bounds.width < 1024){
            let noticeLabel = UILabel(frame: CGRect(x: 170,y :20, width: 700, height:100))
            noticeLabel.numberOfLines = 0
            noticeLabel.text = "Please switch to lanscape mode and try again."
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
startMyPlayground(fetchingData())
