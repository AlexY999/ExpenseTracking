import UIKit
import CoreData

class AddTransactionViewController: UIViewController {
    weak var delegate: BalanceViewControllerDelegate?

    private let customView = AddTransactionView()
    private let context = CoreDataStack.shared.context

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(customView)
        customView.frame = view.bounds
        customView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        customView.backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        customView.addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        customView.categoryPickerView.delegate = self
        customView.categoryPickerView.dataSource = self
    }

    @objc private func addButtonTapped() {
        guard let amountText = customView.amountTextField.text, !amountText.isEmpty else {
            showAlert(title: "Error", message: "Please enter an amount")
            return
        }

        let amount = NSDecimalNumber(string: amountText)
        if amount == NSDecimalNumber.notANumber {
            showAlert(title: "Invalid Amount", message: "Please enter a valid number")
            return
        }

        let selectedCategoryIndex = customView.categoryPickerView.selectedRow(inComponent: 0)
        let selectedCategory = customView.categories[selectedCategoryIndex]

        updateWalletBalance(amount: amount)
        saveTransaction(amount: amount, category: selectedCategory)
    }

    private func updateWalletBalance(amount: NSDecimalNumber) {
        let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()

        do {
            let wallets = try context.fetch(fetchRequest)
            if let wallet = wallets.first {
                wallet.balance = wallet.balance?.subtracting(amount)
                try context.save()
                delegate?.didUpdateBalance()
            } else {
                showAlert(title: "Error", message: "No wallet found")
            }
        } catch {
            showAlert(title: "Error", message: "Failed to update wallet balance: \(error.localizedDescription)")
        }
    }

    private func saveTransaction(amount: NSDecimalNumber, category: String) {
        let transaction = Transaction(context: context)
        transaction.amount = amount
        transaction.category = category
        transaction.date = Date()

        do {
            try context.save()
            navigationController?.popViewController(animated: true)
        } catch {
            showAlert(title: "Error", message: "Failed to save transaction: \(error.localizedDescription)")
        }
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource

extension AddTransactionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return customView.categories.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return customView.categories[row]
    }
}
