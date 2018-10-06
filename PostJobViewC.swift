//
//  PostJobViewC.swift
//  CarLive
//
//  Created by Ramneet Singh on 18/03/18.
//  Copyright © 2018 Ramneet Singh. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class PostJobViewC: UIViewController, PayPalPaymentDelegate {

    //MARK:- Labels outlets
    var descriptionsDicForPost = [[Int:[String: String]]]()
    @IBOutlet weak var surveyLbl1: UILabel!
    @IBOutlet weak var surveyLbl1Ans: UILabel!
    var surveyFirstId = Int()

    @IBOutlet weak var surveyLbl2: UILabel!
    @IBOutlet weak var surveyLbl2Ans: UILabel!
    var surveySecondtId = Int()

    @IBOutlet weak var surveyLbl3: UILabel!
    @IBOutlet weak var surveyLbl3Ans: UILabel!
    var surveyThirdId = Int()

    @IBOutlet weak var descriptionTextView: UITextView!

    @IBOutlet weak var nvActivityView: NVActivityIndicatorView!
    var i:Int = 1

    @IBOutlet weak var menuButton: UIBarButtonItem!

    var resultText = "" // empty
    var payPalConfig = PayPalConfiguration() // default

    @IBOutlet weak var successView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "PayPal by Ramneet"
        successView.isHidden = true

        // Set up payPalConfig
        payPalConfig.acceptCreditCards = false
        payPalConfig.merchantName = "Awesome Shirts, Inc."
        payPalConfig.merchantPrivacyPolicyURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
        payPalConfig.merchantUserAgreementURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")

        payPalConfig.languageOrLocale = Locale.preferredLanguages[0]
        payPalConfig.payPalShippingAddressOption = .payPal;

        print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")

        self.navigationItem.title = "SERVICE TYPE"

        self.menuButton.target = self.revealViewController()
        self.menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        nvActivityView.color = Validations.AppThemeColor()

        for i in (0..<descriptionsDicForPost.count){
            let singleDiscription = descriptionsDicForPost[i]

            for (key, value) in singleDiscription{
                if i == 0{
                    self.surveyFirstId = key }
                if i == 1{
                    self.surveySecondtId = key }
                if i == 2{
                    self.surveyThirdId = key }

                for (secondKey, secondValue) in value{
                    if i == 0{
                        self.surveyLbl1.text = secondKey
                        self.surveyLbl1Ans.text = secondValue
                    }
                    if i == 1{
                        self.surveyLbl2.text = secondKey
                        self.surveyLbl2Ans.text = secondValue
                    }
                    if i == 2{
                        self.surveyLbl3.text = secondKey
                        self.surveyLbl3Ans.text = secondValue
                    }
                }
            }
        }



    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       // PayPalMobile.preconnect(withEnvironment: environment)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backAction(_ sender: UIButton) {

    }
    @IBAction func menuAction(_ sender: UIButton) {

    }

    @IBAction func PstJobAction(_ sender: UIButton) {

        let item1 = PayPalItem(name: DataManager.jobTitle!, withQuantity: 1, withPrice: NSDecimalNumber(string:DataManager.jobPrice!), withCurrency: "USD", withSku: "")

        let items = [item1]
        let subtotal = PayPalItem.totalPrice(forItems: items)

        // Optional: include payment details
        let shipping = NSDecimalNumber(string: "0.00")
        let tax = NSDecimalNumber(string: "0.00")
        let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)

        let total = subtotal.adding(shipping).adding(tax)

        let payment = PayPalPayment(amount: total, currencyCode: "USD", shortDescription: DataManager.jobTitle!, intent: .sale)

        payment.items = items
        payment.paymentDetails = paymentDetails

        if (payment.processable) {
            let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
            present(paymentViewController!, animated: true, completion: nil)
        }
        else {
            // This particular payment will always be processable. If, for
            // example, the amount was negative or the shortDescription was
            // empty, this payment wouldn't be processable, and you'd want
            // to handle that here.
            print("Payment not processalbe: \(payment)")
        }
    }




    func postJobAfterPaymentSuccess(payment_type: String){
        self.nvActivityView.startAnimating()
        UserViewModel.sharedUserVM.postAnJob(user_id: DataManager.userId!, job_title: DataManager.jobTitle!, service_id: DataManager.senderJobId!, address: DataManager.currentAddress!, lat: "\(DataManager.currentLati!)", lng: "\(DataManager.currentLong!)", job_description: "", servey_data: "\(surveyFirstId)%20\(surveyLbl1Ans.text!),\(surveySecondtId)%20\(surveyLbl2Ans.text!),\(surveyThirdId)%20,\(surveyLbl3Ans.text!)", image: "", vehicle_id: DataManager.surveyId!,paymeny_token:"", price:"", payment_type:payment_type, successCallback: { (value, message) in
            print(message)
            self.nvActivityView.stopAnimating()
            if value {
                self.alertResponse(message:"Job Successfully Posted")

                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {

                    let storyboar = UIStoryboard(name: "Main", bundle: nil)
                    let secondViewController = storyboar.instantiateViewController(withIdentifier: "YourJobPostViewC") as! YourJobPostViewC
                    self.navigationController?.pushViewController(secondViewController, animated: false)
                })
            }else{
                self.alertResponse(message:message)
            }
        }) { (reason, error) in
            self.alertResponse(message:"Job Not Posted, Try again")
        }
    }


    // PayPalPaymentDelegate

    func payPalPaymentDidCancel(_ paymentViewController: PayPalPaymentViewController) {
        print("PayPal Payment Cancelled")
        resultText = ""
        successView.isHidden = true
        paymentViewController.dismiss(animated: true, completion: nil)
    }

    func payPalPaymentViewController(_ paymentViewController: PayPalPaymentViewController, didComplete completedPayment: PayPalPayment) {
        print("PayPal Payment Success !")
        paymentViewController.dismiss(animated: true, completion: { () -> Void in
            // send completed confirmaion to your server
            print("Here is your proof of payment:\n\n\(completedPayment.confirmation)\n\nSend this to your server for confirmation and fulfillment.")

            self.resultText = completedPayment.description
            self.showSuccess()
        })
    }

    // MARK: Helpers

    func showSuccess() {
        successView.isHidden = false
        successView.alpha = 1.0
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.5)
        UIView.setAnimationDelay(2.0)
        successView.alpha = 0.0
        UIView.commitAnimations()
        self.postJobAfterPaymentSuccess(payment_type: "paypal")
    }
}

