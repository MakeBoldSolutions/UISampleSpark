using Microsoft.Extensions.Logging;

namespace UISampleSpark.UI.Helpers;

/// <summary>
/// Helper class for seeding the employee database with initial test data
/// </summary>
public static class SeedDatabase
{
    /// <summary>
    /// Initializes the database with sample departments and employees
    /// </summary>
    /// <param name="context">The employee database context to seed</param>
    public static async void DatabaseInitialization(Core.Models.Data.EmployeeContext context)
    {
        try
        {
            using var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
            var serviceLogger = loggerFactory.CreateLogger<Core.Services.EmployeeDatabaseService>();
            var mockLogger = loggerFactory.CreateLogger<Core.Repository.EmployeeMock>();

            Core.Services.EmployeeDatabaseService employeeService = new Core.Services.EmployeeDatabaseService(context, serviceLogger);
            CancellationToken token = new CancellationToken();
            Core.Repository.EmployeeMock employeeMock = new Core.Repository.EmployeeMock(mockLogger, 290);

            // First add all departments
            foreach (DepartmentDto dept in employeeMock.DepartmentCollection())
            {
                await employeeService.SaveAsync(dept, token).ConfigureAwait(true);
            }

            // Then add all employees
            employeeMock.EmployeeCollection()?.ForEach(async emp =>
            {
                await employeeService.SaveAsync(emp, token).ConfigureAwait(true);
            });
        }
        catch (InvalidOperationException ex)
        {
            // Database operation failed - log and continue (this is seed data)
            Console.WriteLine($"Database seed error: {ex.Message}");
        }
        catch (DbUpdateException ex)
        {
            // Database update failed - log and continue (this is seed data)
            Console.WriteLine($"Database update error during seed: {ex.Message}");
        }
    }
}
