namespace UISampleSpark.UI.Controllers;

/// <summary>
/// Serves the pure vanilla JavaScript employee CRUD demo.
/// No JavaScript libraries — only the native browser fetch API, DOM APIs,
/// and the Bootstrap CSS classes already loaded by the shared layout.
/// </summary>
[ApiExplorerSettings(IgnoreApi = true)]
public class EmployeeVanillaController : BaseController
{
    private readonly ILogger<EmployeeVanillaController> _logger;

    /// <summary>Initializes a new instance of <see cref="EmployeeVanillaController"/>.</summary>
    public EmployeeVanillaController(
        IConfiguration configuration,
        IWebHostEnvironment hostEnvironment,
        ILogger<EmployeeVanillaController> logger) : base(configuration, hostEnvironment)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>Renders the Pure Vanilla JavaScript employee CRUD view.</summary>
    [HttpGet]
    public IActionResult Index()
    {
        _logger.LogInformation("Vanilla JS Employee page accessed");
        return View();
    }
}
