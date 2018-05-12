//
//  TouchIdManager.swift
//  TouchIdDeamSwift
//
//  Created by zengbailiang on 2018/5/12.
//  Copyright © 2018年 zengbailiang. All rights reserved.
//

import UIKit
import LocalAuthentication

typealias TouchIdFallBackBlokc = ()->Void
typealias TouchIdResultBlock = (_ useable:Bool,_ success:Bool,_ error:Error?)->Void

class TouchIdManager: NSObject {
    
    static var IDENTIFY:String? = nil
    static let SERVICE = "TOUCHID_SERVICE"
    static let ACCOUNT_PREFIX = "TOUCHID_PERFIX"
    open class func setCurrentTouchIdDataIdentity(identity:String )
    {
        TouchIdManager.IDENTIFY = identity
    }
    
    open class func currentTouchIdDataIdentity()-> String?
    {
        return TouchIdManager.IDENTIFY
    }
    
    open class func setCurrentIdentityTouchIdData()-> Bool
    {
        if self.currentTouchIdDataIdentity() == nil
        {
            return false;
        }
        else
        {
            if self.currentOriTouchIdData() != nil
            {
                //storage by keychain
                SAMKeychain.setPasswordData(self.currentOriTouchIdData()!, forService:SERVICE, account: ACCOUNT_PREFIX + self.currentTouchIdDataIdentity()!)
                return true;
            }
            else
            {
                return false;
            }
        }
    }
    
    open class func touchIdInfoDidChange()->Bool
    {
        let data = self.currentOriTouchIdData()
        if data == nil && self.isErrorTouchIDLockout() {
            //lock after unlock failed many times,and the fingerprint is not changed.
            return false
        }
        else
        {
            let oldData = self.currentIdentityTouchIdData()
            
            if oldData == nil
            {
                //never set
                return false
            }
            else if oldData == data
            {
                //not change
                return false
            }
            else
            {
                return true
            }
        }
    }
    
    open class func showTouchId(title:String,fallbackTitle:String?, fallbackBlock:TouchIdFallBackBlokc?,resultBlock:TouchIdResultBlock?)
    {
        let context = LAContext();
        context.localizedFallbackTitle = fallbackTitle
        var useableError:NSError?
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &useableError) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: title) { (success, error) in
                DispatchQueue.main.async {
                    if success
                    {
                        if resultBlock != nil
                        {
                            resultBlock!(true,success,error)
                        }
                    }
                    else
                    {
                        guard let error = error else
                        {
                            return;
                        }
                        
                        print("errorMsg:" + self.errorMessageForFails(errorCode: error._code))
                        
                        if error._code == LAError.userFallback.rawValue
                        {
                            if fallbackBlock != nil
                            {
                                fallbackBlock!()
                            }
                        }
                        else if error._code == LAError.biometryLockout.rawValue
                        {
                            //try to show password interface
                            self.tryShowTouchIdOrPwdInterface(title: title, resultBlock: resultBlock)
                        }
                        else
                        {
                            if resultBlock != nil
                            {
                                resultBlock!(true,success,error)
                            }
                        }
                    }
                }
            }
        }
        else
        {
            print("errorMsg:" + self.errorMessageForFails(errorCode:(useableError?.code)! ))
            
            if useableError?.code == LAError.biometryLockout.rawValue
            {
                //try to show password interface
                self.tryShowTouchIdOrPwdInterface(title: title, resultBlock: resultBlock)
            }
            else
            {
                if resultBlock != nil
                {
                    resultBlock!(false,false,useableError)
                }
            }
        }
    }
    
    class func tryShowTouchIdOrPwdInterface(title:String,resultBlock:TouchIdResultBlock?)
    {
        let context = LAContext();
        context.localizedFallbackTitle = ""
        var useableError:NSError?
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &useableError) {
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: title) { (success, error) in
                
                DispatchQueue.main.async {
                    if resultBlock != nil
                    {
                        resultBlock!(true,success,error)
                    }
                }
                
                guard let error = error else
                {
                    return;
                }
                print("errorMsg:" + self.errorMessageForFails(errorCode: error._code))
            }
        }
        else
        {
            print("errorMsg:" + self.errorMessageForFails(errorCode:(useableError?.code)! ))
            
            if resultBlock != nil
            {
                resultBlock!(false,false,useableError)
            }
        }
    }
    
    //MARK:touchIdData
    class func currentIdentityTouchIdData()->Data?
    {
        guard (self.currentTouchIdDataIdentity() != nil) else {
            return nil;
        }
        
        return  SAMKeychain.passwordData(forService: TouchIdManager.SERVICE, account: TouchIdManager.ACCOUNT_PREFIX + self.currentTouchIdDataIdentity()!)
    }
    
    class func currentOriTouchIdData() -> Data?{
        let context = LAContext()
        var error:NSError? = nil;
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            return context.evaluatedPolicyDomainState
        }
        print("errorMsg:" + self.errorMessageForFails(errorCode:(error?.code)! ))
        return nil
    }
    
    //MARK:error msg
    //reference:https://github.com/sriscode/FaceId-Authentication-IphoneX
    class func errorMessageForFails(errorCode: Int) -> String {
        
        var message = ""
        
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            message = "Authentication was not successful, because user failed to provide valid credentials"
            
        case LAError.appCancel.rawValue:
            message = "Authentication was canceled by application"
            
        case LAError.invalidContext.rawValue:
            message = "LAContext passed to this call has been previously invalidated"
            
        case LAError.notInteractive.rawValue:
            message = "Authentication failed, because it would require showing UI which has been forbidden by using interactionNotAllowed property"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Authentication could not start, because passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was canceled by system"
            
        case LAError.userCancel.rawValue:
            message = "Authentication was canceled by user"
            
        case LAError.userFallback.rawValue:
            message = "Authentication was canceled, because the user tapped the fallback button"
            
        case LAError.biometryNotAvailable.rawValue:
            message = "Authentication could not start, because biometry is not available on the device"
            
        case LAError.biometryLockout.rawValue:
            message = "Authentication was not successful, because there were too many failed biometry attempts and                          biometry is now locked"
            
        case LAError.biometryNotEnrolled.rawValue:
            message = "Authentication could not start, because biometric authentication is not enrolled"
            
        default:
            message = self.errorMessageForFailsDeprecatediniOS11(errorCode: errorCode)
        }
        
        return message
    }
    
    //reference:https://github.com/sriscode/FaceId-Authentication-IphoneX
    class func errorMessageForFailsDeprecatediniOS11(errorCode: Int) -> String {
        var message = ""
        if #available(iOS 11.0, macOS 10.13, *) {
            message = "unknown error"
        } else {
            switch errorCode {
            case LAError.touchIDLockout.rawValue:
                message = "Authentication was not successful, because there were too many failed Touch ID attempts and Touch ID is now locked. Passcode is required to unlock Touch ID"
                
            case LAError.touchIDNotAvailable.rawValue:
                message = "Authentication could not start, because Touch ID is not available on the device"
                
            case LAError.touchIDNotEnrolled.rawValue:
                message = "Authentication could not start, because Touch ID is not enrolled on the device"
            default :
                message = "unknown error"
            }
        }
        
        return message
    }
    
    class func isErrorTouchIDLockout()->Bool
    {
        let context = LAContext()
        var error:NSError?
        context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        guard error != nil else {
            return false
        }
        
        if error!.code == LAError.biometryLockout.rawValue {
            return true
        }
        else
        {
            return false
        }
    }
}
