namespace UISampleSpark.Core.Extensions;

/// <summary>
/// ENUM Extension Methods
/// </summary>
public static class EnumExtension
{
    /// <summary>
    /// Converts to Description String.
    /// </summary>
    /// <param name="e">The enum value.</param>
    /// <returns>The <see cref="DisplayAttribute.Description"/>, or the value name when none is set.</returns>
    public static string GetDescription(this Enum e)
    {
        if (e == null)
            return string.Empty;

        FieldInfo? fieldInfo = e.GetType().GetField(e.ToString());

        if (fieldInfo?.GetCustomAttributes(typeof(DisplayAttribute), false) is not DisplayAttribute[] descriptionAttributes
            || descriptionAttributes.Length == 0)
            return e.ToString();

        return descriptionAttributes[0].Description;
    }
}
