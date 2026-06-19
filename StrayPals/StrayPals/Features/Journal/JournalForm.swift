//
//  JournalForm.swift
//  StrayPals (MaoWo)
//
//  認養日記表單共用的小工具（欄位標題、輸入框、文字區、列容器、晃動提示）。
//

import UIKit

// MARK: - JournalForm

enum JournalForm {

    /// 區段標題。
    static func label(_ text: String) -> UILabel {
        UILabel(text: text, font: .systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabel)
    }

    /// 單行輸入框（卡片底色 + 圓角）。
    static func textField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 16)
        field.backgroundColor = .appCard
        field.borderStyle = .none
        field.layer.cornerRadius = 12
        field.layer.cornerCurve = .continuous
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.rightViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return field
    }

    /// 多行文字區。
    static func textView() -> UITextView {
        let view = UITextView()
        view.font = .systemFont(ofSize: 16)
        view.backgroundColor = .appCard
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        view.isScrollEnabled = false
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 90).isActive = true
        return view
    }

    /// 標題 + 控制項（水平排列）。
    static func row(_ title: String, _ control: UIView) -> UIStackView {
        let titleLabel = UILabel(text: title, font: .systemFont(ofSize: 15), color: .label)
        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        return row
    }

    /// 必填欄位未填時的左右晃動提示。
    static func shake(_ view: UIView) {
        HapticsManager.shared.notify(.error)
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-8, 8, -6, 6, -3, 3, 0]
        view.layer.add(animation, forKey: "shake")
        view.becomeFirstResponder()
    }
}
