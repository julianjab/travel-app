const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// "3 ene 2024" — no locale data required, works on all platforms.
String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "3 ene 2024 – 10 ene 2024"
String formatDateRange(DateTime start, DateTime end) =>
    '${formatShortDate(start)} – ${formatShortDate(end)}';
