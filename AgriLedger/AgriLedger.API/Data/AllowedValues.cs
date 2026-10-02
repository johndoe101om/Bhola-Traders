namespace AgriLedger.API.Data;

public static class AllowedValues
{
    public static readonly string[] PartyTypes = ["farmer", "supplier", "customer"];
    public static readonly string[] TxnTypes = ["purchase", "sale", "cash_in", "cash_out"];
    public static readonly string[] Directions = ["in", "out"];
    public static readonly string[] PaymentModes = ["cash", "upi", "credit"];
    public static readonly string[] BagMovements = ["given", "returned"];
    public static readonly string[] Commodities = ["rice", "wheat", "maize", "jute", "moong_dal", "mung_daal"];

    // Maps txn_type → direction (relative to our business)
    public static string DirectionForTxnType(string txnType) => txnType switch
    {
        "purchase" => "out",   // we pay out money to buy grain
        "cash_out" => "out",   // we give cash
        "sale" => "in",    // we receive money from selling
        "cash_in" => "in",    // we receive cash
        _ => "in"
    };

    public static readonly string[] EmployeeTypes = ["labour", "driver", "supervisor", "other"];
    public static readonly string[] AttendanceStatuses = ["present", "absent", "half_day", "overtime", "holiday"];
    public static readonly string[] EmployeePaymentModes = ["cash", "upi", "bank_transfer"];
    public static readonly string[] EmployeePaymentTypes = ["wage", "advance", "bonus", "deduction", "settlement"];
}
