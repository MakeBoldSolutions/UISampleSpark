using UISampleSpark.UI.Middleware;

namespace UISampleSpark.UI.Controllers;

/// <summary>
/// MvcEmployeeController
/// </summary>
public class MvcEmployeeController : BaseController
{
    private readonly IEmployeeClient client;

    /// <summary>
    /// Mvc Employee Controller Constructor
    /// </summary>
    /// <param name="employeeClient"></param>
    /// <param name="configuration"></param>
    /// <param name="hostEnvironment"></param>
    public MvcEmployeeController(IEmployeeClient employeeClient,
        IConfiguration configuration,
        IWebHostEnvironment hostEnvironment) : base(configuration, hostEnvironment)
    {
        client = employeeClient;
    }

    /// <summary>
    /// Load Page to Create A New Employee
    /// </summary>
    /// <returns></returns>
    [HttpGet]
    public ActionResult Create() { return View(); }

    /// <summary>
    /// Save New Employee
    /// </summary>
    /// <param name="employee"></param>
    /// <returns></returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<ActionResult> Create(EmployeeDto? employee)
    {
        EmployeeResponse? reqResponse = null;
        if (employee is not null)
        {
            reqResponse = await client.SaveAsync(employee, cts.Token);
        }
        if (reqResponse?.Success == false)
            return RedirectToAction("Index");

        return RedirectToAction("Edit", new { employee?.Id });

    }

    /// <summary>
    /// Select an Employee to delete
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    [HttpGet]
    public async Task<ActionResult> Delete(int id)
    {
        EmployeeResponse? emp = await client.FindEmployeeByIdAsync(id, cts.Token);

        if (emp?.Success == false)
            return RedirectToAction("Index");

        return View(emp?.Resource);
    }

    /// <summary>
    /// Delete Employee
    /// </summary>
    /// <param name="id"></param>
    /// <param name="employee"></param>
    /// <returns></returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<ActionResult> Delete(int id, EmployeeDto? employee)
    {
        if (id <= 0 || employee is null || employee.Id != id)
            return BadRequest();

        // Ensure the target exists before issuing a delete to avoid blind operations.
        EmployeeResponse? existing = await client.FindEmployeeByIdAsync(id, cts.Token);
        if (existing?.Success != true || existing.Resource is null)
            return NotFound();

        _ = await client.DeleteAsync(id, cts.Token);

        return RedirectToAction("Index");
    }

    /// <summary>
    /// View Employee Details
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    [HttpGet]
    public async Task<ActionResult> Details(int id)
    {
        EmployeeResponse? emp = await client.FindEmployeeByIdAsync(id, cts.Token);
        if (emp?.Success == false)
            return RedirectToAction("Index");

        return View(emp?.Resource);
    }

    /// <summary>
    /// Edit an employee by ID
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    [HttpGet]
    public async Task<ActionResult> Edit(int id)
    {
        EmployeeResponse? emp = await client.FindEmployeeByIdAsync(id, cts.Token);

        if (emp?.Success == false)
            return RedirectToAction("Index");

        return View(emp?.Resource);
    }

    /// <summary>
    /// Save Employee
    /// </summary>
    /// <param name="id"></param>
    /// <param name="employee"></param>
    /// <returns></returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<ActionResult> Edit(int id, EmployeeDto? employee)
    {
        if (employee is null)
            return RedirectToAction("Edit");

        employee.ProfilePicture = UploadedFile(employee.ProfileImage, EmployeeId: employee.Id.ToString());

        EmployeeResponse? reqResponse = null;
        if (employee.Id == id)
            reqResponse = await client.UpdateAsync(id, employee, cts.Token);

        if (reqResponse?.Success == true)
            return RedirectToAction("Index");

        return RedirectToAction("Edit", new { employee.Id });
    }

    /// <summary>
    /// Default Page for MvcEmployeeController
    /// </summary>
    /// <param name="paging"></param>
    /// <returns></returns>
    [HttpGet]
    public async Task<ActionResult> Index(PagingParameterModel? paging)
    {
        if (paging == null)
            paging = new PagingParameterModel();

        IEnumerable<EmployeeDto> list = await client.GetEmployeesAsync(paging, cts.Token);

        return View(list);
    }
}

