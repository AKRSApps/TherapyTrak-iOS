//
//  TherapySessionTableViewCell.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/16/22.
//

import UIKit

class TherapySessionTableViewCell: UITableViewCell {

    @IBOutlet weak var numberOfRepsLabel: UILabel!
    @IBOutlet weak var avgHeartRateLabel: UILabel!
    @IBOutlet weak var stretchTypeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
