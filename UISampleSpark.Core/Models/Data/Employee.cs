using System.ComponentModel.DataAnnotations.Schema;

namespace UISampleSpark.Core.Models.Data;

public class Employee : Data.BaseEntity, Data.IEmployee
{
    /// <summary>
    /// Gets or sets the name.
    /// </summary>
    public required string Name { get; set; }

    /// <summary>
    /// Gets or sets the age.
    /// </summary>
    public int Age { get; set; }

    /// <summary>
    /// Gets or sets the country.
    /// </summary>
    public string? Country { get; set; }

    /// <summary>
    /// Gets or sets the state.
    /// </summary>
    public string? State { get; set; }

    /// <summary>
    /// Gets or sets the department identifier.
    /// </summary>
    public int? DepartmentId { get; set; }

    /// <summary>
    /// Gets or sets the department navigation property.
    /// </summary>
    [ForeignKey(nameof(DepartmentId))]
    public Data.Department? Department { get; set; }

    /// <summary>
    /// Gets or sets the employee manager identifier.
    /// </summary>
    public int? ManagerId { get; set; }

    /// <summary>
    /// Gets or sets the profile picture path.
    /// </summary>
    public string ProfilePicture { get; set; } = "default.jpg";

    /// <summary>
    /// Gets or sets the employee gender.
    /// </summary>
    public Data.Gender Gender { get; set; }
}
