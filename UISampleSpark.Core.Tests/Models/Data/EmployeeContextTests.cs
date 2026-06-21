
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace UISampleSpark.Core.Tests.Models.Data;
[TestClass]
public class EmployeeContextTests
{
    [TestMethod]
    public async Task EmployeeContext_ExpectedBehaviorAsync()
    {
        // Arrange
        DbContextOptions<Core.Models.Data.EmployeeContext> options = new DbContextOptionsBuilder<Core.Models.Data.EmployeeContext>()
            .UseInMemoryDatabase("EmployeeTest")
            .Options;
        using Core.Models.Data.EmployeeContext context = new Core.Models.Data.EmployeeContext(options);
        // Act
        await context.Database.EnsureDeletedAsync();
        await context.Database.EnsureCreatedAsync();

        Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(NullLogger<Core.Repository.EmployeeMock>.Instance);
        List<EmployeeResponse> employeeList = new List<EmployeeResponse>();
        List<DepartmentResponse> departmentList = new List<DepartmentResponse>();
        Core.Services.EmployeeDatabaseService svc = new Core.Services.EmployeeDatabaseService(context, NullLogger<Core.Services.EmployeeDatabaseService>.Instance);

        foreach (DepartmentDto dept in employeeMock.DepartmentCollection())
        {
            departmentList.Add(await svc.SaveDepartmentAsync(dept));
        }
        int deptSuccess = departmentList.Where(w => w.Success).Count();

        foreach (EmployeeDto emp in employeeMock.EmployeeCollection())
        {
            employeeList.Add(await svc.SaveEmployeeDbAsync(emp));
        }
        int emptSuccess = employeeList.Where(w => w.Success).Count();

        // Assert
        Assert.IsNotNull(context);
        Assert.AreEqual(emptSuccess, await context.Employees.CountAsync());
        Assert.AreEqual(deptSuccess, await context.Departments.CountAsync());

    }
}


