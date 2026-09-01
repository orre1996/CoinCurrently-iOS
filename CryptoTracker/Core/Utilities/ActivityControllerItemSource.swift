//
//  ActivityControllerItemSource.swift
//  CoinCurrently
//
//  Created by Oscar Berggren on 2024-09-11.
//

import UIKit
import LinkPresentation

class ActivityControllerItemSource: NSObject, UIActivityItemSource {
    var title: String
    var text: String

    init(title: String, text: String) {
        self.title = title
        self.text = text
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let appIcon = UIImage(named: "AppIconRaw")
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.iconProvider = NSItemProvider(object: appIcon ?? UIImage())
        metadata.originalURL = URL(fileURLWithPath: text)
        return metadata
    }
}
