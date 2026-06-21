namespace UISampleSpark.Core.Models.Data;
public interface IEmployee
{
    int Age { get; set; }
    string? Country { get; set; }
    Data.Department? Department { get; set; }
    int? DepartmentId { get; set; }
    int? ManagerId { get; set; }
    string Name { get; set; }
    string? ProfilePicture { get; set; }
    string? State { get; set; }
    Data.Gender Gender { get; set; }
}
