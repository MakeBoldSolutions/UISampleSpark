namespace UISampleSpark.Core.Models.Data;

public interface IDepartment
{
    string Description { get; set; }
    ICollection<Data.Employee> Employees { get; set; }
    string Name { get; set; }
}
