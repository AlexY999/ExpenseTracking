import UIKit

class BalanceView: UIView {
    let balanceLabel = UILabel()
    let balanceStackView = UIStackView()
    let addBalanceButton = UIButton(type: .system)
    let addTransactionButton = UIButton(type: .system)
    let transactionsTableView = UITableView()
    let bitcoinRateLabel = UILabel()

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

        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.text = "0 BTC"
        balanceLabel.font = UIFont.boldSystemFont(ofSize: 36)
        balanceLabel.textColor = .label
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceLabel.minimumScaleFactor = 0.5

        addBalanceButton.translatesAutoresizingMaskIntoConstraints = false
        addBalanceButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addBalanceButton.tintColor = .systemBlue

        balanceStackView.addArrangedSubview(balanceLabel)
        balanceStackView.addArrangedSubview(addBalanceButton)
        balanceStackView.translatesAutoresizingMaskIntoConstraints = false
        balanceStackView.axis = .horizontal
        balanceStackView.spacing = 10
        balanceStackView.alignment = .center
        balanceStackView.distribution = .equalSpacing
        addSubview(balanceStackView)

        addTransactionButton.translatesAutoresizingMaskIntoConstraints = false
        addTransactionButton.setTitle("Add Transaction", for: .normal)
        addTransactionButton.backgroundColor = .systemGreen
        addTransactionButton.setTitleColor(.white, for: .normal)
        addTransactionButton.layer.cornerRadius = 10
        addTransactionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addSubview(addTransactionButton)

        transactionsTableView.translatesAutoresizingMaskIntoConstraints = false
        transactionsTableView.backgroundColor = .systemGroupedBackground
        transactionsTableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: "TransactionCell")
        addSubview(transactionsTableView)

        bitcoinRateLabel.translatesAutoresizingMaskIntoConstraints = false
        bitcoinRateLabel.text = "1 BTC = 0 $"
        bitcoinRateLabel.font = UIFont.systemFont(ofSize: 16)
        bitcoinRateLabel.textColor = .secondaryLabel
        addSubview(bitcoinRateLabel)

        NSLayoutConstraint.activate([
            bitcoinRateLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            bitcoinRateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            balanceStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            balanceStackView.topAnchor.constraint(equalTo: bitcoinRateLabel.bottomAnchor, constant: 20),

            addTransactionButton.topAnchor.constraint(equalTo: balanceStackView.bottomAnchor, constant: 20),
            addTransactionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            addTransactionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            addTransactionButton.heightAnchor.constraint(equalToConstant: 44),

            transactionsTableView.topAnchor.constraint(equalTo: addTransactionButton.bottomAnchor, constant: 20),
            transactionsTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            transactionsTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            transactionsTableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
