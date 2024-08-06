import Foundation
import CoreData

extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var date: Date?
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var category: String?

}

extension Transaction: Identifiable {

}
