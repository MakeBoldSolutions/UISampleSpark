namespace UISampleSpark.UI.Controllers;

/// <summary>
/// React-based Employee CRUD Controller
/// </summary>
/// <remarks>
/// This controller demonstrates a React-based Single Page Application approach
/// to employee CRUD operations. It uses React 18 with JSX transpilation via Babel
/// standalone, consuming the same RESTful API endpoints as the other implementations.
/// </remarks>
public class EmployeeReactController : BaseController
{
    private readonly ILogger<EmployeeReactController> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeReactController"/> class.
    /// </summary>
    /// <param name="configuration">Application configuration interface</param>
    /// <param name="hostEnvironment">Web hosting environment information</param>
    /// <param name="logger">Logger for diagnostic information</param>
    public EmployeeReactController(
        IConfiguration configuration,
        IWebHostEnvironment hostEnvironment,
        ILogger<EmployeeReactController> logger) : base(configuration, hostEnvironment)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>
    /// Renders the React Employee CRUD view
    /// </summary>
    /// <returns>The React SPA view that will be populated with data via API calls</returns>
    [HttpGet]
    public IActionResult Index()
    {
        _logger.LogInformation("React Employee page accessed");
        return View();
    }
}
