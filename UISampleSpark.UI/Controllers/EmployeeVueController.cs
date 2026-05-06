namespace UISampleSpark.UI.Controllers;

/// <summary>
/// Vue.js-based Employee CRUD Controller
/// </summary>
/// <remarks>
/// This controller demonstrates a Vue 3 Single Page Application approach
/// to employee CRUD operations. It uses Vue's Composition API loaded via CDN,
/// consuming the same RESTful API endpoints as the other implementations.
/// </remarks>
public class EmployeeVueController : BaseController
{
    private readonly ILogger<EmployeeVueController> _logger;

    /// <summary>
    /// Initializes a new instance of the <see cref="EmployeeVueController"/> class.
    /// </summary>
    /// <param name="configuration">Application configuration interface</param>
    /// <param name="hostEnvironment">Web hosting environment information</param>
    /// <param name="logger">Logger for diagnostic information</param>
    public EmployeeVueController(
        IConfiguration configuration,
        IWebHostEnvironment hostEnvironment,
        ILogger<EmployeeVueController> logger) : base(configuration, hostEnvironment)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <summary>
    /// Renders the Vue Employee CRUD view
    /// </summary>
    /// <returns>The Vue SPA view that will be populated with data via API calls</returns>
    [HttpGet]
    public IActionResult Index()
    {
        _logger.LogInformation("Vue Employee page accessed");
        return View();
    }
}
