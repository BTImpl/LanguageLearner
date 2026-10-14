/// Whether [a] and [b] fall on the same calendar day (in their own time zone).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
