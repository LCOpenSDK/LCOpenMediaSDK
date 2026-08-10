//
//  LCDeviceListPresenter.swift
//  LeChangeDemo
//
//  Created by yyg on 2022/9/24.
//  Copyright © 2022 Imou. All rights reserved.
//

import LCOpenSDKDynamic
import LCNetworkModule
import LCNewLivePreviewModule
import LCOpenMediaSDK

@objcMembers class LCDeviceListPresenter : LCBasicPresenter {
    /// 开发平台设备
    var openDevices = [LCDeviceInfo]() {
        didSet {
            self.p2pPredrilling()
            self.mtsPreKeepalive()
        }
    }
    /// containter
    weak var listContainer: LCDeviceListViewController?
    
//    lazy var livePreviewVC: LCNewLivePreviewViewController = {
//        return LCNewLivePreviewViewController()
//    }()
    
    /// 当前是否在网络请求中
    var isRefreshing: Bool = false
    /// p2p预打洞设备
    var p2pDevices: Set<String> = Set<String>()
    /// p2p预打洞设备
    var mtsKeepDevices: Set<String> = Set<String>()
    
    var pageIndex = 1
    let pageSize = 10
    /// 上一页平台返回的原始设备数量（未过滤），用于判断是否还有下一页
    var lastPageRawCount = 0

    deinit {
        NSLog(" 💔💔💔 %@ dealloced 💔💔💔", NSStringFromClass(self.classForCoder))
    }
    
    func initSDK() {
        print("\(LCApplicationDataManager.sdkHost())" + "\(LCApplicationDataManager.sdkHost())")
        let param = LCOpenSDK_ApiParam()
        param.procotol = LCApplicationDataManager.hostApi().contains("https") ? .PROCOTOL_TYPE_HTTPS : .PROCOTOL_TYPE_HTTP
        param.addr = LCApplicationDataManager.sdkHost()
        param.port = LCApplicationDataManager.sdkPort()
        param.token = LCApplicationDataManager.token()
        let _ = LCOpenSDK_Api(openApi: param)
        print(" \(NSStringFromClass(self.classForCoder)):: Init open api: \(param.addr)")
    }
    
    func initSDKLog() {
        let logInfo = LCOpenSDK_LogInfo()
        logInfo.levelType = LogLevelTypeALL
        LCOpenSDK_Log.shareInstance().setLogInfo(logInfo)
    }
    
    func refreshData() {
        if self.isRefreshing {
            self.listContainer?.deviceListView.mj_header?.endRefreshing()
            return
        }
        
        self.isRefreshing = true
        self.pageIndex = 1
        LCDeviceManagerInterface.queryDeviceDetailPage(pageIndex, pageSize: pageSize) {[weak self] devices in
            guard let self = self else { return }
            self.openDevices.removeAll()
            let ds = (devices as? [LCDeviceInfo]) ?? []
            // 分页条件用平台原始返回数量判断
            self.lastPageRawCount = ds.count
            //只显示NVR与通道数大于等于1
            let temp = ds.filter { device in
                return (device.channels.count == 0 && device.catalog.uppercased() != "NVR") ? false : true
            }
            self.openDevices.append(contentsOf: temp)
            self.listContainer?.deviceListView.reloadData()
            LCProgressHUD.hideAllHuds(nil)
            self.listContainer?.deviceListView.mj_header?.endRefreshing()
            self.listContainer?.deviceListView.mj_footer?.resetNoMoreData()
            self.isRefreshing = false
        } failure: {[weak self] error in
            LCProgressHUD.hideAllHuds(nil)
            self?.listContainer?.deviceListView.mj_header?.endRefreshing()
            self?.isRefreshing = false
            LCProgressHUD.showMsg(error.errorMessage)
        }
    }

    func loadMoreData() {
        if self.isRefreshing {
            self.listContainer?.deviceListView.mj_footer?.endRefreshing()
            return
        }
        
        // 用平台上一页原始返回数量判断是否还有下一页，不用展示列表数量
        if self.lastPageRawCount < self.pageSize {
            self.listContainer?.deviceListView.mj_footer?.endRefreshingWithNoMoreData()
            return
        }
        
        self.isRefreshing = true
        let nextPage = self.pageIndex + 1
        LCDeviceManagerInterface.queryDeviceDetailPage(nextPage, pageSize: pageSize) { [weak self] devices in
            guard let self = self else { return }
            let ds = (devices as? [LCDeviceInfo]) ?? []
            self.lastPageRawCount = ds.count
            self.pageIndex = nextPage
            //只显示NVR与通道数大于等于1
            let temp = ds.filter { device in
                return (device.channels.count == 0 && device.catalog.uppercased() != "NVR") ? false : true
            }
            self.openDevices.append(contentsOf: temp)
            self.listContainer?.deviceListView.reloadData()
            LCProgressHUD.hideAllHuds(nil)
            if self.lastPageRawCount < self.pageSize {
                self.listContainer?.deviceListView.mj_footer?.endRefreshingWithNoMoreData()
            } else {
                self.listContainer?.deviceListView.mj_footer?.endRefreshing()
            }
            self.isRefreshing = false
        } failure: {[weak self] error in
            LCProgressHUD.hideAllHuds(nil)
            self?.listContainer?.deviceListView.mj_footer?.endRefreshing()
            self?.isRefreshing = false
            LCProgressHUD.showMsg(error.errorMessage)
        }
    }
    
