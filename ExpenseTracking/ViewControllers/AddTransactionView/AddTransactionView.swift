import UIKit

class AddTransactionView: UIView {
    let amountTextField = UITextField()
    let categoryPickerView = UIPickerView()
    let addButton = UIButton(type: .system)
    let backButton = UIButton(type: .system)

    let categories = ["groceries", "taxi", "electronics", "restaurant", "other"]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .white

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .systemBlue
        addSubview(backButton)

        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.placeholder = "Enter amount"
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .roundedRect
        amountTextField.layer.borderColor = UIColor.systemGray.cgColor
        amountTextField.layer.borderWidth = 1.0
        amountTextField.layer.cornerRadius = 8.0
        addSubview(amountTextField)

        categoryPickerView.translatesAutoresizingMaskIntoConstraints = false
        categoryPickerView.layer.borderColor = UIColor.systemGray.cgColor
        categoryPickerView.layer.borderWidth = 1.0
        categoryPickerView.layer.cornerRadius = 8.0
        addSubview(categoryPickerView)

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 8.0
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addSubview(addButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            amountTextField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            amountTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            amountTextField.heightAnchor.constraint(equalToConstant: 44),

            categoryPickerView.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 20),
            categoryPickerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            categoryPickerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            categoryPickerView.heightAnchor.constraint(equalToConstant: 200),

            addButton.topAnchor.constraint(equalTo: categoryPickerView.bottomAnchor, constant: 20),
            addButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
