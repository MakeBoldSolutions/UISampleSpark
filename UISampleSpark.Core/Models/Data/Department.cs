namespace UISampleSpark.Core.Models.Data;

/// <summary>
/// Department entity
/// </summary>
public class Department : Data.BaseEntity, Data.IDepartment
{
    /// <summary>
    /// Gets or sets the department name.
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// Gets or sets the department description.
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the collection of employees in this department.
    /// </summary>
    public ICollection<Data.Employee> Employees { get; set; } = [];
}
