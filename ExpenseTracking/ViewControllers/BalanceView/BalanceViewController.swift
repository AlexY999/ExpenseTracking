import UIKit
import CoreData

class BalanceViewController: UIViewController, BalanceViewControllerDelegate {
    
    private let balanceLabel = UILabel()
    private let balanceStackView = UIStackView()
    private let addBalanceButton = UIButton(type: .system)
    private let addTransactionButton = UIButton(type: .system)
    private let transactionsTableView = UITableView()
    private let bitcoinRateLabel = UILabel()

    private let context = CoreDataStack.shared.context
    private var transactions: [Transaction] = []
    private var currentPage = 0
    private let transactionsPerPage = 20
    private var isFetchingMoreTransactions = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupUI()
        fetchData()
        updateBitcoinRate()
    }
    
    func didUpdateBalance() {
        fetchData()
    }
    
    func updateBitcoinRate() {
        BitcoinRateService.shared.fetchRateIfNeeded { [weak self] rate in
            DispatchQueue.main.async {
                self?.bitcoinRateLabel.text = "1 BTC = \(rate ?? "N/A") $"
            }
        }
    }
    
    private func fetchData() {
        currentPage = 0
        transactions.removeAll()
        fetchTransactions()
        transactionsTableView.reloadData()
        updateBalanceLabel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollToTopTapped()
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.text = "0 BTC"
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 36)
        balanceLabel.textColor = .label
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.5
        
        addBalanceButton.translatesAutoresizingMaskIntoConstraints = false
        addBalanceButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addBalanceButton.tintColor = .systemBlue
        addBalanceButton.addTarget(self, action: #selector(addBalanceTapped), for: .touchUpInside)
        
        balanceStackView.addArrangedSubview(balanceLabel)
        balanceStackView.addArrangedSubview(addBalanceButton)
        balanceStackView.translatesAutoresizingMaskIntoConstraints = false
        balanceStackView.axis = .horizontal
        balanceStackView.spacing = 10
        balanceStackView.alignment = .center
        balanceStackView.distribution = .equalSpacing
        view.addSubview(balanceStackView)
        
        addTransactionButton.translatesAutoresizingMaskIntoConstraints = false
        addTransactionButton.setTitle("Add Transaction", for: .normal)
        addTransactionButton.backgroundColor = .systemGreen
        addTransactionButton.setTitleColor(.white, for: .normal)
        addTransactionButton.layer.cornerRadius = 10
        addTransactionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addTransactionButton.addTarget(self, action: #selector(addTransactionTapped), for: .touchUpInside)
        view.addSubview(addTransactionButton)
        
        transactionsTableView.translatesAutoresizingMaskIntoConstraints = false
        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self
        transactionsTableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        transactionsTableView.backgroundColor = .systemGroupedBackground
        view.addSubview(transactionsTableView)
        
        bitcoinRateLabel.translatesAutoresizingMaskIntoConstraints = false
        bitcoinRateLabel.text = "1 BTC = 0 $"
        bitcoinRateLabel.font = UIFont.systemFont(ofSize: 16)
        bitcoinRateLabel.textColor = .secondaryLabel
        view.addSubview(bitcoinRateLabel)
        
        NSLayoutConstraint.activate([
            bitcoinRateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            bitcoinRateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            balanceStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            balanceStackView.topAnchor.constraint(equalTo: bitcoinRateLabel.bottomAnchor, constant: 20),
            
            addTransactionButton.topAnchor.constraint(equalTo: balanceStackView.bottomAnchor, constant: 20),
            addTransactionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addTransactionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTransactionButton.heightAnchor.constraint(equalToConstant: 44),
            
            transactionsTableView.topAnchor.constraint(equalTo: addTransactionButton.bottomAnchor, constant: 20),
            transactionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transactionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            transactionsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
            balanceLabel.text = "\(wallet.balance ?? 0) BTC"
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
        currentPage += 1;
        fetchTransactions()
        transactionsTableView.reloadData()
    }
    
    private func scrollToTopTapped() {
        let numberOfSections = transactionsTableView.numberOfSections
        if numberOfSections > 0 {
            let numberOfRows = transactionsTableView.numberOfRows(inSection: 0)
            if numberOfRows > 0 {
                let topIndexPath = IndexPath(row: 0, section: 0)
                transactionsTableView.scrollToRow(at: topIndexPath, at: .top, animated: true)
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
