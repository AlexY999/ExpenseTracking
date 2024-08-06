import UIKit
import CoreData

class AddTransactionViewController: UIViewController {
    weak var delegate: BalanceViewControllerDelegate?

    private let amountTextField = UITextField()
    private let categoryPickerView = UIPickerView()
    private let addButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)

    private let categories = ["groceries", "taxi", "electronics", "restaurant", "other"]

    private let context = CoreDataStack.shared.context

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .systemBlue
        view.addSubview(backButton)

        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.placeholder = "Enter amount"
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .roundedRect
        amountTextField.layer.borderColor = UIColor.systemGray.cgColor
        amountTextField.layer.borderWidth = 1.0
        amountTextField.layer.cornerRadius = 8.0
        view.addSubview(amountTextField)

        categoryPickerView.translatesAutoresizingMaskIntoConstraints = false
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        categoryPickerView.layer.borderColor = UIColor.systemGray.cgColor
        categoryPickerView.layer.borderWidth = 1.0
        categoryPickerView.layer.cornerRadius = 8.0
        view.addSubview(categoryPickerView)

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = .systemBlue
        addButton.layer.cornerRadius = 8.0
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            amountTextField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20),
            amountTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            amountTextField.heightAnchor.constraint(equalToConstant: 44),

            categoryPickerView.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 20),
            categoryPickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categoryPickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            categoryPickerView.heightAnchor.constraint(equalToConstant: 200),

            addButton.topAnchor.constraint(equalTo: categoryPickerView.bottomAnchor, constant: 20),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    @objc private func addButtonTapped() {
        guard let amountText = amountTextField.text, !amountText.isEmpty else {
            showAlert(title: "Error", message: "Please enter an amount")
            return
        }

        let amount = NSDecimalNumber(string: amountText)
        if amount == NSDecimalNumber.notANumber {
            showAlert(title: "Invalid Amount", message: "Please enter a valid number")
            return
        }

        let selectedCategoryIndex = categoryPickerView.selectedRow(inComponent: 0)
        let selectedCategory = categories[selectedCategoryIndex]

        let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()

        do {
            let wallets = try context.fetch(fetchRequest)
            if let wallet = wallets.first {
                wallet.balance = wallet.balance?.subtracting(amount)

                let transaction = Transaction(context: context)
                transaction.amount = amount
                transaction.category = selectedCategory
                transaction.date = Date()

                delegate?.didUpdateBalance()
                try context.save()
                navigationController?.popViewController(animated: true)
            } else {
                showAlert(title: "Error", message: "No wallet found")
            }
        } catch {
            showAlert(title: "Error", message: "Failed to save transaction: \(error.localizedDescription)")
        }
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource

extension AddTransactionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
}
