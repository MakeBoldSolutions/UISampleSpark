using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using UISampleSpark.Core.Models;

namespace UISampleSpark.MinimalApi.Helpers;

/// <summary>
/// Helper class for seeding the employee database with initial test data
/// </summary>
public static class SeedDatabase
{
    /// <summary>
    /// Initializes the database with sample departments and employees
    /// </summary>
    public static async void DatabaseInitialization(Core.Models.Data.EmployeeContext context)
    {
        try
        {
            using var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
            var serviceLogger = loggerFactory.CreateLogger<Core.Services.EmployeeDatabaseService>();
            var mockLogger = loggerFactory.CreateLogger<Core.Repository.EmployeeMock>();

            var employeeService = new Core.Services.EmployeeDatabaseService(context, serviceLogger);
            var token = new CancellationToken();
            var employeeMock = new Core.Repository.EmployeeMock(mockLogger, 290);
            foreach (var dept in employeeMock.DepartmentCollection())
            {
                await employeeService.SaveAsync(dept, token).ConfigureAwait(true);
            }
            employeeMock.EmployeeCollection()?.ForEach(async emp =>
            {
                await employeeService.SaveAsync(emp, token).ConfigureAwait(true);
            });
        }
        catch (InvalidOperationException ex)
        {
            Console.WriteLine($"Database seed error: {ex.Message}");
        }
        catch (DbUpdateException ex)
        {
            Console.WriteLine($"Database update error during seed: {ex.Message}");
        }
    }
}
