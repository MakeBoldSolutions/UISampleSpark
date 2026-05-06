namespace UISampleSpark.UI.Controllers;

/// <summary>
/// Blazor Server Employee CRUD Controller
/// </summary>
/// <remarks>
/// This controller hosts a Blazor Server component that demonstrates
/// real-time CRUD operations using SignalR. The Blazor component injects
/// IEmployeeService directly, requiring no HTTP API round-trip.
/// </remarks>
public class EmployeeBlazorController : BaseController
{
    private readonly ILogger<EmployeeBlazorController> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeBlazorController"/> class.
    /// </summary>
    /// <param name="configuration">Application configuration interface</param>
    /// <param name="hostEnvironment">Web hosting environment information</param>
    /// <param name="logger">Logger for diagnostic information</param>
    public EmployeeBlazorController(
        IConfiguration configuration,
        IWebHostEnvironment hostEnvironment,
        ILogger<EmployeeBlazorController> logger) : base(configuration, hostEnvironment)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>
    /// Renders the Blazor Employee CRUD view hosting the Blazor Server component
    /// </summary>
    /// <returns>The view that hosts the Blazor Server component via SignalR</returns>
    [HttpGet]
    public IActionResult Index()
    {
        _logger.LogInformation("Blazor Employee page accessed");
        return View();
    }
}
