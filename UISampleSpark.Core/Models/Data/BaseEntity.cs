namespace UISampleSpark.Core.Models.Data;
public enum Gender
{
    Male,
    Female
}

public abstract class BaseEntity
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string CreatedBy { get; set; }
    [Required]
    public DateTime CreatedDate { get; set; }
    [Required]
    public string LastUpdatedBy { get; set; }
    [Required]
    public DateTime LastUpdatedDate { get; set; }

    public BaseEntity()
    {
        CreatedBy = string.Empty;
        LastUpdatedBy = string.Empty;
        CreatedDate = DateTime.Now;
        LastUpdatedDate = DateTime.Now;
    }
}
