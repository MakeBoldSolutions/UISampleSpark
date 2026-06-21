namespace UISampleSpark.Core.Extensions;

/// <summary>
/// Extensions to string for parsing and manipulation
/// </summary>
public static class StringExtensions
{
    /// <summary>
    /// Gets the decimal from string.
    /// </summary>
    /// <param name="str">The string.</param>
    /// <param name="defaultValue">The default value.</param>
    /// <returns>System.Decimal.</returns>
    public static decimal GetDecimalFromString(this string? str, decimal defaultValue) =>
        decimal.TryParse(str, out decimal returnDecimal) ? returnDecimal : defaultValue;

    /// <summary>
    /// Gets the int from string.
    /// </summary>
    /// <param name="str">The string.</param>
    /// <param name="defaultValue">The default value.</param>
    /// <returns>System.Nullable&lt;System.Int32&gt;.</returns>
    public static int? GetIntFromString(this string? str, int? defaultValue) =>
        int.TryParse(str, out int returnInt) ? returnInt : defaultValue;

    /// <summary>
    /// Gets the int from string.
    /// </summary>
    /// <param name="str">The string.</param>
    /// <param name="defaultValue">The default value.</param>
    /// <returns>System.Int32.</returns>
    public static int GetIntFromString(this string? str, int defaultValue) =>
        int.TryParse(str, out int returnInt) ? returnInt : defaultValue;

    /// <summary>
    /// Indexes the of NTH.
    /// </summary>
    /// <param name="str">The string.</param>
    /// <param name="value">The value.</param>
    /// <param name="nth">The NTH.</param>
    /// <returns>System.Int32.</returns>
    /// <exception cref="ArgumentException">Can not find the zeroth index of substring in string. Must start with 1</exception>
    public static int IndexOfNth(this string? str, string? value, int nth = 1)
    {
        if (str is null || value is null)
            return 0;

        if (nth <= 0)
            throw new ArgumentException("Can not find the zeroth index of substring in string. Must start with 1", nameof(nth));

        int offset = str.IndexOf(value, StringComparison.Ordinal);

        for (int i = 1; i < nth; i++)
        {
            if (offset == -1)
                return -1;
            offset = str.IndexOf(value, offset + 1, StringComparison.Ordinal);
        }

        return offset;
    }

    /// <summary>
    /// Returns the leftmost characters from a string.
    /// </summary>
    /// <param name="str">The string.</param>
    /// <param name="length">The length.</param>
    /// <returns>System.String.</returns>
    /// <exception cref="ArgumentException">Length must be greater than zero</exception>
    public static string Left(this string? str, int length)
    {
        if (str is null)
            return string.Empty;

        if (length <= 0)
            throw new ArgumentException("Can return zero or less characters. Must start with 1", nameof(length));

        return str.Length <= length ? str : str[..length];
    }

    /// <summary>
    /// Returns the rightmost characters from a string.
    /// </summary>
    /// <param name="str">The string.</param>
    /// <param name="length">The length.</param>
    /// <returns>System.String.</returns>
    public static string Right(this string? str, int length)
    {
        if (string.IsNullOrEmpty(str))
            return string.Empty;

        return str.Length > length ? str[^length..] : str;
    }

    /// <summary>
    /// Extension Method for String to Trim and Check for null in a single function
    /// </summary>
    /// <param name="value">The String to be trimmed</param>
    /// <returns>Trimmed string or string.empty is the value was null</returns>
    public static string TrimIfNotNull(this string? value) =>
        value?.Trim() ?? string.Empty;

    /// <summary>
    /// Splits a string by a separator and converts each element to the specified type.
    /// Elements that cannot be converted are skipped and <paramref name="allConverted"/> is set to false.
    /// </summary>
    /// <typeparam name="T">The target type to convert elements to.</typeparam>
    /// <param name="value">The input string to split.</param>
    /// <param name="separator">The character used to separate elements.</param>
    /// <param name="allConverted">Output parameter indicating whether all conversions succeeded.</param>
    /// <returns>A list of successfully converted elements.</returns>
    public static List<T> SplitAndConvert<T>(this string value, char separator, out bool allConverted)
    {
        var results = new List<T>();
        allConverted = true;
        foreach (string item in value.Split(separator))
        {
            try
            {
                results.Add((T)Convert.ChangeType(item, typeof(T), System.Globalization.CultureInfo.InvariantCulture));
            }
            catch (InvalidCastException)
            {
                allConverted = false;
            }
            catch (FormatException)
            {
                allConverted = false;
            }
        }
        return results;
    }
}
