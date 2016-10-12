//
//  UIUtils.swift
//  ios-video-frames
//

import Foundation


class UIUtils {
    
    static let instance = UIUtils()
    var progressHud : MBProgressHUD?
    
    //MARK: - MBProgressHud
    func showPorgressHudWithMessage(_ message : String, view : UIView) {
        self.progressHud = MBProgressHUD.showAdded(to: view, animated: true)
        self.progressHud?.labelText = message;
    }
    
    func hideProgressHud() {
        DispatchQueue.main.async {
            if self.progressHud != nil && !self.progressHud!.isHidden {
                self.progressHud!.hide(true)
            }
        }
        
    }
}
