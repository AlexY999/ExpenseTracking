import UIKit

class TransactionTableViewCell: UITableViewCell {
    private let categoryIndicator = UIView()
    private let dateLabel = UILabel()
    private let amountLabel = UILabel()
    private let categoryLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        categoryIndicator.translatesAutoresizingMaskIntoConstraints = false
        categoryIndicator.layer.cornerRadius = 5
        contentView.addSubview(categoryIndicator)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 14)
        contentView.addSubview(dateLabel)

        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = .boldSystemFont(ofSize: 16)
        contentView.addSubview(amountLabel)

        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = .systemFont(ofSize: 14)
        contentView.addSubview(categoryLabel)

        NSLayoutConstraint.activate([
            categoryIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            categoryIndicator.widthAnchor.constraint(equalToConstant: 10),
            categoryIndicator.heightAnchor.constraint(equalToConstant: 10),

            dateLabel.leadingAnchor.constraint(equalTo: categoryIndicator.trailingAnchor, constant: 12),
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            amountLabel.leadingAnchor.constraint(equalTo: categoryIndicator.trailingAnchor, constant: 12),
            amountLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with transaction: Transaction) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        dateLabel.text = dateFormatter.string(from: transaction.date ?? Date())
        amountLabel.text = "\(transaction.amount ?? 0) BTC"
        categoryLabel.text = transaction.category ?? "-"

        if transaction.category == "add_balance" {
            categoryIndicator.backgroundColor = .green
        } else {
            categoryIndicator.backgroundColor = .red
        }
    }
}
