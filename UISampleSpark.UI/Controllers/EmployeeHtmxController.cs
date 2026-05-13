namespace UISampleSpark.UI.Controllers;

/// <summary>
/// htmx-based Employee CRUD Controller
/// </summary>
/// <remarks>
/// This controller demonstrates a server-driven approach using htmx.
/// Instead of returning JSON, actions return HTML fragments that htmx
/// swaps into the DOM, enabling SPA-like interactivity with minimal JavaScript.
/// </remarks>
public class EmployeeHtmxController : BaseController
{
    private readonly IEmployeeClient _client;
    private readonly ILogger<EmployeeHtmxController> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeHtmxController"/> class.
    /// </summary>
    /// <param name="employeeClient">Employee data access client</param>
    /// <param name="configuration">Application configuration interface</param>
    /// <param name="hostEnvironment">Web hosting environment information</param>
    /// <param name="logger">Logger for diagnostic information</param>
    public EmployeeHtmxController(
        IEmployeeClient employeeClient,
        IConfiguration configuration,
        IWebHostEnvironment hostEnvironment,
        ILogger<EmployeeHtmxController> logger) : base(configuration, hostEnvironment)
    {
        _client = employeeClient;
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>
    /// Renders the htmx Employee CRUD main view
    /// </summary>
    /// <returns>The htmx view with declarative AJAX attributes</returns>
    [HttpGet]
    public IActionResult Index()
    {
        _logger.LogInformation("htmx Employee page accessed");
        return View();
    }

    /// <summary>
    /// Returns the employee table as an HTML fragment for htmx swap
    /// </summary>
    /// <param name="page">Current page number (1-based)</param>
    /// <param name="pageSize">Number of items per page</param>
    /// <param name="search">Search term for filtering employees</param>
    /// <returns>Partial view containing the employee table with pagination</returns>
    [HttpGet]
    public async Task<IActionResult> Table(int page = 1, int pageSize = 10, string? search = null)
    {
        Response.Headers["X-Robots-Tag"] = "noindex, nofollow";
        var allEmployees = await _client.GetEmployeesAsync(new PagingParameterModel(), cts.Token).ConfigureAwait(false);

        // Apply search filter if provided
        var filteredEmployees = allEmployees;
        if (!string.IsNullOrWhiteSpace(search))
        {
            filteredEmployees = allEmployees
                .Where(e => MatchesSearch(e, search))
                .ToList();
        }

        var totalItems = filteredEmployees.Count();
        var totalPages = (int)Math.Ceiling(totalItems / (double)pageSize);
        page = Math.Max(1, Math.Min(page, totalPages == 0 ? 1 : totalPages));

        var pagedEmployees = filteredEmployees
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        ViewBag.CurrentPage = page;
        ViewBag.PageSize = pageSize;
        ViewBag.TotalPages = totalPages;
        ViewBag.TotalItems = totalItems;
        ViewBag.AllItemsCount = allEmployees.Count();
        ViewBag.Search = search;

        return PartialView("_Table", pagedEmployees);
    }

    /// <summary>
    /// Returns the employee edit/create form as an HTML fragment
    /// </summary>
    /// <param name="id">Optional employee ID for editing; null for new employee</param>
    /// <returns>Partial view containing the employee form</returns>
    [HttpGet]
    public async Task<IActionResult> Edit(int? id)
    {
        var departments = await _client.GetDepartmentsAsync(false, cts.Token).ConfigureAwait(false);
        ViewBag.Departments = departments;

        if (id.HasValue && id.Value > 0)
        {
            var response = await _client.FindEmployeeByIdAsync(id.Value, cts.Token).ConfigureAwait(false);
            return PartialView("_Form", response.Resource);
        }

        return PartialView("_Form", new EmployeeDto());
    }

    /// <summary>
    /// Saves a new or updated employee from htmx form submission
    /// </summary>
    /// <param name="employee">The employee data from the form</param>
    /// <returns>Empty content with HX-Trigger header to refresh the table</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Save(EmployeeDto employee)
    {
        ArgumentNullException.ThrowIfNull(employee);
        if (employee.Id > 0)
        {
            await _client.UpdateAsync(employee.Id, employee, cts.Token).ConfigureAwait(false);
        }
        else
        {
            await _client.SaveAsync(employee, cts.Token).ConfigureAwait(false);
        }

        Response.Headers["HX-Trigger"] = "refreshTable";
        return Content("");
    }

    /// <summary>
    /// Returns the delete confirmation dialog as an HTML fragment
    /// </summary>
    /// <param name="id">The employee ID to confirm deletion</param>
    /// <returns>Partial view containing the delete confirmation</returns>
    [HttpGet]
    public async Task<IActionResult> DeleteConfirm(int id)
    {
        var response = await _client.FindEmployeeByIdAsync(id, cts.Token).ConfigureAwait(false);
        return PartialView("_DeleteConfirm", response.Resource);
    }

    /// <summary>
    /// Deletes an employee via htmx DELETE request
    /// </summary>
    /// <param name="id">The employee ID to delete</param>
    /// <returns>Empty content with HX-Trigger header to refresh the table</returns>
    [HttpDelete]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id)
    {
        await _client.DeleteAsync(id, cts.Token).ConfigureAwait(false);
        Response.Headers["HX-Trigger"] = "refreshTable";
        return Content("");
    }

    private static bool MatchesSearch(EmployeeDto employee, string search)
    {
        string[] fields =
        [
            employee.Name ?? string.Empty,
            employee.GenderName ?? string.Empty,
            employee.State ?? string.Empty,
            employee.Country ?? string.Empty,
            employee.DepartmentName ?? string.Empty
        ];

        return fields.Any(field => field.Contains(search, StringComparison.OrdinalIgnoreCase));
    }
}
