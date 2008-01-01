def sql_concat(*args)
  SQLITE ? args.join(' || ') : "CONCAT(#{args.join(', ')})"
end

def sql_lcase(expr)
  SQLITE ? "LOWER(#{expr})" : "LCASE(#{expr})"
end

def sql_year(expr)
  SQLITE ? "CAST(STRFTIME('%y', #{expr}) as 'INTEGER')" : "YEAR(#{expr})"
end

def sql_month(expr)
  SQLITE ? "CAST(STRFTIME('%m', #{expr}) as 'INTEGER')" : "MONTH(#{expr})"
end

def sql_day(expr)
  SQLITE ? "CAST(STRFTIME('%d', #{expr}) as 'INTEGER')" : "DAY(#{expr})"
end