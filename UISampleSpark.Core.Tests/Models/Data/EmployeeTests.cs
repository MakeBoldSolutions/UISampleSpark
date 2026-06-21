namespace UISampleSpark.Core.Tests.Models.Data;

[TestClass]
public class EmployeeTests
{
    [TestMethod]
    public void Employee_Test()
    {
        // Arrange
        Core.Models.Data.Employee employee = new Core.Models.Data.Employee
        {
            Age = 20,
            Country = "USA",
            DepartmentId = 1,
            Id = 1,
            Name = "Test Employee",
            State = "TX",
            Department = new Core.Models.Data.Department()
            {
                Id = 1,
                Name = "Test",
                Description = "Test"
            }
        };
        // Act
        employee.Age = 21;

        // Assert
        Assert.IsNotNull(employee);
    }
}


