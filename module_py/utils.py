def calc_perc(num, den, decimals=1):
    try:
        return round((num / den) * 100, decimals)
    except ZeroDivisionError:
        return 0.0