    func getTableViewCellHeight(info: LCDeviceInfo) -> CGFloat {
        if info.channels.count > 1 {
            //多通道设备
            if info.channels.count <= 2 {
                return 200.0
            } else {
                return 315.0
            }
        } else {
            //单通道设备
            return 260.0
        }
    }
    
    // p2p预打洞
    func p2pPredrilling()  {
        var jsonArray = [LCOpenSDK_P2PDeviceInfo]()
        self.openDevices.forEach {[weak self] device in
            if self?.p2pDevices.contains(device.deviceId) == false && device.status == "online" {
                let info = LCOpenSDK_P2PDeviceInfo()
                info.playToken = device.playTokenV2
                info.did = device.deviceId
                jsonArray.append(info)
                self?.p2pDevices.insert(device.deviceId)
            }
        }
        if jsonArray.count > 0 {
            LCOpenSDK_LoginManager.shareMyInstance().addDevices(LCApplicationDataManager.token(), devices: jsonArray)
        }
    }
    
    // MTS预连接
    func mtsPreKeepalive()  {
        var datas = Array<Dictionary<String, String>>()
        self.openDevices.forEach {[weak self] device in
            if self?.mtsKeepDevices.contains(device.deviceId) == false && device.status == "online" {
                datas.append(["playtoken":device.playTokenV2, "deviceId":device.deviceId, "productId":device.productId])
                self?.mtsKeepDevices.insert(device.deviceId)
            }
        }
        
        LCOpenSDK_Utils.mtsPreKeepalive(datas, token: LCApplicationDataManager.token())
    }
}

extension LCDeviceListPresenter: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.openDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LCDeviceListCell", for: indexPath)
        (cell as? LCDeviceListCell)?.deviceInfo = self.openDevices[indexPath.row]
        (cell as? LCDeviceListCell)?.resultBlock = {[weak self] info, channelIndex, index in
            LCNewDeviceVideoManager.shareInstance().reset()
            LCNewDeviceVideoManager.shareInstance().currentDevice = info
            /// 多目相机
            if (info.channels.count > 0) {
                if (info.multiFlag == true) {
                    LCNewDeviceVideoManager.shareInstance().mainChannelInfo = info.channels[0]
                    LCNewDeviceVideoManager.shareInstance().displayChannelID = info.channels[channelIndex].channelId
                } else {
                    LCNewDeviceVideoManager.shareInstance().mainChannelInfo = info.channels[channelIndex]
                    LCNewDeviceVideoManager.shareInstance().displayChannelID = info.channels[channelIndex].channelId
                }
            }
            if index == 0 {
                if info.catalog.uppercased() == "NVR" &&  LCNewDeviceVideoManager.shareInstance().mainChannelInfo.status != "online" {
                    return
                }
                if info.catalog.uppercased() == "IPC" && info.status != "online" {
                    return
                }
                let vc = LCNewLivePreviewViewController()
                vc.isFirstIntoVC = true
                self?.listContainer?.navigationController?.pushViewController(vc, animated: true)
            } else if index == 1 {
                var channleId = ""
                if self?.openDevices[indexPath.row].channels.count ?? -1 > channelIndex {
                    channleId = self?.openDevices[indexPath.row].channels[channelIndex].channelId ?? "-1"
                }
                self?.listContainer?.navigationController?.push(toDeviceSettingPage: self?.openDevices[indexPath.row] ?? LCDeviceInfo(), selectedChannelId:channleId)
            } else if index == 2 {
                let deviceJson = info.transfromToJson()
                let userInfo = ["deviceJson": deviceJson, "index":channelIndex] as [String : Any]
                self?.listContainer?.navigationController?.push(toMessagePage: userInfo)
            } else if index == 3 {
                NSLog("模拟接听");
                LCAlertView.lc_ShowAlert(title: "提示", detail: "请先按下设备上的【呼叫】按钮，听到“正在呼叫”提示音后，再在30秒内按App界面上的【模拟接听呼叫】按钮", confirmString: "开始模拟", cancelString: "取消") { isConfirmSelected in
                    if isConfirmSelected {
                        //开始模拟呼叫
                        LCPermissionHelper.requestCameraAndAudioPermission { granted in
                            if granted {
                                let vc = LCVisualTalkViewController()
                                vc.intercomStatus = .ringing
//                                vc.isNeedSoftEncode = false
                                vc.modalPresentationStyle = .fullScreen
                                self?.listContainer?.present(vc, animated: true)
                            }
                        }
                    }
                }
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.getTableViewCellHeight(info: self.openDevices[indexPath.row])
    }
}
