using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using System;
using System.Linq;

namespace UISampleSpark.UI.Pages.EmployeeRazor
{
    /// <summary>
    /// Model for creating a new employee through Razor Pages
    /// </summary>
    public class CreateModel : PageModel
    {
        private readonly Core.Models.Data.EmployeeContext _context;

        /// <summary>
        /// Initializes a new instance of the <see cref="CreateModel"/> class
        /// </summary>
        /// <param name="context">Database context for employee data</param>
        public CreateModel(Core.Models.Data.EmployeeContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Handles GET requests for the create page
        /// </summary>
        /// <returns>The create page with department dropdown populated</returns>
        public IActionResult OnGet()
        {
            ViewData["DepartmentId"] = new SelectList(_context.Departments, "Id", "CreatedBy");
            return Page();
        }

        /// <summary>
        /// Gets or sets the employee entity to be created
        /// </summary>
        [BindProperty]
        public Core.Models.Data.Employee Employee { get; set; } = default!;


        /// <summary>
        /// Handles form submission for creating a new employee
        /// </summary>
        /// <returns>Redirects to index page on success, or returns the form with validation errors</returns>
        // To protect from overposting attacks, see https://aka.ms/RazorPagesCRUD
        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid || _context.Employees == null || Employee == null)
            {
                return Page();
            }

            _context.Employees.Add(Employee);
            await _context.SaveChangesAsync();

            return RedirectToPage("./Index");
        }
    }
}
