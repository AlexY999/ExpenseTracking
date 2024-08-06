import UIKit
import CoreData

class BalanceViewController: UIViewController, BalanceViewControllerDelegate {
    private let customView = BalanceView()

    private let context = CoreDataStack.shared.context
    private var transactions: [Transaction] = []
    private var currentPage = 0
    private let transactionsPerPage = 20
    private var isFetchingMoreTransactions = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(customView)
        customView.frame = view.bounds
        customView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        customView.addBalanceButton.addTarget(self, action: #selector(addBalanceTapped), for: .touchUpInside)
        customView.addTransactionButton.addTarget(self, action: #selector(addTransactionTapped), for: .touchUpInside)
        customView.transactionsTableView.delegate = self
        customView.transactionsTableView.dataSource = self

        fetchData()
        updateBitcoinRate()
    }

    func didUpdateBalance() {
        fetchData()
    }

    func updateBitcoinRate() {
        BitcoinRateService.shared.fetchRateIfNeeded { [weak self] rate in
            DispatchQueue.main.async {
                self?.customView.bitcoinRateLabel.text = "1 BTC = \(rate ?? "N/A") $"
            }
        }
    }

    private func fetchData() {
        currentPage = 0
        transactions.removeAll()
        fetchTransactions()
        customView.transactionsTableView.reloadData()
        updateBalanceLabel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToTopTapped()
        }
    }

    @objc private func addBalanceTapped() {
        let alertController = UIAlertController(title: "Add Balance", message: "Enter the amount to add", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let amountText = alertController.textFields?.first?.text {
                let amount = NSDecimalNumber(string: amountText)
                if amount != NSDecimalNumber.notANumber {
                    self?.updateBalance(by: amount)
                } else {
                    let errorAlert = UIAlertController(title: "Invalid Input", message: "Please enter a valid amount.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(errorAlert, animated: true, completion: nil)
                }
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    @objc private func addTransactionTapped() {
        let addTransactionVC = AddTransactionViewController()
        addTransactionVC.delegate = self
        navigationController?.pushViewController(addTransactionVC, animated: true)
    }

    private func updateBalance(by amount: NSDecimalNumber) {
        let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()
        if let wallets = try? context.fetch(fetchRequest), let wallet = wallets.first {
            wallet.balance = wallet.balance?.adding(amount)
        } else {
            let wallet = Wallet(context: context)
            wallet.balance = amount
        }

        let transaction = Transaction(context: context)
        transaction.amount = amount
        transaction.category = "add_balance"
        transaction.date = Date()

        do {
            fetchData()
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    private func updateBalanceLabel() {
        let fetchRequest: NSFetchRequest<Wallet> = Wallet.fetchRequest()
        if let wallets = try? context.fetch(fetchRequest), let wallet = wallets.first {
            customView.balanceLabel.text = "\(wallet.balance ?? 0) BTC"
        }
    }

    private func fetchTransactions() {
        isFetchingMoreTransactions = true
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = transactionsPerPage
        fetchRequest.fetchOffset = currentPage * transactionsPerPage

        do {
            let fetchedTransactions = try context.fetch(fetchRequest)
            isFetchingMoreTransactions = fetchedTransactions.isEmpty
            transactions.append(contentsOf: fetchedTransactions)
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
    }

    private func fetchMoreTransactions() {
        currentPage += 1
        fetchTransactions()
        customView.transactionsTableView.reloadData()
    }

    private func scrollToTopTapped() {
        let numberOfSections = customView.transactionsTableView.numberOfSections
        if numberOfSections > 0 {
            let numberOfRows = customView.transactionsTableView.numberOfRows(inSection: 0)
            if numberOfRows > 0 {
                let topIndexPath = IndexPath(row: 0, section: 0)
                customView.transactionsTableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BalanceViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return transactionsGroupedByDay().count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let groupedTransactions = transactionsGroupedByDay()
        return groupedTransactions[section].value.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let groupedTransactions = transactionsGroupedByDay()
        let date = groupedTransactions[section].key
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath) as! TransactionTableViewCell
        let groupedTransactions = transactionsGroupedByDay()
        let transaction = groupedTransactions[indexPath.section].value[indexPath.row]

        cell.configure(with: transaction)
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSectionIndex = tableView.numberOfSections - 1
        let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1

        if indexPath.section == lastSectionIndex && indexPath.row == lastRowIndex && !isFetchingMoreTransactions {
            fetchMoreTransactions()
        }
    }

    private func transactionsGroupedByDay() -> [(key: Date, value: [Transaction])] {
        var groupedTransactions = [Date: [Transaction]]()
        let calendar = Calendar.current

        for transaction in transactions {
            guard let transactionDate = transaction.date else {
                continue
            }
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: transactionDate)
            if let date = calendar.date(from: dateComponents) {
                if groupedTransactions[date] == nil {
                    groupedTransactions[date] = [transaction]
                } else {
                    groupedTransactions[date]?.append(transaction)
                }
            }
        }

        for (date, transactions) in groupedTransactions {
            groupedTransactions[date] = transactions.sorted(by: { $0.date! > $1.date! })
        }

        return groupedTransactions.sorted(by: { $0.key > $1.key })
    }
}
